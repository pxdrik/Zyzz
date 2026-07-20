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
| Sprint 16 | QML UI redesign | Migrated from PySide6 Widgets to QML/Qt Quick; ZyzzBridge, Core sphere, pipeline viz, glassmorphism |
| Sprint 17 | Tech debt cleanup | Cached AI clients, cached CalendarService, fixed router word boundaries |

---

## Known Issues

None currently. All Sprint Final critical issues resolved.

---

## Security Notes (Intentional Design — Personal Desktop App)

- `run_command` tool uses `shell=True`. By design for personal use. Consider adding a confirmation prompt before production distribution.
- `read_file` tool has no path restriction. By design for personal use.

---

## Current Technical Debt

| Debt Item | Location | Impact |
|---|---|---|
| ~~AI client objects created on every API call~~ | ~~`core/providers/providers.py`~~ | **RESOLVED Sprint 17** |
| ~~`CalendarService._build_service()` called on every operation~~ | ~~`core/calendar/service.py`~~ | **RESOLVED Sprint 17** |
| ~~No `.env` file loading~~ | ~~`apps/desktop/app.py`~~ | **RESOLVED Sprint 15** |
| ~~No system prompt for any provider~~ | ~~`core/providers/providers.py`~~ | **RESOLVED Sprint 15** |
| ~~Keyword router uses substring matching~~ | ~~`core/router/service.py`~~ | **RESOLVED Sprint 17** |
| `main_window.py` is a legacy file | `apps/desktop/windows/main_window.py` | Kept for reference; QML is now primary |
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

1. **Add system prompt**: Give all three providers a consistent identity and behavioral baseline — the AI doesn't know it's "Zyzz".
2. **Cache AI clients**: Instantiate `anthropic.Anthropic()`, `openai.OpenAI()`, `genai.Client()` once in `__init__`, not on every call.
3. **Cache `CalendarService._build_service()`**: Store the authenticated service object on `self` and only rebuild on token expiry.
4. **Fix keyword router word boundaries**: Use `re.search(r'\bkeyword\b', lower)` instead of substring `in` matching.
5. **Write smoke tests**: Cover `RouterService`, `MemoryService`, `AutomationService`, `ConversationService` at minimum.
6. **Add system prompt to all providers**: Define a personality and behavioral baseline.

---

## File Map (Key Files Only)

```
apps/desktop/app.py               — QGuiApplication + QQmlApplicationEngine entrypoint
apps/desktop/bridge.py            — ZyzzBridge (Python↔QML), ConversationListModel, PipelineModel
apps/desktop/workers.py           — QThread workers (Stream, Parallel, Record, Transcribe, TTS)
apps/desktop/ui/qml/main.qml     — Main QML window with layout, background particles
apps/desktop/ui/qml/ZyzzCore.qml  — Animated core sphere with Canvas, orbiting particles
apps/desktop/ui/qml/InputBar.qml  — Glass-style input bar with mic + text + send
apps/desktop/ui/qml/ResponsePanel.qml — Glassmorphism response text panel
apps/desktop/ui/qml/PipelineBar.qml   — Animated pipeline node visualization
apps/desktop/ui/qml/HistoryDrawer.qml — Slide-from-left conversation history drawer
apps/desktop/ui/style.qss         — Global Qt stylesheet (legacy, kept for reference)
apps/desktop/windows/main_window.py — Legacy widget-based UI (kept for reference)

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
