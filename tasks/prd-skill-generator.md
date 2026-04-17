# PRD: Skill Generator Skill

## Introduction/Overview

This feature creates a new meta-skill called `generate-skill` that enables an AI assistant to generate new skills (SKILL.md files and supporting resources) from a brief one-line user description. The skill will analyze the request, ask clarifying questions only when the prompt is vague, and produce a complete skill directory structure at `.agents/skills/<skill-name>/`.

## Goals

1. Enable rapid skill creation from minimal input (one-line descriptions)
2. Produce well-structured SKILL.md files following the existing skill format conventions
3. Generate appropriate supporting resources (scripts, references, templates) based on skill complexity
4. Save skills to the relative project path `.agents/skills/<skill-name>/SKILL.md`

## User Stories

- As a developer, I can type "create a skill that does X" and get a fully structured skill without writing boilerplate
- As a developer, I want the AI to ask clarifying questions only when my description is too vague, so I'm not interrupted unnecessarily
- As a developer, I want complex skills to include bundled resources (scripts, references, templates) while simple skills remain minimal
- As a developer, I want the generated skill to follow the same frontmatter and structure conventions as existing skills in the repository

## Functional Requirements

1. The system must accept a brief one-line description of a skill to generate
2. The system must evaluate whether the description is clear enough to proceed; if vague, ask 2-3 clarifying questions about skill logic, scope, and workflows
3. The system must generate a SKILL.md file with proper YAML frontmatter (`name`, `description`, `license`)
4. The system must generate a SKILL.md body that includes: Goal, Process/Workflow, Output format, Target Audience, and any other sections appropriate for the skill
5. The system must determine skill complexity and conditionally generate supporting resources:
   - Simple skills: SKILL.md only
   - Complex skills: SKILL.md plus scripts, references, and templates in the skill directory
6. The system must save the skill to `.agents/skills/<skill-name>/SKILL.md` relative to the project root
7. The system must create the directory structure if it does not already exist
8. The system must derive a valid skill name (kebab-case) from the user's description if not explicitly provided
9. The generated SKILL.md must follow the same formatting conventions as existing skills (markdown structure, clear sections, actionable instructions)

## Non-Goals (Out of Scope)

- Modifying or registering the skill in any global skill registry or configuration
- Testing or validating the generated skill by executing it
- Generating skills that modify system-level or global AI assistant configuration
- Auto-installing dependencies or bundled scripts

## Design Considerations

- The SKILL.md frontmatter must match the existing pattern:
  ```yaml
  ---
  name: skill-name
  description: Short description of the skill
  license: MIT
  ---
  ```
- The skill name in the directory and frontmatter should be kebab-case (e.g., `generate-skill`, `write-tests`)
- Reference the existing skills (`create-prd`, `generate-tasks`, `execute-tasks`) as structural examples

## Technical Considerations

- The skill should be saved relative to the project root at `.agents/skills/<skill-name>/SKILL.md`
- If bundled resources are needed, they should be placed in the same skill directory (e.g., `.agents/skills/<skill-name>/scripts/`, `.agents/skills/<skill-name>/references/`)
- The skill generator should use the existing `question` tool for clarifying questions when needed

## Success Metrics

- A skill is generated and saved to the correct path in a single interaction (or one round of clarifying questions)
- The generated SKILL.md is structurally consistent with existing skills in the repository
- The generated skill is functional and can be loaded by the AI assistant in subsequent sessions

## Open Questions

- Should the skill generator support updating/modifying existing skills, or only creating new ones?
- Should there be a validation step to check that the generated SKILL.md is parseable and well-formed?
- What license should be used by default for generated skills? (Currently assuming MIT based on existing skills)
