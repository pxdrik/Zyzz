from __future__ import annotations

import ast
import operator
import os
import smtplib
import subprocess
from datetime import datetime, timezone
from email.mime.text import MIMEText
from pathlib import Path

from core.automations.service import AutomationService
from core.calendar.service import CalendarService
from core.tools.models import ToolSpec
from core.tools.registry import ToolRegistry


# --------------------------------------------------------------------------- #
# Tool implementations
# --------------------------------------------------------------------------- #


def _calculator(expression: str) -> str:
    """Safely evaluate a mathematical expression using the AST."""
    _OPS: dict[type, object] = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.Mult: operator.mul,
        ast.Div: operator.truediv,
        ast.Pow: operator.pow,
        ast.Mod: operator.mod,
        ast.USub: operator.neg,
    }

    def _eval(node: ast.expr) -> float:
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return float(node.value)
        if isinstance(node, ast.BinOp):
            op_type = type(node.op)
            if op_type not in _OPS:
                raise ValueError(f"Unsupported operator: {op_type.__name__}")
            return _OPS[op_type](_eval(node.left), _eval(node.right))  # type: ignore[operator]
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            return -_eval(node.operand)
        raise ValueError(f"Unsupported expression node: {type(node).__name__}")

    tree = ast.parse(expression.strip(), mode="eval")
    result = _eval(tree.body)
    # Return int representation when there is no fractional part
    return str(int(result)) if result == int(result) else str(result)


def _get_current_datetime() -> str:
    """Return the current UTC date and time as a formatted string."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def _read_file(path: str) -> str:
    """Read and return the text content of a file."""
    return Path(path).read_text(encoding="utf-8")


def _run_command(command: str) -> str:
    """Execute a shell command and return its combined stdout/stderr output."""
    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        timeout=30,
    )
    output = (result.stdout + result.stderr).strip()
    return output if output else "(no output)"


# --------------------------------------------------------------------------- #
# Registry builder
# --------------------------------------------------------------------------- #


# --------------------------------------------------------------------------- #
# Automation tool wrappers
# --------------------------------------------------------------------------- #

_automations = AutomationService()


def _create_automation(name: str, description: str, prompt: str) -> str:
    """Create or overwrite a saved automation."""
    a = _automations.create(name=name, description=description, prompt=prompt)
    return f"Automação criada: '{a.name}' (ID: {a.id})"


def _list_automations() -> str:
    """Return a formatted list of all saved automations."""
    items = _automations.list()
    if not items:
        return "Nenhuma automação cadastrada ainda."
    return "\n".join(f"- {a.name}: {a.description}" for a in items)


def _delete_automation(name: str) -> str:
    """Delete the named automation."""
    if _automations.delete(name):
        return f"Automação '{name}' removida."
    return f"Automação '{name}' não encontrada."


# --------------------------------------------------------------------------- #
# Email tool
# --------------------------------------------------------------------------- #


def _send_email(to: str, subject: str, body: str) -> str:
    """Send an email via SMTP using credentials from environment variables."""
    host = os.environ.get("SMTP_HOST", "smtp.gmail.com")
    port = int(os.environ.get("SMTP_PORT", "587"))
    user = os.environ.get("SMTP_USER", "")
    password = os.environ.get("SMTP_PASSWORD", "")
    from_addr = os.environ.get("SMTP_FROM", user)

    if not user or not password:
        raise ValueError("SMTP_USER and SMTP_PASSWORD must be configured in the .env file.")

    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = from_addr
    msg["To"] = to

    with smtplib.SMTP(host, port) as server:
        server.starttls()
        server.login(user, password)
        server.sendmail(from_addr, [to], msg.as_string())

    return f"Email enviado para {to} com o assunto '{subject}'."


# --------------------------------------------------------------------------- #
# Calendar tool wrappers
# --------------------------------------------------------------------------- #

_calendar = CalendarService()


def _list_upcoming_events(max_results: int = 10, days_ahead: int = 7) -> str:
    """Return a formatted list of upcoming Google Calendar events."""
    events = _calendar.list_events(max_results=max_results, days_ahead=days_ahead)
    if not events:
        return "Nenhum evento encontrado."
    lines = []
    for e in events:
        line = f"- {e.title}: {e.start}"
        if e.location:
            line += f" ({e.location})"
        lines.append(line)
    return "\n".join(lines)


def _get_daily_agenda(date: str = "") -> str:
    """Return the events scheduled for a specific day."""
    events = _calendar.get_daily_agenda(date or None)
    if not events:
        return "Nenhum evento agendado para esse dia."
    return "\n".join(f"- {e.title}: {e.start} — {e.end}" for e in events)


def _create_calendar_event(
    title: str, start: str, end: str, description: str = "", location: str = ""
) -> str:
    """Create a calendar event and return a confirmation message."""
    event = _calendar.create_event(
        title=title, start=start, end=end, description=description, location=location
    )
    return f"Evento criado: '{event.title}' em {event.start} (ID: {event.id})"


# --------------------------------------------------------------------------- #
# Registry builder
# --------------------------------------------------------------------------- #


def build_registry() -> ToolRegistry:
    """Create and return a ToolRegistry populated with all built-in tools."""
    registry = ToolRegistry()

    registry.register(
        ToolSpec(
            name="calculator",
            description=(
                "Evaluate a mathematical expression and return the result. "
                "Supports +, -, *, /, ** (power), and % (modulo)."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "expression": {
                        "type": "string",
                        "description": "Math expression to evaluate, e.g. '2 + 2' or '(10 * 3) / 4'.",
                    }
                },
                "required": ["expression"],
            },
        ),
        _calculator,
    )

    registry.register(
        ToolSpec(
            name="get_current_datetime",
            description="Return the current date and time in UTC.",
            parameters={"type": "object", "properties": {}},
        ),
        _get_current_datetime,
    )

    registry.register(
        ToolSpec(
            name="read_file",
            description="Read the text contents of a file at the given path.",
            parameters={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Absolute or relative path to the file to read.",
                    }
                },
                "required": ["path"],
            },
        ),
        _read_file,
    )

    registry.register(
        ToolSpec(
            name="run_command",
            description="Execute a shell command and return its output.",
            parameters={
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "description": "Shell command to run, e.g. 'echo hello' or 'dir'.",
                    }
                },
                "required": ["command"],
            },
        ),
        _run_command,
    )

    registry.register(
        ToolSpec(
            name="create_automation",
            description=(
                "Save a new automation (a reusable workflow) with a name, description, and prompt. "
                "The user can later run it by typing '/run <name>' in the chat."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Short unique name for the automation."},
                    "description": {"type": "string", "description": "One-line description of what it does."},
                    "prompt": {"type": "string", "description": "The full prompt that will be sent to the AI when this automation runs."},
                },
                "required": ["name", "description", "prompt"],
            },
        ),
        _create_automation,
    )

    registry.register(
        ToolSpec(
            name="list_automations",
            description="List all saved automations with their names and descriptions.",
            parameters={"type": "object", "properties": {}},
        ),
        _list_automations,
    )

    registry.register(
        ToolSpec(
            name="delete_automation",
            description="Delete a saved automation by name.",
            parameters={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Name of the automation to delete."},
                },
                "required": ["name"],
            },
        ),
        _delete_automation,
    )

    registry.register(
        ToolSpec(
            name="send_email",
            description=(
                "Send an email via SMTP. Requires SMTP_HOST, SMTP_PORT, SMTP_USER, "
                "SMTP_PASSWORD and optionally SMTP_FROM in the environment."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "to": {"type": "string", "description": "Recipient email address."},
                    "subject": {"type": "string", "description": "Email subject line."},
                    "body": {"type": "string", "description": "Plain-text email body."},
                },
                "required": ["to", "subject", "body"],
            },
        ),
        _send_email,
    )

    registry.register(
        ToolSpec(
            name="list_upcoming_events",
            description=(
                "List upcoming events from the user's Google Calendar. "
                "Use this when the user asks about their schedule, upcoming meetings, or appointments."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "max_results": {
                        "type": "integer",
                        "description": "Maximum number of events to return (default 10).",
                    },
                    "days_ahead": {
                        "type": "integer",
                        "description": "How many days ahead to look (default 7).",
                    },
                },
            },
        ),
        _list_upcoming_events,
    )

    registry.register(
        ToolSpec(
            name="get_daily_agenda",
            description=(
                "Get the calendar events for a specific day. "
                "Use this when the user asks what they have scheduled on a particular date or today."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Date in YYYY-MM-DD format. Leave empty to use today.",
                    },
                },
            },
        ),
        _get_daily_agenda,
    )

    registry.register(
        ToolSpec(
            name="create_calendar_event",
            description=(
                "Create a new event in the user's Google Calendar. "
                "Use ISO 8601 format for start and end (e.g. 2024-03-15T14:00:00Z)."
            ),
            parameters={
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Event title or name."},
                    "start": {
                        "type": "string",
                        "description": "Start datetime in ISO 8601 format, e.g. 2024-03-15T14:00:00Z.",
                    },
                    "end": {
                        "type": "string",
                        "description": "End datetime in ISO 8601 format.",
                    },
                    "description": {"type": "string", "description": "Optional event description."},
                    "location": {"type": "string", "description": "Optional event location."},
                },
                "required": ["title", "start", "end"],
            },
        ),
        _create_calendar_event,
    )

    return registry
