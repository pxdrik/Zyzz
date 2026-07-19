from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed

from core.providers.providers import get_provider
from core.router.models import Provider


class Orchestrator:
    """Coordinates multi-provider workflows and parallel execution."""

    _ALL_PROVIDERS: tuple[Provider, ...] = (
        Provider.CLAUDE,
        Provider.CHATGPT,
        Provider.GEMINI,
    )

    def run_all_parallel(self, prompt: str) -> list[tuple[str, str]]:
        """Run all three providers simultaneously and return results as (provider_name, response).

        Results are returned in the order they complete (fastest first).
        """

        def _generate(provider: Provider) -> tuple[str, str]:
            try:
                response = get_provider(provider).generate([{"role": "user", "content": prompt}])
                return (provider.value, response)
            except Exception as exc:
                return (provider.value, f"Erro: {exc}")

        results: list[tuple[str, str]] = []
        with ThreadPoolExecutor(max_workers=len(self._ALL_PROVIDERS)) as executor:
            futures = {executor.submit(_generate, p): p for p in self._ALL_PROVIDERS}
            for future in as_completed(futures):
                results.append(future.result())

        return results
