"""
ZYZZ Desktop Assistant
=======================
Ponto de entrada da aplicação QML.

Responsável por:
    - Inicializar o QGuiApplication
    - Criar o ZyzzBridge (Python ↔ QML)
    - Carregar o QML engine e a UI principal
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWebEngineQuick import QtWebEngineQuick

from apps.desktop.bridge import ZyzzBridge

BASE_DIR = Path(__file__).resolve().parent
QML_DIR = BASE_DIR / "ui" / "qml"


def main() -> None:
    """Launch the Zyzz QML desktop application."""
    load_dotenv()

    # Initialize WebEngine before QGuiApplication (required by Qt)
    QtWebEngineQuick.initialize()

    # Force Basic style so Qt Quick Controls can be fully customized
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName("ZYZZ")
    app.setOrganizationName("ZYZZ")

    bridge = ZyzzBridge()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("zyzz", bridge)
    engine.addImportPath(str(QML_DIR))

    qml_file = QML_DIR / "main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        print("[ZYZZ] ERRO: Falha ao carregar main.qml", file=sys.stderr)
        sys.exit(1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
