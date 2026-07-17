"""
ZYZZ Desktop Assistant
=======================
Ponto de entrada da aplicação.

Responsável por:
    - Inicializar o QApplication
    - Configurar DPI / fontes globais
    - Carregar o stylesheet (.qss)
    - Instanciar e exibir a MainWindow
"""

from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from PySide6.QtWidgets import QApplication

from apps.desktop.windows.main_window import MainWindow

BASE_DIR = Path(__file__).resolve().parent
STYLE_PATH = BASE_DIR / "ui" / "style.qss"


def load_stylesheet(app: QApplication) -> None:
    """Carrega o stylesheet (.qss) global da aplicação, se existir."""
    try:
        with open(STYLE_PATH, "r", encoding="utf-8") as file:
            app.setStyleSheet(file.read())
    except FileNotFoundError:
        print(f"[ZYZZ] Aviso: stylesheet não encontrado em: {STYLE_PATH}")


def configure_application(app: QApplication) -> None:
    """Configurações globais de identidade visual e comportamento da app."""
    app.setApplicationName("ZYZZ")
    app.setApplicationDisplayName("ZYZZ")
    app.setOrganizationName("ZYZZ")

    # Tipografia padrão. Faz fallback silencioso caso a fonte não exista no SO.
    default_font = QFont("Segoe UI", 10)
    default_font.setStyleStrategy(QFont.StyleStrategy.PreferAntialias)
    app.setFont(default_font)


def main() -> None:
    # Garante escala correta em telas HiDPI (multi-monitor, notebooks 4K, etc.)
    QApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QApplication(sys.argv)
    configure_application(app)
    load_stylesheet(app)

    window = MainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
