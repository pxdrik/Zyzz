from datetime import datetime

from core.router.service import RouterService


def print_banner():
    print("=" * 50)
    print("🧠 ZYZZ")
    print("=" * 50)


def startup():
    print_banner()
    print(f"📅 Date: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print("✅ System initialized")
    print()


def main():
    startup()

    router = RouterService()

    prompt = "Explique esse código Python"

    decision = router.route(prompt)

    print(f"Prompt: {prompt}")
    print(f"Provider escolhido: {decision.provider.value}")
    print(f"Motivo: {decision.reason}")


if __name__ == "__main__":
    main()
