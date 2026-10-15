;;; open-meteo.el --- Weather forecasts as Org tables -*- lexical-binding: t; -*-

;; Keywords: tools, convenience
;; Package-Requires: ((emacs "27.1"))

;;; Commentary:

;; Fetches a forecast from the Open-Meteo API (https://open-meteo.com) for
;; a city given by name and renders it as an Org table.
;;
;; The entry point is `open-meteo-table', which asks for a city, a start
;; date and a number of days and inserts the table at point:
;;
;;     | Date       | Weather       | Min | Max | Precip | Wind |
;;     |------------+---------------+-----+-----+--------+------|
;;     | 2026-10-01 | Partly cloudy | 7.4 | 14. | 0.2    | 11.5 |
;;
;; With a prefix argument it renders the detailed table instead, one row
;; per hour rather than one per day.
;;
;; The pieces are separate so they can be used on their own:
;;
;;   `open-meteo--request'               city -> parsed forecast
;;   `open-meteo--render-table'          forecast -> Org table string
;;   `open-meteo--render-short-table'    one row per day
;;   `open-meteo--render-detailed-table' one row per hour
;;
;; A forecast is a plist:
;;
;;   (:city "Moscow" :latitude 55.75 :longitude 37.61 :country "Russia"
;;    :timezone "Europe/Moscow" :start-date "2026-10-01" :end-date "..."
;;    :detailed nil :units ALIST :rows (ROW ...))
;;
;; where each ROW is a plist of the requested variables keyed by symbol,
;; so a renderer only ever looks at `:rows' and `:units'.  No HTTP or JSON
;; knowledge lives below `open-meteo--request'.
;;
;; Geocoding is done through the Open-Meteo geocoding API and cached for
;; the session in `open-meteo--geocode-cache'.

;;; Code:

(require 'json)
(require 'url)
(require 'subr-x)

(declare-function org-table-align "org-table" ())
(declare-function org-table-end "org-table" (&optional table-type))

(declare-function plz "plz" (method url &rest rest))

(defgroup open-meteo nil
  "Weather forecasts as Org tables."
  :group 'tools
  :prefix "open-meteo-")

(defcustom open-meteo-default-city nil
  "City to offer as the default when reading one from the minibuffer."
  :type '(choice (const :tag "None" nil) string)
  :group 'open-meteo)

(defcustom open-meteo-default-range 7
  "How many days to request when no range is given."
  :type 'integer
  :group 'open-meteo)

(defcustom open-meteo-language "en"
  "Language code passed to the geocoding API when resolving a city."
  :type 'string
  :group 'open-meteo)

(defcustom open-meteo-geocoding-url
  "https://geocoding-api.open-meteo.com/v1/search"
  "Endpoint resolving a place name to coordinates."
  :type 'string
  :group 'open-meteo)

(defcustom open-meteo-forecast-url "https://api.open-meteo.com/v1/forecast"
  "Endpoint serving forecasts."
  :type 'string
  :group 'open-meteo)

(defconst open-meteo-daily-variables
  '(weather_code
    temperature_2m_min
    temperature_2m_max
    precipitation_sum
    precipitation_probability_max
    wind_speed_10m_max)
  "Daily variables requested for a short forecast.")

(defconst open-meteo-hourly-variables
  '(weather_code
    temperature_2m
    apparent_temperature
    relative_humidity_2m
    precipitation_probability
    precipitation
    wind_speed_10m)
  "Hourly variables requested for a detailed forecast.")

(defconst open-meteo-weather-codes
  '((0 . "Clear sky")
    (1 . "Mainly clear")
    (2 . "Partly cloudy")
    (3 . "Overcast")
    (45 . "Fog")
    (48 . "Depositing rime fog")
    (51 . "Light drizzle")
    (53 . "Moderate drizzle")
    (55 . "Dense drizzle")
    (56 . "Light freezing drizzle")
    (57 . "Dense freezing drizzle")
    (61 . "Slight rain")
    (63 . "Moderate rain")
    (65 . "Heavy rain")
    (66 . "Light freezing rain")
    (67 . "Heavy freezing rain")
    (71 . "Slight snow fall")
    (73 . "Moderate snow fall")
    (75 . "Heavy snow fall")
    (77 . "Snow grains")
    (80 . "Slight rain showers")
    (81 . "Moderate rain showers")
    (82 . "Violent rain showers")
    (85 . "Slight snow showers")
    (86 . "Heavy snow showers")
    (95 . "Thunderstorm")
    (96 . "Thunderstorm with slight hail")
    (99 . "Thunderstorm with heavy hail"))
  "WMO weather interpretation codes and their descriptions.")

(defvar open-meteo--geocode-cache (make-hash-table :test #'equal)
  "Cache mapping a downcased city name to its geocoding plist.")


;;;; Plumbing

(defun open-meteo--url (base query)
  "Return BASE with QUERY, an alist of string pairs, appended."
  (concat base "?"
          (url-build-query-string
           (mapcar (lambda (pair) (list (car pair) (cdr pair))) query))))

(defun open-meteo--get-json (url)
  "GET URL and return its body parsed as JSON with alists and symbol keys."
  (json-read-from-string
   (if (require 'plz nil t)
       (plz 'get url :as 'string)
     ;; `url-retrieve-synchronously' hands back undecoded bytes, so the
     ;; body is decoded here rather than left for `json-read'.
     (with-current-buffer (url-retrieve-synchronously url t t)
       (unwind-protect
           (progn
             (goto-char (point-min))
             (unless (re-search-forward "^\r?$" nil t)
               (error "Open-Meteo: malformed response from %s" url))
             (decode-coding-string
              (buffer-substring-no-properties (point) (point-max))
              'utf-8))
         (kill-buffer (current-buffer)))))))

(defun open-meteo--geocode (city)
  "Resolve CITY to a plist of :name, :latitude, :longitude and :country.
Results are cached in `open-meteo--geocode-cache' for the session."
  (let ((key (downcase (string-trim city))))
    (or (gethash key open-meteo--geocode-cache)
        (let* ((url (open-meteo--url
                     open-meteo-geocoding-url
                     `(("name" . ,city)
                       ("count" . "1")
                       ("language" . ,open-meteo-language)
                       ("format" . "json"))))
               (hit (car (append (alist-get 'results (open-meteo--get-json url)) nil))))
          (unless hit
            (error "Open-Meteo: no place found for %S" city))
          (puthash key
                   (list :name (alist-get 'name hit)
                         :latitude (alist-get 'latitude hit)
                         :longitude (alist-get 'longitude hit)
                         :country (alist-get 'country hit))
                   open-meteo--geocode-cache)))))

(defun open-meteo--days (range)
  "Return the number of days RANGE asks for.
RANGE is a positive integer, nil for `open-meteo-default-range', or one
of the symbols `day', `today', `week' and `month'."
  (pcase range
    ('nil open-meteo-default-range)
    ((or 'day 'today) 1)
    ('week 7)
    ('month 30)
    ((and (pred integerp) (pred (< 0))) range)
    (_ (error "Open-Meteo: invalid range %S" range))))

(defun open-meteo--date-string (date)
  "Return DATE as an ISO 8601 day string.
DATE may be nil for today, a string (returned as is after trimming), an
Emacs time value, or a number of seconds since the epoch."
  (pcase date
    ('nil (format-time-string "%Y-%m-%d"))
    ((pred stringp) (string-trim date))
    (_ (format-time-string "%Y-%m-%d" date))))

(defun open-meteo--date-plus (date days)
  "Return the ISO day string DAYS after the ISO day string DATE."
  (let ((parsed (parse-time-string (concat date " 12:00:00"))))
    (format-time-string
     "%Y-%m-%d"
     (encode-time (nth 0 parsed) (nth 1 parsed) (nth 2 parsed)
                  (+ (nth 3 parsed) days) (nth 4 parsed) (nth 5 parsed)))))

(defun open-meteo--rows (block variables)
  "Transpose BLOCK, a `daily' or `hourly' alist, into a list of row plists.
VARIABLES are the requested variable symbols; `time' is always included."
  (let* ((keys (cons 'time variables))
         (columns (mapcar (lambda (key)
                            (cons key (append (alist-get key block) nil)))
                          keys))
         rows)
    (dotimes (i (length (cdr (assq 'time columns))))
      (push (mapcan (lambda (column)
                      (list (intern (format ":%s" (car column)))
                            (nth i (cdr column))))
                    columns)
            rows))
    (nreverse rows)))


;;;; Requesting

(defun open-meteo--request (city &optional range date detailed)
  "Fetch the forecast for CITY and return it as a plist.
RANGE is how many days to cover, as understood by `open-meteo--days';
DATE is the first of those days, as understood by
`open-meteo--date-string'.  With DETAILED non-nil the forecast carries
one row per hour and the hourly variables, otherwise one row per day and
the daily variables.  See the Commentary for the shape of the result."
  (let* ((place (open-meteo--geocode city))
         (days (open-meteo--days range))
         (start (open-meteo--date-string date))
         (end (open-meteo--date-plus start (1- days)))
         (variables (if detailed
                        open-meteo-hourly-variables
                      open-meteo-daily-variables))
         (field (if detailed "hourly" "daily"))
         (url (open-meteo--url
               open-meteo-forecast-url
               `(("latitude" . ,(number-to-string (plist-get place :latitude)))
                 ("longitude" . ,(number-to-string (plist-get place :longitude)))
                 (,field . ,(mapconcat #'symbol-name variables ","))
                 ("timezone" . "auto")
                 ("start_date" . ,start)
                 ("end_date" . ,end))))
         (response (open-meteo--get-json url)))
    (when-let* ((reason (alist-get 'reason response)))
      (error "Open-Meteo: %s" reason))
    (list :city (plist-get place :name)
          :country (plist-get place :country)
          :latitude (plist-get place :latitude)
          :longitude (plist-get place :longitude)
          :timezone (alist-get 'timezone response)
          :start-date start
          :end-date end
          :detailed (and detailed t)
          :units (alist-get (intern (concat field "_units")) response)
          :rows (open-meteo--rows (alist-get (intern field) response)
                                  variables))))


;;;; Rendering

(defun open-meteo--weather-description (code)
  "Return the description of WMO weather CODE, or the code itself."
  (or (alist-get code open-meteo-weather-codes)
      (and code (format "%s" code))
      ""))

(defun open-meteo--unit (forecast variable)
  "Return the unit FORECAST reports for VARIABLE, or an empty string."
  (or (alist-get variable (plist-get forecast :units)) ""))

(defun open-meteo--cell (value)
  "Return VALUE as a table cell string."
  (cond ((null value) "")
        ((eq value :null) "")
        ((stringp value) value)
        ((floatp value) (format "%.1f" value))
        (t (format "%s" value))))

(defun open-meteo--table (headers rows)
  "Return an Org table string with HEADERS and ROWS of cell values."
  (let ((lines (list (concat "|-"
                             (mapconcat (lambda (_) "-") headers "-+-")
                             "-|")
                     (concat "| " (mapconcat #'identity headers " | ") " |"))))
    (dolist (row rows)
      (push (concat "| " (mapconcat #'open-meteo--cell row " | ") " |") lines))
    (string-join (nreverse lines) "\n")))

(defun open-meteo--render-short-table (forecast)
  "Return FORECAST as an Org table with one row per day."
  (open-meteo--table
   (list "Date"
         "Weather"
         (format "Min %s" (open-meteo--unit forecast 'temperature_2m_min))
         (format "Max %s" (open-meteo--unit forecast 'temperature_2m_max))
         (format "Precip %s" (open-meteo--unit forecast 'precipitation_sum))
         "Precip %"
         (format "Wind %s" (open-meteo--unit forecast 'wind_speed_10m_max)))
   (mapcar (lambda (row)
             (list (plist-get row :time)
                   (open-meteo--weather-description (plist-get row :weather_code))
                   (plist-get row :temperature_2m_min)
                   (plist-get row :temperature_2m_max)
                   (plist-get row :precipitation_sum)
                   (plist-get row :precipitation_probability_max)
                   (plist-get row :wind_speed_10m_max)))
           (plist-get forecast :rows))))

(defun open-meteo--render-detailed-table (forecast)
  "Return FORECAST as an Org table with one row per hour."
  (open-meteo--table
   (list "Time"
         "Weather"
         (format "Temp %s" (open-meteo--unit forecast 'temperature_2m))
         (format "Feels %s" (open-meteo--unit forecast 'apparent_temperature))
         "Humidity %"
         "Precip %"
         (format "Precip %s" (open-meteo--unit forecast 'precipitation))
         (format "Wind %s" (open-meteo--unit forecast 'wind_speed_10m)))
   (mapcar (lambda (row)
             (list (replace-regexp-in-string "T" " " (or (plist-get row :time) ""))
                   (open-meteo--weather-description (plist-get row :weather_code))
                   (plist-get row :temperature_2m)
                   (plist-get row :apparent_temperature)
                   (plist-get row :relative_humidity_2m)
                   (plist-get row :precipitation_probability)
                   (plist-get row :precipitation)
                   (plist-get row :wind_speed_10m)))
           (plist-get forecast :rows))))

(defun open-meteo--render-table (forecast)
  "Return FORECAST as an Org table, detailed or short as it was requested."
  (if (plist-get forecast :detailed)
      (open-meteo--render-detailed-table forecast)
    (open-meteo--render-short-table forecast)))

(defun open-meteo--caption (forecast)
  "Return a one line Org caption describing FORECAST."
  (format "#+CAPTION: %s%s, %s%s\n"
          (plist-get forecast :city)
          (if-let* ((country (plist-get forecast :country)))
              (format " (%s)" country)
            "")
          (plist-get forecast :start-date)
          (if (equal (plist-get forecast :start-date)
                     (plist-get forecast :end-date))
              ""
            (format " -- %s" (plist-get forecast :end-date)))))


;;;; Command

;;;###autoload
(defun open-meteo-table (city &optional range date detailed)
  "Insert the forecast for CITY at point as an Org table.
RANGE is a number of days and DATE the first of them; with DETAILED
non-nil the table has one row per hour instead of one per day.
Interactively read CITY, DATE and RANGE from the minibuffer, and take
DETAILED from the prefix argument."
  (interactive
   (list (read-string (if open-meteo-default-city
                          (format "City (%s): " open-meteo-default-city)
                        "City: ")
                      nil nil open-meteo-default-city)
         (read-number "Days: " open-meteo-default-range)
         (read-string "Start date (YYYY-MM-DD, empty for today): ")
         current-prefix-arg))
  (let ((forecast (open-meteo--request city range
                                       (if (equal date "") nil date)
                                       detailed)))
    (open-meteo--render-table forecast)))

(defun open-meteo-insert-table (city &optional range date detailed)
  "Insert the forecast for CITY at point as an Org table.
RANGE is a number of days and DATE the first of them; with DETAILED
non-nil the table has one row per hour instead of one per day.
Interactively read CITY, DATE and RANGE from the minibuffer, and take
DETAILED from the prefix argument."
  (interactive
   (list (read-string (if open-meteo-default-city
                          (format "City (%s): " open-meteo-default-city)
                        "City: ")
                      nil nil open-meteo-default-city)
         (read-number "Days: " open-meteo-default-range)
         (read-string "Start date (YYYY-MM-DD, empty for today): ")
         current-prefix-arg))
  (let ((forecast (open-meteo--request city range
                                       (if (equal date "") nil date)
                                       detailed)))
    (insert (open-meteo--caption forecast)
            (open-meteo--render-table forecast)
            "\n")
    (when (derived-mode-p 'org-mode)
      (forward-line -1)
      (org-table-align)
      (goto-char (org-table-end)))))

(provide 'open-meteo)
;;; open-meteo.el ends here
