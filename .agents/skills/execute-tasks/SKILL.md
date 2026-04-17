---
name: execute-tasks
description: Implementing all subtasks from a task file autonomously without interruptions
license: MIT
---

## Goal

To guide an AI assistant in autonomously implementing all subtasks from a task file without asking questions or seeking confirmation. The AI should work through each task systematically, updating progress as it goes, and only pause if token usage becomes excessive.

## Process

1.  **Receive Task File:** The user provides a path to a task file (typically `tasks-*.md` in `/tasks/`) or asks you to find the most recent one.
2.  **Read Task File:** Read the entire task file to understand all parent tasks and subtasks that need to be implemented.
3.  **Understand Context:** Review the relevant files mentioned in the task file to understand the codebase structure and existing patterns before starting implementation.
4.  **Execute Tasks Sequentially:** Work through each subtask in order, from top to bottom. For each subtask:
    - Understand what needs to be done
    - Implement the required changes
    - Update the task file by changing `- [ ]` to `- [x]` for the completed subtask
    - Move to the next subtask immediately without asking for confirmation
5.  **Token Management:** Monitor your token usage. If you have spent a significant amount of tokens (approaching context limits), pause and inform the user:
    - "I've completed tasks X through Y. Token usage is getting high. Should I continue with the remaining tasks?"
    - Wait for user confirmation before proceeding.
6.  **Complete All Tasks:** Continue until all subtasks are marked as complete or until the user stops you.

## Rules

- **NO QUESTIONS:** Do not ask clarifying questions during implementation. Make reasonable assumptions based on the codebase context and existing patterns.
- **NO INTERRUPTIONS:** Do not pause between tasks to ask for confirmation. Work continuously through the task list.
- **UPDATE PROGRESS:** After completing each subtask, immediately update the task file to mark it as complete (`- [x]`).
- **FOLLOW PATTERNS:** When implementing, follow existing code conventions, patterns, and architecture found in the codebase.
- **TEST WHEN POSSIBLE:** If the task file mentions tests or if tests are clearly appropriate, write and run them. Fix any failures before moving to the next task.
- **HANDLE ERRORS:** If you encounter an error or blocker, attempt to resolve it autonomously. Only stop if you cannot proceed after reasonable attempts.

## Token Management Guidelines

- **Low token usage:** Continue implementing without interruption
- **Medium token usage:** Continue, but be mindful of context window
- **High token usage:** Pause and ask the user if you should continue. Provide a summary of what's been completed and what remains.

## Target Audience

This skill is designed for autonomous execution. The AI should act as a senior developer who can make reasonable decisions without needing constant guidance.

## Output

- **Progress Updates:** Provide brief status updates after completing each parent task (e.g., "Completed task 1.0: Setup database schema")
- **Final Summary:** When all tasks are complete, provide a summary of what was implemented
- **Task File:** The task file should be updated in real-time with completed tasks marked as `- [x]`

## Example Workflow

```
1. User: "Execute the tasks in tasks-user-auth.md"
2. AI: Reads tasks-user-auth.md, understands all subtasks
3. AI: Reviews relevant files mentioned in the task file
4. AI: Starts implementing subtask 1.1
5. AI: Completes 1.1, updates task file: `- [x] 1.1 Setup auth routes`
6. AI: Immediately starts implementing subtask 1.2
7. AI: Continues this pattern for all subtasks...
8. AI: "All tasks completed. Summary: Implemented user authentication with login, logout, and session management."
```
