from datetime import datetime


def print_banner():
    print("=" * 50)
    print("🧠 ZYZZ")
    print("=" * 50)


def startup():
    print_banner()

    print(f"📅 Date: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print("✅ System initialized")
    print("🚀 Welcome back, Pedro!")
    print()


def main():
    startup()


if __name__ == "__main__":
    main()
