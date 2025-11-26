# GitHub Copilot Instructions

## Commit Message Guidelines

-   Write short and clear commit messages.
-   Start with an imperative verb (e.g., "Add", "Fix", "Update").
-   Insert a blank line between subject and body.
-   Explain what and why, never how.
-   Reference issue numbers when relevant (e.g., "Fixes #123").

## AHK-Specific Rules

-   Extract the file version from the third line of the file.
-   The version appears after " = " in lines like:
        ;@Ahk2Exe-Let U_FileVersion = 0.0.2.4
-   Always include the detected version in the commit body as:
        "File version: X.X.X.X"

-   Highlight changes in hotkeys, timers, handlers, conditions, and flows.
-   Mention impacts on other modules or scripts.
-   Distinguish refactor vs fix.
-   Note performance-relevant updates.
-   Warn when functions, classes, prototypes, or globals are renamed/moved.

## Prefixes

-   feat: new functionality
-   fix: bug fix
-   refactor: internal changes
-   perf: performance improvement
-   chore: small cleanup

## Avoid

-   Vague messages like "adjustments", "test", "update".
