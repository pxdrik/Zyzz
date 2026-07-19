# PROJECT_STATUS.md

This file is the single source of truth for the current state of Zyzz.
Claude must read this file at the start of every session and update it at the end of every task.

---

## Current Version

v1.0.0

---

## Completed Features

| Sprint | Feature | Notes |
|---|---|---|
| Sprint 0 | Project bootstrap | Folder structure, pyproject.toml, uv setup |
| Sprint 1 | Desktop UI shell | Sidebar, header, chat area, input bar (PySide6 + QSS) |
| Sprint 2 | Router integration | RouterService wired to UI; routing decision displayed in header |
| Sprint 3 | Provider layer | BaseProvider, ClaudeProvider, ChatGPTProvider, GeminiProvider (mocked) |
| Sprint 4 | Real Claude API | Anthropic SDK, claude-sonnet-4-6 |
| Sprint 5 | Real ChatGPT API | OpenAI SDK, gpt-4o-mini |
| Sprint 6 | Real Gemini API | google-genai SDK, gemini-2.0-flash |
| Sprint 7 | Streaming | QThread-based streaming; UI updates token by token |
| Sprint 8 | Conversation history | Persist to disk, sidebar list, new chat, rename, delete |
| Sprint 9 | Long-term memory | Store facts via trigger phrases; inject context into every prompt |
| Sprint 10 | Voice | Push-to-talk recording, STT via Whisper API, TTS via pyttsx3 |
| Sprint 11 | Tool execution | ToolRegistry, ToolSpec/ToolResult models, 4 built-in tools, Claude + ChatGPT tool loops |
| Sprint 12 | Google Calendar | OAuth2, list/create events, daily agenda via tools |
| Sprint 13 | Automations | AutomationService, create/list/delete/run automations, send_email tool |
| Sprint 14 | Intelligence | Improved router with confidence/complexity, Orchestrator, /compare parallel execution |
| Sprint 15 | Production release | v1.0.0 tag, README, build script (PyInstaller) |

---

## Known Issues

- **Streaming broken for all messages**: When any tool is registered, `ClaudeProvider.stream()` and `ChatGPTProvider.stream()` silently fall back to a blocking (non-streaming) call. Because `_registry = build_registry()` runs at module import time, the registry is always non-empty. Sprint 7's streaming is functionally inactive.
- **No conversation history sent to AI**: Provider calls always send only the current prompt. The multi-turn conversation stored in `ConversationService` is never loaded and injected. The AI has no memory of the current session.
- **Duplicate comment block in `core/tools/builtin.py`**: The `# Registry builder` section header appears twice (lines 76-78 are a stale artifact from the Sprint 13 edit).

---

## Security Issues (Must Fix Before Any User Exposure)

- **CRITICAL**: `run_command` tool uses `shell=True` with no sandbox or allowlist. The AI model can execute arbitrary shell commands on the user's machine.
- **CRITICAL**: `read_file` tool has no path restriction. The AI model can read any file the OS user can access (credentials, SSH keys, tokens).

---

## Current Technical Debt

| Debt Item | Location | Impact |
|---|---|---|
| `assert` used as type guard (disabled with `-O`) | `core/providers/providers.py:99, 107, 195, 203` | Silent failure in optimized builds |
| Bare `except: pass` swallowing errors silently | `core/automations/service.py:50`, `core/memory/service.py:66`, `core/history/service.py:39` | Data corruption is invisible to the user |
| AI client objects created on every API call | `core/providers/providers.py` (inside `generate`/`stream`) | Unnecessary overhead per message |
| `CalendarService._build_service()` called on every operation | `core/calendar/service.py:24, 49, 65` | Re-authenticates on every calendar tool call |
| No `.env` file loading | `apps/desktop/app.py` | Users must set OS-level env vars; `.env` file is never read |
| No system prompt for any provider | `core/providers/providers.py` | AI has no identity, role, or behavioral guardrails |
| Keyword router uses substring matching, not word boundaries | `core/router/service.py:45-46` | False routing signals on common substrings |
| `main_window.py` is a 1000-line god file with 10+ classes | `apps/desktop/windows/main_window.py` | Hardest file to maintain in the codebase |
| No tests | `tests/` (empty) | Zero regression protection |
| No logging infrastructure | Entire codebase | All errors go to `stderr`; no persistent log |
| Model names hardcoded as string literals | `core/providers/providers.py` | Fragile when providers deprecate models |
| `CalendarService` always creates events in UTC | `core/calendar/service.py:54` | Events appear at wrong time for non-UTC users |
| `GeminiProvider` has no tool support | `core/providers/providers.py:212-244` | Gemini excluded from tool calling; `/compare` shows inconsistent results |

---

## Architecture Constraints (Do Not Violate)

- `core/` must never import from `apps/`. Zero framework dependencies inside `core/`.
- All new business logic goes into `core/`, never inside a window or widget.
- All UI styling lives in `apps/desktop/ui/style.qss`. No inline styles in Python.
- All inter-module data contracts must be Pydantic `BaseModel` subclasses.
- Every public class and method must have a type-annotated signature and a docstring.
- Use `uv` for all package management. Never use `pip` directly.

---

## Next Recommended Tasks (Ordered by ROI)

1. **Fix security**: Remove or sandbox `run_command`; add path restriction to `read_file`.
2. **Restore streaming**: Refactor provider/registry binding so the streaming path is not blocked by tool presence.
3. **Inject conversation history**: Load current conversation messages from `ConversationService` and pass them to providers on every call.
4. **Add system prompt**: Give all three providers a consistent identity and behavioral baseline.
5. **Load `.env`**: Add `python-dotenv` and call `load_dotenv()` in `app.py` for first-run usability.
6. **Fix error handling**: Replace bare `except: pass` with proper logging in 3 services; replace `assert` guards with real raises.
7. **Write smoke tests**: Cover `RouterService`, `MemoryService`, `AutomationService`, `ConversationService` at minimum.
8. **Cache AI clients**: Instantiate provider clients once in `__init__`, not on every call.

---

## File Map (Key Files Only)

```
apps/desktop/app.py               — QApplication entrypoint
apps/desktop/ui/style.qss         — Global Qt stylesheet
apps/desktop/windows/main_window.py — All widgets, workers, and main window (~1000 lines)

core/router/models.py             — Provider enum, RouteDecision model
core/router/service.py            — RouterService (keyword-based routing)
core/providers/providers.py       — BaseProvider, ClaudeProvider, ChatGPTProvider, GeminiProvider
core/tools/models.py              — ToolSpec, ToolResult
core/tools/registry.py            — ToolRegistry
core/tools/builtin.py             — 11 built-in tools + build_registry()
core/history/models.py            — Conversation, Message models
core/history/service.py           — ConversationService (disk persistence)
core/memory/models.py             — MemoryEntry model
core/memory/service.py            — MemoryService (disk persistence + trigger extraction)
core/automations/models.py        — Automation model
core/automations/service.py       — AutomationService (disk persistence)
core/calendar/models.py           — CalendarEvent model
core/calendar/service.py          — CalendarService (Google Calendar OAuth2)
core/voice/service.py             — VoiceService (Whisper STT + pyttsx3 TTS)
core/brain/orchestrator.py        — Orchestrator (parallel multi-provider execution)

scripts/build_installer.py        — PyInstaller build script
main.py                           — Dev/test CLI scratch file (not production)
```

---

## Persistence Layout

All runtime data lives under `~/.zyzz/`:

```
~/.zyzz/
  conversations/        — One JSON file per conversation (UUID filename)
  memory.json           — List of MemoryEntry objects
  automations.json      — List of Automation objects
  google_token.json     — Cached Google OAuth2 token
  credentials.json      — Google Cloud OAuth2 client credentials (user-supplied)
```

---

## Environment Variables Required

| Variable | Required | Used By |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | ClaudeProvider, VoiceService (Whisper) |
| `OPENAI_API_KEY` | Yes | ChatGPTProvider, VoiceService (Whisper) |
| `GOOGLE_API_KEY` | Yes | GeminiProvider |
| `SMTP_HOST` | No (default: smtp.gmail.com) | send_email tool |
| `SMTP_PORT` | No (default: 587) | send_email tool |
| `SMTP_USER` | If email is used | send_email tool |
| `SMTP_PASSWORD` | If email is used | send_email tool |
| `SMTP_FROM` | No (defaults to SMTP_USER) | send_email tool |
