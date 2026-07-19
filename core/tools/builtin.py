from __future__ import annotations

import ast
import operator
import subprocess
from datetime import datetime, timezone
from pathlib import Path

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

    return registry
