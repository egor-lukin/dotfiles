---
name: generate-skill
description: Generating a new skill from a one-line description
license: MIT
---

## Goal

To guide an AI assistant in creating a new skill from a brief, one-line description provided by the user. The generated skill should follow established conventions for frontmatter format, section structure, and file organization.

## Process

1.  **Receive Description:** The user provides a one-line description of the skill they want to create.
2.  **Assess Clarity:** Evaluate whether the description is specific enough to generate a complete skill. Look for:
    - Clear purpose or functionality
    - Identifiable target audience or use case
    - Sufficient context to determine appropriate sections
3.  **Ask Clarifying Questions (Only When Needed):** If the description is vague or ambiguous, ask 2-3 targeted clarifying questions. Focus on:
    - **Purpose:** "What specific problem does this skill solve?"
    - **Workflow:** "What are the key steps the AI should follow when using this skill?"
    - **Output:** "What should the skill produce or where should it save its output?"
    
    Provide answer options where possible to make responses quick. Skip this step if the description is clear enough to proceed.
4.  **Assess Complexity:** Determine if the skill is simple or complex:
    - **Simple skills:** Require only a SKILL.md file with frontmatter and instructions
    - **Complex skills:** Benefit from bundled resources like reference guides, templates, or helper scripts
5.  **Generate Skill Name:** Derive a kebab-case skill name from the description (e.g., "generate skill" → `generate-skill`, "code review" → `code-review`).
6.  **Create Directory:** Create the skill directory at `.agents/skills/<skill-name>/`.
7.  **Write SKILL.md:** Generate the skill file following the standard structure below.
8.  **Create Supporting Resources (Complex Skills Only):** For complex skills, create appropriate subdirectories (`references/`, `templates/`, `scripts/`) with supporting files.
9.  **Save Files:** Save the SKILL.md and any supporting resources in the appropriate locations.

## Clarifying Questions (Guidelines)

Ask clarifying questions only when the input description lacks essential information. Focus on areas that would significantly impact the skill's usefulness:

*   **Purpose/Goal:** If unclear - "What specific task should this skill help the AI accomplish?"
*   **Process/Workflow:** If vague - "What are the key steps or rules the AI should follow?"
*   **Output/Location:** If unstated - "Where should the skill save its output or what format should it use?"

**Important:** Only ask questions when the answer isn't reasonably inferable. Make reasonable assumptions based on existing skill patterns when possible.

### Formatting Requirements

- **Number all questions** (1, 2, 3, etc.)
- **List options for each question as A, B, C, etc.** for easy reference
- Keep questions concise and focused on the most critical gaps

## Skill Structure

The generated skill should follow this structure:

```markdown
---
name: [skill-name]
description: [One-line description of the skill's purpose]
license: MIT
---

## Goal

[Clear statement of what the skill helps the AI accomplish]

## Process

[Step-by-step instructions for the AI to follow when using this skill]

## Output

[What the skill produces and where it should be saved]

## Target Audience

[Who the skill is designed for or what assumptions the AI should make]
```

Additional sections may be added as appropriate:
- **Rules:** Specific constraints or requirements
- **Clarifying Questions (Guidelines):** How to handle ambiguous inputs
- **Examples:** Usage examples or templates
- **Interaction Model:** How the skill interacts with users

## Complexity Assessment

Determine whether to generate supporting resources based on these criteria:

**Simple Skills (SKILL.md only):**
- Straightforward workflows with clear, linear steps
- Skills that guide a single type of document generation
- Skills with minimal conditional logic

**Complex Skills (SKILL.md + supporting resources):**
- Skills requiring reference materials or examples
- Skills that generate multiple file types or formats
- Skills with complex conditional logic or decision trees
- Skills that benefit from reusable templates

### Supporting Resource Guidelines

- **References:** Create when the skill needs examples, best practices, or pattern guides
- **Templates:** Create when the skill generates documents with consistent structure
- **Scripts:** Create only when programmatic helpers are genuinely needed

## Output

- **Format:** Markdown (`.md`)
- **Location:** `.agents/skills/<skill-name>/SKILL.md`
- **Supporting Resources:** `.agents/skills/<skill-name>/references/`, `.agents/skills/<skill-name>/templates/`, `.agents/skills/<skill-name>/scripts/` (only for complex skills)

## Target Audience

This skill is designed for use by an AI assistant that needs to quickly create new skills from brief descriptions. The generated skills should follow established conventions and be immediately usable without additional configuration.
