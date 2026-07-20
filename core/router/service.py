from __future__ import annotations

import re

from core.router.models import Provider, RouteDecision


def _word_match(keyword: str, text: str) -> bool:
    """Check if keyword appears as a whole word in text."""
    return bool(re.search(rf"\b{re.escape(keyword)}\b", text))

# Keywords that signal a task suited for Claude (technical, analytical, code-heavy)
_CLAUDE_KEYWORDS: frozenset[str] = frozenset({
    # Programming
    "python", "javascript", "typescript", "java", "rust", "c++", "golang", "sql",
    "code", "código", "bug", "erro", "error", "debug", "debugar", "algorithm",
    "algoritmo", "function", "função", "class", "classe", "api", "software",
    "programar", "program", "refactor", "refatorar", "test", "teste",
    # Analysis & reasoning
    "analyze", "analisar", "analyse", "reasoning", "logic", "lógica",
    "math", "matemática", "explain", "explique", "complex", "complexo",
    "review", "revisar", "compare", "comparar", "evaluate", "avaliar",
    "architecture", "arquitetura", "database", "banco de dados",
})

# Keywords that signal a task suited for Gemini (creative, linguistic, multimodal)
_GEMINI_KEYWORDS: frozenset[str] = frozenset({
    # Creative writing
    "write", "escreva", "story", "história", "poem", "poema", "creative", "criativo",
    "script", "roteiro", "narrative", "narrativa", "fiction", "ficção",
    # Visual & design
    "image", "imagem", "photo", "foto", "video", "vídeo", "design",
    "visual", "art", "arte", "logo", "illustration", "ilustração",
    # Language & translation
    "translate", "traduzir", "traduz", "language", "língua", "idioma",
    "grammar", "gramática", "spelling", "ortografia",
    # Brainstorm
    "brainstorm", "ideas", "ideias", "suggest", "sugira", "creative",
})


class RouterService:
    """Routes a user prompt to the most appropriate AI provider."""

    def route(self, prompt: str) -> RouteDecision:
        """Analyse the prompt and return a RouteDecision with provider, reason, complexity and confidence."""
        lower = prompt.lower()
        word_count = len(lower.split())
        complexity = self._estimate_complexity(word_count)

        # Count keyword matches per provider
        claude_matches = sum(1 for kw in _CLAUDE_KEYWORDS if _word_match(kw, lower))
        gemini_matches = sum(1 for kw in _GEMINI_KEYWORDS if _word_match(kw, lower))

        # Pick the provider with the strongest keyword signal
        if claude_matches >= gemini_matches and claude_matches > 0:
            confidence = min(1.0, 0.4 + claude_matches * 0.2)
            return RouteDecision(
                provider=Provider.CLAUDE,
                reason=f"Technical/analytical signal ({claude_matches} keyword(s) matched)",
                complexity=complexity,
                confidence=confidence,
            )

        if gemini_matches > 0:
            confidence = min(1.0, 0.4 + gemini_matches * 0.2)
            return RouteDecision(
                provider=Provider.GEMINI,
                reason=f"Creative/linguistic signal ({gemini_matches} keyword(s) matched)",
                complexity=complexity,
                confidence=confidence,
            )

        # Default: Gemini for all queries (primary provider)
        return RouteDecision(
            provider=Provider.GEMINI,
            reason="Default provider — Gemini",
            complexity=complexity,
            confidence=0.6,
        )

    def _estimate_complexity(self, word_count: int) -> str:
        """Return a complexity label based on prompt length."""
        if word_count <= 8:
            return "simple"
        if word_count <= 50:
            return "medium"
        return "complex"
