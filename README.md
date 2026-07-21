# Zyzz — Personal AI Chief of Staff

Zyzz is a desktop assistant that helps you think, plan, organize, and execute work by intelligently orchestrating multiple AI models (Claude, ChatGPT, Gemini) and external tools through a native desktop interface.

---

## Features

- **Multi-provider AI routing** — automatically routes each query to the most appropriate model based on content type and complexity
- **Streaming responses** — responses appear token by token, just like ChatGPT
- **Conversation history** — all conversations are persisted locally; reopen, rename, or delete any past conversation
- **Long-term memory** — store facts about yourself and have them injected as context into every prompt
- **Voice interaction** — push-to-talk recording, speech-to-text via OpenAI Whisper, text-to-speech responses
- **Tool execution** — AI can invoke built-in tools: calculator, datetime, file reader, terminal commands
- **Google Calendar** — read upcoming events, get daily agenda, create new appointments
- **Automations** — save reusable prompts as named workflows and trigger them with `/run <name>`
- **Parallel comparison** — send any query to all three providers simultaneously with `/compare <query>`
- **Finance module** — Lacalle Finance (React) embedded via QtWebEngine; log expenses and income directly from the AI chat
- **AI Command Center UI** — holographic-style interface with real-time system telemetry (CPU, RAM, Disk via psutil), animated core visualization, floating glass panels
- **Dark theme** — clean, high-contrast UI inspired by Linear and Raycast

---

## Requirements

- Python 3.12+
- [uv](https://github.com/astral-sh/uv) (package manager)
- API keys for the AI providers you want to use
- *(Optional)* Google Cloud project with Calendar API enabled
- *(Optional)* A microphone for voice input

---

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/pxdrik/Zyzz.git
cd Zyzz

# 2. Install dependencies
uv sync

# 3. Set up your environment variables
cp .env.example .env
# Edit .env and fill in your API keys
```

---

## Configuration

Copy `.env.example` to `.env` and fill in the values you need:

```env
# AI Providers
ANTHROPIC_API_KEY=sk-ant-...      # Required for Claude
OPENAI_API_KEY=sk-...             # Required for ChatGPT and Whisper (voice)
GOOGLE_API_KEY=...                # Required for Gemini

# Email automation (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=you@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=you@gmail.com
```

### Google Calendar (optional)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project and enable the **Google Calendar API**
3. Create **OAuth 2.0 credentials** (type: Desktop app)
4. Download `credentials.json` and place it at `~/.zyzz/credentials.json`
5. On first use, a browser window opens for OAuth consent; the token is cached automatically

---

## Running

```bash
uv run python -m apps.desktop.app
```

---

## Using Zyzz

### Chat

Type any message and press **Enter**. Zyzz routes the query to the best AI model automatically.

| Signal | Routed to |
|---|---|
| Code, bugs, algorithms, analysis | Claude |
| Creative writing, translation, design | Gemini |
| General queries (default) | ChatGPT |

### Special commands

| Command | Description |
|---|---|
| `/compare <query>` | Send the query to all three AI providers in parallel and display all responses |
| `/run <name>` | Execute a saved automation by name |
| `remember that <fact>` | Store a fact in long-term memory |
| `gastei 50 reais no ifood` | Log an expense to the Finance module (AI interprets naturally) |

### Voice

Click the **microphone button** to start recording. Click again to stop. The audio is transcribed via Whisper and sent automatically. The AI response is also spoken aloud when voice input is used.

### Automations

Ask Zyzz to create one:

> "Create an automation called 'daily briefing' that fetches my calendar agenda for today and summarizes what I need to do"

Then trigger it any time with `/run daily briefing`.

### Memory

```
remember that my preferred coding language is Python
remember that I work in the fintech industry
```

These facts are injected as context into every subsequent prompt.

---

## Building a Standalone Package

Requires [PyInstaller](https://pyinstaller.org/):

```bash
pip install pyinstaller
python scripts/build_installer.py
```

The packaged application is output to `dist/Zyzz/`. Distribute the entire `Zyzz/` folder.

---

## Project Structure

```
Zyzz/
├── apps/desktop/          # PySide6 + QML desktop application (UI layer)
│   ├── ui/qml/            # QML components (main, core, input bar, panels)
│   └── ui/web/            # Embedded web modules (Finance via React/WebEngine)
├── core/
│   ├── router/            # Prompt routing and provider selection
│   ├── providers/         # Claude, ChatGPT, Gemini implementations
│   ├── memory/            # Long-term memory persistence
│   ├── history/           # Conversation history persistence
│   ├── voice/             # Speech-to-text and text-to-speech
│   ├── tools/             # Tool registry and built-in tools
│   ├── calendar/          # Google Calendar integration
│   ├── automations/       # Saved workflow automations
│   ├── shared/            # System metrics (psutil), utilities
│   └── brain/             # Multi-provider orchestration
├── scripts/               # Build and utility scripts
└── tests/                 # Test suite
```

---

## Author

Pedro Funes

---

## Version

**1.1.0**
