;; -*- lexical-binding: t; -*-

(defun my/org-logbook-for-day (&optional date)
  "Собрать все CLOCK-записи (logbook) из `org-agenda-files' за DATE.

DATE — строка вида \"ГГГГ-ММ-ДД\" (по умолчанию — сегодня).
Возвращает список плистов (:heading НАЗВАНИЕ :start ВРЕМЯ :end ВРЕМЯ :file ФАЙЛ)
и выводит их таблицей в буфер *Org Logbook*."
  (interactive (list (org-read-date nil nil nil "Дата: ")))
  (let* ((date (or date (format-time-string "%Y-%m-%d")))
         (clock-re "^[ \t]*CLOCK:[ \t]*\\[\\([^]]+\\)\\]\\(?:--\\[\\([^]]+\\)\\]\\)?")
         (results nil))
    (dolist (file (org-agenda-files))
      (when (file-exists-p file)
        (with-current-buffer (find-file-noselect file)
          (org-with-wide-buffer
           (goto-char (point-min))
           (while (re-search-forward clock-re nil t)
             (let ((start-str (match-string-no-properties 1))
                   (end-str   (match-string-no-properties 2)))
               (when (and start-str (string-prefix-p date start-str))
                 (save-excursion
                   (org-back-to-heading t)
                   (push (list :heading (org-get-heading t t t t)
                               :start (my/org-logbook--time-of start-str)
                               :end (if end-str
                                        (my/org-logbook--time-of end-str)
                                      "не завершено")
                               :file (file-name-nondirectory file))
                         results)))))))))
    (setq results (sort (nreverse results)
                         (lambda (a b) (string< (plist-get a :start)
                                                 (plist-get b :start)))))
    ;; (my/org-logbook--show date results)
    (my/org-logbook-formatter results)))

(defun my/org-logbook-formatter (entries)
  "Преобразовать ENTRIES в список списков (ФАЙЛ НАЧАЛО КОНЕЦ)."
  (mapcar (lambda (e)
            (list
             (plist-get e :file)
             (plist-get e :heading)
             (plist-get e :start)
             (plist-get e :end)))
          entries))

(defun my/org-logbook--time-of (timestamp)
  "Извлечь ЧЧ:ММ из строки таймстампа org TIMESTAMP."
  (if (string-match "\\([0-9][0-9]:[0-9][0-9]\\)\\'" timestamp)
      (match-string 1 timestamp)
    "??:??"))

(defun my/org-logbook--show (date entries)
  "Показать ENTRIES за DATE таблицей в отдельном буфере."
  (with-current-buffer (get-buffer-create "*Org Logbook*")
    (erase-buffer)
    (org-mode)
    (insert (format "* Logbook за %s\n\n" date))
    (if (null entries)
        (insert "Записей не найдено.\n")
      (insert "| Название | Начало | Конец |\n")
      (insert "|-\n")
      (dolist (e entries)
        (insert (format "| %s | %s | %s |\n"
                         (plist-get e :heading)
                         (plist-get e :start)
                         (plist-get e :end))))
      (goto-char (point-min))
      (search-forward "|-" nil t)
      (org-table-align))
    (display-buffer (current-buffer))))

(provide 'logbook-table)
