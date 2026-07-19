from __future__ import annotations

from collections.abc import Callable

from core.tools.models import ToolResult, ToolSpec


class ToolRegistry:
    """Maps tool names to their specs and implementations.

    Providers query specs() to advertise tools to the model, then call
    execute() to run whichever tool the model requests.
    """

    def __init__(self) -> None:
        self._tools: dict[str, tuple[ToolSpec, Callable[..., str]]] = {}

    def register(self, spec: ToolSpec, fn: Callable[..., str]) -> None:
        """Register a tool with its spec and implementation function."""
        self._tools[spec.name] = (spec, fn)

    def specs(self) -> list[ToolSpec]:
        """Return the spec for every registered tool."""
        return [spec for spec, _ in self._tools.values()]

    def execute(self, name: str, params: dict) -> ToolResult:
        """Execute the named tool with the given parameters and return the result."""
        if name not in self._tools:
            return ToolResult(tool_name=name, output=f"Unknown tool: '{name}'", success=False)
        _, fn = self._tools[name]
        try:
            output = fn(**params)
            return ToolResult(tool_name=name, output=str(output), success=True)
        except Exception as exc:
            return ToolResult(tool_name=name, output=str(exc), success=False)

    def is_empty(self) -> bool:
        """Return True if no tools are registered."""
        return not self._tools
