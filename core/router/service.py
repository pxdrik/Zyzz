from core.router.models import Provider, RouteDecision


class RouterService:
    @staticmethod
    def route(self, prompt: str) -> RouteDecision:
        prompt = prompt.lower()

        if any(word in prompt for word in ["python", "código", "erro", "bug"]):
            return RouteDecision(
                provider=Provider.CLAUDE,
                reason="Programming task",
            )

        if any(word in prompt for word in ["imagem", "logo", "design"]):
            return RouteDecision(
                provider=Provider.GEMINI,
                reason="Image generation",
            )

        return RouteDecision(
            provider=Provider.CHATGPT,
            reason="General reasoning",
        )
