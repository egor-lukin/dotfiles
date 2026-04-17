# Skill Structure Examples and Best Practices

## Standard Frontmatter

All skills must include YAML frontmatter with these fields:

```yaml
---
name: skill-name
description: One-line description of what the skill does
license: MIT
---
```

## Common Sections

### Required Sections

1. **Goal** - Clear statement of what the skill helps accomplish
2. **Process** - Step-by-step instructions for the AI
3. **Output** - What the skill produces and where
4. **Target Audience** - Who the skill is for

### Optional Sections (Add as Needed)

- **Rules** - Specific constraints or requirements
- **Clarifying Questions (Guidelines)** - How to handle ambiguous inputs
- **Interaction Model** - How the skill interacts with users
- **Examples** - Usage examples or templates

## Example: Simple Skill

A simple skill that only needs a SKILL.md file:

```markdown
---
name: write-readme
description: Writing a README file for a project
license: MIT
---

## Goal

To guide an AI assistant in creating a comprehensive README file.

## Process

1. Analyze the project structure and code
2. Identify the project's purpose and key features
3. Write the README following standard conventions
4. Save as README.md in the project root

## Output

- **Format:** Markdown
- **Location:** Project root as `README.md`

## Target Audience

Developers who will use or contribute to the project.
```

## Example: Complex Skill

A complex skill with supporting resources:

```
.agents/skills/code-review/
├── SKILL.md
├── references/
│   └── best-practices.md
└── templates/
    └── review-template.md
```

## Best Practices

1. **Be Specific:** Use clear, unambiguous language in instructions
2. **Follow Conventions:** Match the format and structure of existing skills
3. **Keep It Focused:** Each skill should have a single, well-defined purpose
4. **Use Examples:** Include examples when the output format is important
5. **Conditional Logic:** Specify when to ask questions vs. make assumptions
6. **Noun-Based Names:** Use verb-noun or noun-noun patterns (e.g., `generate-skill`, `code-review`)
