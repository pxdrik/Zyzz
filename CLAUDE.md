# CLAUDE.md — Zyzz Engineering Reference

This document is the permanent engineering manual for any AI working in this repository.
Read it entirely before writing a single line of code.

---

## 1. Project Vision

Zyzz is a **personal AI Chief of Staff** — a desktop assistant that helps the user think, plan, organize, and execute tasks by intelligently orchestrating multiple AI models (ChatGPT, Claude, Gemini) and external tools.

The product is not a wrapper around a single AI. Its core value is in **routing, memory, and orchestration**: understanding what the user needs and delegating it to the best model or tool, automatically.

Design philosophy:
- Simplicity over cleverness.
- Modular, domain-driven architecture.
- Documentation before implementation.
- Long-term maintainability over short-term speed.

---

## 2. Team Roles

| Person / AI | Role |
|---|---|
| Pedro | Product Owner — defines priorities and requirements |
| ChatGPT | AI Architect / Tech Lead — defines architecture and technical decisions |
| Claude | Senior Software Engineer — implements features, fixes bugs, writes tests |
| Gemini | Research Engineer — investigates libraries, APIs, and alternatives |

Claude's mandate is to **implement, not redesign**. Architectural decisions are made by the Architect (ChatGPT) and approved by the Product Owner (Pedro). If Claude identifies a problem with the architecture, it must flag it and wait for a decision before changing anything structural.

---

## 3. Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Language | Python 3.12 | Type hints required everywhere |
| Package manager | uv | Use `uv` for all installs and runs |
| Data validation | Pydantic v2 | Models for all data contracts |
| Desktop UI | PySide6 | Native Qt desktop app |
| UI styling | QSS | All styles live in `style.qss` |
| API layer | FastAPI | Not yet implemented — reserved in `apps/api/` |
| Web frontend | React + Tauri | Not yet implemented — reserved in `apps/web/` |
| Database | PostgreSQL | Not yet implemented |
| AI orchestration | LangGraph | Not yet implemented — reserved in `core/brain/` |
| AI providers | OpenAI, Anthropic, Google | Routed via `core/router/` |

---

## 4. Repository Structure

```
Zyzz/
├── main.py                      # CLI entrypoint (development/testing only)
├── pyproject.toml               # Project metadata and dependencies
├── uv.lock                      # Locked dependency tree — do not edit manually
│
├── apps/                        # Runnable applications (thin layers only)
│   ├── desktop/                 # PySide6 desktop application
│   │   ├── app.py               # QApplication entrypoint
│   │   ├── ui/
│   │   │   └── style.qss        # Global Qt stylesheet (design system)
│   │   └── windows/
│   │       └── main_window.py   # All UI widgets and the main window
│   ├── api/                     # FastAPI backend (not yet implemented)
│   └── web/                     # React/Tauri frontend (not yet implemented)
│
├── core/                        # Business logic — no UI, no framework coupling
│   ├── router/                  # Prompt routing: decides which AI to use
│   │   ├── models.py            # Provider enum, RouteDecision model
│   │   └── service.py           # RouterService
│   ├── agents/                  # AI agents (not yet implemented)
│   ├── brain/                   # LangGraph orchestration (not yet implemented)
│   ├── memory/                  # Context and memory layer (not yet implemented)
│   ├── shared/                  # Shared utilities, base classes, exceptions
│   └── tools/                   # External tool integrations (not yet implemented)
│
├── docs/
│   ├── adr/                     # Architecture Decision Records
│   ├── architecture/            # System design documents
│   └── product/                 # Vision, roadmap, specs
│
├── scripts/                     # Utility scripts (migrations, seeds, etc.)
└── tests/                       # Mirrors the core/ and apps/ structure
```

### Layer rules

- `core/` has **zero knowledge** of PySide6, FastAPI, or any framework. It is pure Python.
- `apps/` contains thin integration layers that wire `core/` to a specific runtime (Qt, HTTP, etc.).
- `apps/` may import from `core/`. `core/` must never import from `apps/`.
- New business logic always goes into `core/`, never directly into a window or route handler.

---

## 5. How to Run the Project

All commands use `uv`. Never use `pip` directly.

```bash
# Install dependencies
uv sync

# Run the desktop UI
uv run python -m apps.desktop.app

# Run the CLI entrypoint (development/testing)
uv run python main.py

# Run tests
uv run pytest

# Add a dependency
uv add <package>
```

After **every change**, run the relevant entrypoint to confirm nothing is broken before committing.

---

## 6. Code Conventions

### General

- All code is written in **English** (variable names, comments, docstrings).
- User-facing strings (UI labels, messages) are written in **Portuguese (Brazil)**.
- Maximum line length: **100 characters**.
- Use `from __future__ import annotations` at the top of every module.

### Typing

- **All function signatures must have type annotations** — parameters and return types.
- Use `X | None` instead of `Optional[X]` (Python 3.10+ union syntax).
- Use `list[X]`, `dict[K, V]`, `tuple[X, ...]` (lowercase, not from `typing`).

### Docstrings

- Every public class and every public method must have a docstring.
- Use plain prose, not reStructuredText or Google style. Keep it concise.
- Private methods (prefixed with `_`) do not require docstrings unless the logic is non-obvious.

### Pydantic models

- All inter-module data contracts must be Pydantic `BaseModel` subclasses.
- Never pass raw dicts between modules. Define a model.
- Use `str(Enum)` pattern for enums that are serialized (as in `Provider`).

### PySide6 / UI

- Every widget must have a unique `objectName` set via `setObjectName()`.
- All visual styling lives exclusively in `style.qss`. No inline styles in Python code.
- Signals and slots follow the pattern: signal defined on the emitting widget, connected in the parent or window.
- UI widgets must contain **zero business logic**. They emit signals; `core/` does the work.
- Qt method overrides that conflict with PEP 8 naming (e.g., `keyPressEvent`) should be marked with `# noqa: N802`.

### File and module naming

- Snake case for all Python files and directories: `main_window.py`, `router_service.py`.
- One class per file is the default. Group only when classes are tightly coupled and small (as in `main_window.py`).

---

## 7. Git and Commit Conventions

- Commits must be **small and atomic** — one logical change per commit.
- Commit message format: `type: short description in imperative mood`
  - Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`
  - Examples: `feat: add keyword router for Gemini`, `fix: remove self from static method`
- Never commit broken code. Run the project before every commit.
- Never commit `.env` files, credentials, or personal configuration.
- Branch names: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`.

---

## 8. Development Workflow for New Features

1. **Understand the requirement** — read the relevant docs and existing code before writing anything.
2. **Define the data contract** — create or update Pydantic models in the appropriate `core/` module.
3. **Implement the service** — write the business logic in `core/`, covered by unit tests.
4. **Wire to the UI or API** — connect the service to the application layer (`apps/`) via signals or route handlers.
5. **Update styles if needed** — all visual changes go into `style.qss`, never inline.
6. **Run the project** — verify the feature works end-to-end.
7. **Commit** — one commit per logical unit of work.

New modules inside `core/` must follow the same structure as `core/router/`:
- `models.py` — data models
- `service.py` — business logic class

---

## 9. Mandatory Rules

These rules are non-negotiable. Violating them requires explicit approval from the Product Owner.

1. **Do not alter the folder architecture** without a documented decision. If a structural change is needed, flag it — do not implement it unilaterally.
2. **Run the project after every non-trivial change.** Do not commit code you have not seen execute.
3. **All public interfaces must be typed and documented.** No untyped function signatures in `core/`.
4. **Do not add dependencies without justification.** Every new package must solve a real problem that cannot be solved with the standard library or existing dependencies.
5. **Commits must be small and descriptive.** A commit that touches five unrelated things is a bad commit.
6. **`core/` must remain framework-agnostic.** If you are importing PySide6 or FastAPI inside `core/`, you are doing it wrong.
7. **Never silently swallow exceptions.** Either handle them explicitly or let them propagate. Do not use bare `except:` or `except Exception: pass`.
8. **Do not over-engineer.** Build only what is needed for the current task. No speculative abstractions, no premature generalization.

---

## 10. Current Known Issues

No known issues.

---

## 11. Sprint Status

| Sprint | Status | Description |
|---|---|---|
| Sprint 0 | Done | Project bootstrap, folder structure, core router |
| Sprint 1 | Done | Desktop UI shell (PySide6): sidebar, header, chat area, input bar |
| Sprint 2 | Done | Connect RouterService to the UI; display routing decision |
| Sprint 3 | Done | Provider layer (core/providers/): mocked ChatGPT, Claude, Gemini |
| Sprint 4 | Done | Real Claude API integration via Anthropic SDK; mocks preserved for ChatGPT and Gemini |
| Sprint 5 | Done | Real ChatGPT integration via OpenAI SDK (gpt-4o-mini); Gemini remains mocked |
| Sprint 6 | Done | Real Gemini integration via google-genai SDK (gemini-2.0-flash) |
| Sprint 7 | Done | Streaming responses via QThread; UI updates token by token without freezing |
| Sprint 8 | Done | Conversation history: persist to disk, sidebar list, new chat, rename, delete |
| Sprint 9 | Done | Long-term memory: store facts via trigger phrases, inject context into every prompt |
| Sprint 10 | Done | Voice interaction: push-to-talk recording, STT via Whisper, TTS via pyttsx3 |
| Sprint 11 | Done | Tool execution: ToolRegistry, 4 built-in tools, Claude and ChatGPT tool call loops |
| Sprint 12 | Done | Google Calendar integration: OAuth2, list/create events, daily agenda via tools |
| Sprint 13 | Done | Automations: AutomationService, create/list/delete/run automations, send_email tool |
| Sprint 14 | Done | Intelligence: improved router with confidence/complexity, Orchestrator, /compare parallel execution |
| Sprint 15 | Done | Production release: v1.0.0, bug fixes, README, build script |
| Sprint 16 | Done | AI Command Center UI, real system metrics (psutil), Finance module (React/WebEngine), add_expense/add_income tools |

---

## 12. Architecture Principles

These principles govern every implementation decision. They are not preferences — they are constraints.

- **Business logic belongs in `core/`.** Services, models, and domain rules must never live inside `apps/`.
- **UI logic belongs in `apps/desktop/`.** Widgets, windows, and signal wiring are not business logic and must not leak into `core/`.
- **UI must never contain business rules.** A widget may display a result or emit a signal; it must never decide what the result should be.
- **Prefer composition over inheritance.** Build behavior by combining small, focused objects. Avoid deep class hierarchies.
- **Every module must have a single responsibility.** If you cannot describe what a module does in one sentence, it is doing too much.
- **Avoid unnecessary global state.** Do not use module-level variables as runtime state. Pass dependencies explicitly.
- **Write for extensibility and maintainability, not for cleverness.** Code is read far more often than it is written.
- **Follow the existing project architecture.** When in doubt, look at what already exists and be consistent with it.
- **Never move files or folders without strong justification.** Restructuring has a cost. Flag the need and wait for approval before acting.

---

## 13. Definition of Done

A task is only considered complete when **all** of the following are true:

- [ ] The project runs successfully after the change.
- [ ] No runtime errors exist.
- [ ] No syntax errors exist.
- [ ] Existing functionality was not broken.
- [ ] The requested feature is fully implemented — not partially.
- [ ] All new code is typed (parameters and return values).
- [ ] Docstrings were added to new public classes and methods.
- [ ] Unused imports were removed.
- [ ] The implementation follows the current architecture (see sections 4 and 12).
- [ ] Changes are committed with a clear Conventional Commits message.
- [ ] The commit has been pushed to the remote repository successfully.

Do not mark a task as done, and do not move on, until every item above is satisfied.

---

## 14. Never Guess

If any information required to complete a task is missing, ambiguous, or unclear — **stop and ask**.

Never invent:
- Business rules that were not specified.
- Architectural decisions that were not documented.
- Behavior of external systems based on assumptions.
- What the user "probably" wants.

One clarifying question asked before starting is worth more than an hour of work built on a wrong assumption. When in doubt, ask Pedro.

---

## 15. Execution Policy

Default behavior:

- Implement the complete requested feature.
- Validate it.
- Fix issues found during validation.
- Commit the changes.
- Push the commit to the remote repository.
- Verify the push succeeded.
- Report only the final summary using the Delivery Report Format (see section 17).

Do not stop after each small step.
Do not ask for confirmation unless a requirement is ambiguous.
Minimize intermediate explanations.
Prioritize delivering working software.

---

## 16. Git Workflow

Every completed task must follow this workflow in order:

1. Implement the feature.
2. Run the project and validate it works.
3. Fix any errors found.
4. Stage all required files.
5. Create a clear commit using Conventional Commits format.
6. Push the commit to the current remote branch.
7. Verify the push completed successfully.

**Mandatory rule:** Never leave completed work only in the local repository.

- If a commit succeeds but the push fails, report the error and stop.
- Never claim a task is complete if the remote repository was not updated.
- A task is not considered done until the changes are safely stored in the remote repository.

---

## 17. Delivery Report Format

Every completed task must end with a report in exactly this format:

```
## Sprint X Complete

### Requirements implemented
- ...

### Files changed
- `path/to/file.py` — description of change

### Validation
✅ Application started successfully
✅ No runtime errors
✅ Feature works as expected
✅ Existing functionality preserved

### Git
Commit: <hash>
Message: type: description
Push: ✅ origin/master updated

### Next sprint suggestion
...
```

Use this format every time. Do not deviate from it.
