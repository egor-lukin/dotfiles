## Relevant Files

- `.agents/skills/create-prd/SKILL.md` - Reference for existing skill format and conventions.
- `.agents/skills/generate-tasks/SKILL.md` - Reference for existing skill format and conventions.
- `.agents/skills/execute-tasks/SKILL.md` - Reference for existing skill format and conventions.
- `.agents/skills/generate-skill/SKILL.md` - New skill file to be created.
- `.agents/skills/generate-skill/references/skill-structure-examples.md` - Reference guide for skill structure patterns (if complexity warrants).
- `.agents/skills/generate-skill/templates/skill-template.md` - Template for generating new SKILL.md files.

### Notes

- Follow the exact frontmatter format used by existing skills (`name`, `description`, `license`).
- The skill should be saved relative to the project root at `.agents/skills/<skill-name>/SKILL.md`.
- Supporting resources (scripts, references, templates) should only be generated for complex skills.

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, you must check it off in this markdown file by changing `- [ ]` to `- [x]`. This helps track progress and ensures you don't skip any steps.

Example:
- `- [ ] 1.1 Read file` → `- [x] 1.1 Read file` (after completing)

Update the file after completing each sub-task, not just after completing an entire parent task.

## Tasks

- [x] 1.0 Analyze existing skill conventions and structure
  - [x] 1.1 Read all existing SKILL.md files in `.agents/skills/` to understand format patterns
  - [x] 1.2 Document common frontmatter fields (`name`, `description`, `license`)
  - [x] 1.3 Identify standard sections used across skills (Goal, Process, Output, Target Audience, etc.)
  - [x] 1.4 Note directory structure patterns for skills that include bundled resources

- [x] 2.0 Define the generate-skill workflow and logic
  - [x] 2.1 Define input processing logic for parsing one-line skill descriptions
  - [x] 2.2 Define vagueness detection criteria and clarifying question flow (2-3 questions max, only when needed)
  - [x] 2.3 Define complexity assessment rules (simple skills = SKILL.md only; complex skills = SKILL.md + scripts/references/templates)
  - [x] 2.4 Define the output generation pipeline (derive skill name, create directory, write files)

- [x] 3.0 Write the SKILL.md file with frontmatter and instructions
  - [x] 3.1 Create YAML frontmatter with `name: generate-skill`, appropriate description, and `license: MIT`
  - [x] 3.2 Write the Goal section describing the skill's purpose
  - [x] 3.3 Write the Process section with step-by-step instructions for skill generation
  - [x] 3.4 Include conditional logic for asking clarifying questions when input is vague
  - [x] 3.5 Write the Output section specifying the save path `.agents/skills/<skill-name>/SKILL.md`
  - [x] 3.6 Write the Target Audience section and any additional relevant sections

- [x] 4.0 Create supporting resources for complex skill generation
  - [x] 4.1 Create a reference file with skill structure examples and best practices
  - [x] 4.2 Create a SKILL.md template that the skill can use when generating new skills
  - [x] 4.3 Define guidelines for when to generate bundled scripts vs. references vs. templates

- [x] 5.0 Save and validate the skill at `.agents/skills/generate-skill/`
  - [x] 5.1 Create the directory `.agents/skills/generate-skill/`
  - [x] 5.2 Save the completed SKILL.md file
  - [x] 5.3 Save supporting resources in appropriate subdirectories (`references/`, `templates/`)
  - [x] 5.4 Verify the complete file structure and content matches the PRD requirements
