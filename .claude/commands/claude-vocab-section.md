
# Shared Vocabulary Protocol (add to CLAUDE.md)

## Dictionary Location

- **Index:** `docs/dictionary.md` — Load at session start
- **Full entries:** `docs/dictionary/[term].md` — Read on-demand

## How to Reference

1. Load `docs/dictionary.md` (the index) at session start
2. When you encounter a term from the index, read its full entry in `docs/dictionary/`
3. Use the dictionary definition—NOT your general knowledge
4. If a term is missing, follow the process below

## When a Term is Missing

If a keyword in the user's query does not exist in the dictionary:

1. **Flag it:** "⚠️ Term '[X]' not found in dictionary"
2. **Ask the user** for a definition or description
3. **Run `/define-terms "[X]"`** to create the entry using their input

Do NOT proceed with assumptions. The dictionary exists to prevent guesswork.

## When a Potential Match Exists

If a keyword in the user's query is similar to (but not exactly) an existing term:

1. **Ask for confirmation:** "Did you mean '[existing term]'?"
2. If yes → use that term's definition
3. If it's an alias → **update the entry's `Aliases` field** in `docs/dictionary/[term].md` to include the user's phrasing

## Do NOT

- ❌ Assume you know what a term means without checking
- ❌ Skip the dictionary lookup because a term seems obvious
- ❌ Proceed with ambiguous terms without asking

## When Modifying Code

If your changes affect files listed in any dictionary term's "Code Locations":

1. Re-read that term's full entry
2. Verify your changes align with the defined behavior
3. Update the dictionary entry if behavior has changed

## Maintenance Responsibility

After ANY code change that:
- Modifies a component/hook/store listed in a dictionary entry
- Introduces a new domain concept
- Changes the behavior of an existing concept

You MUST update `docs/dictionary.md` accordingly.

## The Lookup Pattern

```mermaid
flowchart TD
    A[Receive User Instruction] --> B[Scan for Domain-Specific Terms]
    B --> C{Term in Dictionary?}
    C -->|Exact match| D[Read Full Entry]
    C -->|Partial match| E[Ask User: Did you mean X?]
    C -->|No match| F[Flag Missing Term]
    E -->|Yes| D
    E -->|No, it's an alias| G[Update Aliases in Entry]
    G --> D
    F --> H[Ask User for Definition]
    H --> I[Run /define-terms]
    I --> D
    D --> J[Proceed with Implementation]
```

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant D as docs/dictionary.md
    participant C as /define-terms

    U->>A: "When user is in committed state, disable the editor"
    A->>D: Load index
    A->>A: Scan for terms: "committed state", "editor"
    A->>D: Lookup "committed state"
    D-->>A: Found → read docs/dictionary/committed-state.md
    A->>D: Lookup "editor"
    D-->>A: Found → read docs/dictionary/editor.md
    A->>A: Resolved: Disable BlockScheduleEditor when scheduleStore.committed === true
    A->>U: Implementation complete
```

```mermaid
sequenceDiagram
    participant U as User
    participant A as Agent
    participant D as docs/dictionary.md
    participant C as /define-terms

    U->>A: "Update the scheduler widget"
    A->>D: Load index
    A->>A: Scan for terms: "scheduler widget"
    A->>D: Lookup "scheduler widget"
    D-->>A: Not found. Partial match: "scheduler"
    A->>U: ⚠️ "scheduler widget" not in dictionary. Did you mean "scheduler"?
    U->>A: No, it's a new component
    A->>U: Please describe what "scheduler widget" means
    U->>A: It's the compact weekly view sidebar
    A->>C: /define-terms "scheduler widget"
    C-->>A: Entry created
    A->>U: Added to dictionary. Proceeding with implementation.
```