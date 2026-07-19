# ROADMAP.md — Zyzz

## Vision

Zyzz is a personal AI Chief of Staff.

Its purpose is to help the user think, plan, organize and execute work by intelligently orchestrating multiple AI providers and external tools through a desktop application.

The roadmap below defines the planned evolution of the project.

Unless explicitly instructed otherwise, AI assistants should always implement the next incomplete sprint.

---

# Sprint Status

| Sprint | Status |
|----------|--------|
| Sprint 0 | ✅ Done |
| Sprint 1 | ✅ Done |
| Sprint 2 | ✅ Done |
| Sprint 3 | ✅ Done |
| Sprint 4 | ✅ Done |
| Sprint 5 | ✅ Done |
| Sprint 6 | ✅ Done |
| Sprint 7 | ✅ Done |
| Sprint 8 | ✅ Done |
| Sprint 9 | ✅ Done |
| Sprint 10 | Pending |
| Sprint 11 | Pending |
| Sprint 12 | Pending |
| Sprint 13 | Pending |
| Sprint 14 | Pending |
| Sprint 15 | Pending |

---

# Sprint 0 — Foundation

Status: ✅ Done

Goals

- Project bootstrap
- Folder structure
- Python + uv
- Core architecture
- Initial documentation

Deliverables

- Base project
- CLAUDE.md
- Repository organization

---

# Sprint 1 — Desktop UI

Status: ✅ Done

Goals

- Desktop shell
- Sidebar
- Header
- Chat area
- Input field
- Dark theme

Deliverables

- Functional desktop interface

---

# Sprint 2 — Router

Status: ✅ Done

Goals

Connect the UI with RouterService.

Deliverables

- User messages reach RouterService
- Routing decision displayed
- UI connected to business layer

---

# Sprint 3 — Provider Layer

Status: ✅ Done

Goals

Create the provider abstraction.

Deliverables

- ChatGPTProvider
- ClaudeProvider
- GeminiProvider
- Mock responses
- .env.example

---

# Sprint 4 — Claude Integration

Status: ✅ Done

Goals

Replace the mocked Claude provider with the real Anthropic SDK.

Requirements

- Official Anthropic SDK
- Read ANTHROPIC_API_KEY
- Graceful error handling
- No architecture changes
- Keep ChatGPT and Gemini mocked

Definition of Done

- Claude returns real responses
- App runs successfully
- Existing providers continue working

---

# Sprint 5 — OpenAI Integration

Status: ✅ Done

Goals

Replace mocked ChatGPT provider.

Requirements

- Official OpenAI SDK
- Read OPENAI_API_KEY
- Same interface as Claude

Definition of Done

- ChatGPT answers real prompts

---

# Sprint 6 — Gemini Integration

Status: ✅ Done

Goals

Replace mocked Gemini provider.

Requirements

- Official Google SDK
- Read GOOGLE_API_KEY

Definition of Done

- Gemini answers real prompts

---

# Sprint 7 — Streaming Responses

Status: ✅ Done

Goals

Support streaming responses.

Requirements

- Token streaming
- Live UI updates
- No UI freezing

Definition of Done

Responses appear progressively.

---

# Sprint 8 — Conversation History

Status: ✅ Done

Goals

Persist conversations.

Requirements

- Create conversations
- Rename conversations
- Delete conversations
- Sidebar history

Definition of Done

Previous conversations can be reopened.

---

# Sprint 9 — Memory

Status: ✅ Done

Goals

Implement long-term memory.

Requirements

- Store user preferences
- Store important facts
- Retrieve memories when relevant

Definition of Done

Zyzz remembers previous conversations.

---

# Sprint 10 — Voice

Status: Pending

Goals

Voice interaction.

Requirements

- Speech-to-text
- Text-to-speech
- Push-to-talk

Definition of Done

User can have voice conversations.

---

# Sprint 11 — Tools

Status: Pending

Goals

Allow providers to execute tools.

Examples

- Calculator
- File reader
- Weather
- Web search
- Terminal commands

Definition of Done

Providers can invoke tools.

---

# Sprint 12 — Calendar

Status: Pending

Goals

Calendar integration.

Requirements

- Read events
- Create events
- Daily agenda

Definition of Done

Zyzz manages appointments.

---

# Sprint 13 — Automations

Status: Pending

Goals

Workflow automation.

Examples

- Email automation
- Daily reports
- File organization
- Custom workflows

Definition of Done

Users can execute automations.

---

# Sprint 14 — Intelligence

Status: Pending

Goals

Improve orchestration.

Requirements

- Better routing
- Multi-provider workflows
- Parallel execution
- Cost optimization

Definition of Done

Zyzz intelligently coordinates multiple AI providers.

---

# Sprint 15 — Production Release

Status: Pending

Goals

Prepare Zyzz for public release.

Requirements

- Bug fixing
- Performance optimization
- Documentation
- Packaging
- Installer
- Version 1.0

Definition of Done

Stable production release.

---

# Development Rules

Before implementing any sprint:

1. Read CLAUDE.md.
2. Read this ROADMAP.md.
3. Identify the first pending sprint.
4. Implement only that sprint.
5. Do not implement future sprints.
6. Do not redesign the architecture.
7. Keep implementations as simple as possible.
8. Validate the application.
9. Fix any issues found.
10. Commit the changes.
11. Push to GitHub.
12. Update this roadmap by marking the sprint as Done.

If any sprint is ambiguous, stop and ask for clarification instead of guessing.
