"""
ZYZZ Desktop Assistant
=======================
Janela principal e componentes de UI reutilizáveis.

Este módulo contém, propositalmente, todos os widgets de interface
(sidebar, header, bolhas de chat, campo de mensagem) como classes
independentes e reutilizáveis, sem alterar a arquitetura de pastas
já definida no projeto (app.py / windows / ui).

A lógica de negócio (roteamento, processamento) vive em core/.
Este módulo apenas conecta sinais e delega ao ChatEngine.
"""

from __future__ import annotations

from dataclasses import dataclass

from PySide6.QtCore import Qt, Signal, QSize
from PySide6.QtGui import QKeyEvent, QResizeEvent
from PySide6.QtWidgets import (
    QWidget,
    QMainWindow,
    QFrame,
    QLabel,
    QPushButton,
    QTextEdit,
    QScrollArea,
    QVBoxLayout,
    QHBoxLayout,
    QSizePolicy,
    QButtonGroup,
)

from core.router.service import RouterService


# --------------------------------------------------------------------------- #
# Constantes de layout / responsividade
# --------------------------------------------------------------------------- #

SIDEBAR_EXPANDED_WIDTH = 240
SIDEBAR_COLLAPSED_WIDTH = 72
COLLAPSE_BREAKPOINT = 860  # abaixo dessa largura, a sidebar colapsa sozinha


# --------------------------------------------------------------------------- #
# Sidebar
# --------------------------------------------------------------------------- #


@dataclass(frozen=True)
class NavItem:
    key: str
    icon: str
    label: str


NAV_ITEMS = (
    NavItem("new_chat", "＋", "Novo chat"),
    NavItem("history", "🕘", "Histórico"),
    NavItem("favorites", "★", "Favoritos"),
    NavItem("settings", "⚙", "Configurações"),
)


class SidebarButton(QPushButton):
    """Botão de navegação da sidebar, com ícone + label que pode ser ocultado
    quando a sidebar está em modo colapsado (somente ícone)."""

    def __init__(self, item: NavItem, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self._item = item
        self.setObjectName("SidebarButton")
        self.setCheckable(True)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setMinimumHeight(40)

        self._layout = QHBoxLayout(self)
        self._layout.setContentsMargins(14, 0, 14, 0)
        self._layout.setSpacing(12)

        self._icon_label = QLabel(item.icon)
        self._icon_label.setObjectName("SidebarButtonIcon")
        self._icon_label.setFixedWidth(20)
        self._icon_label.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self._text_label = QLabel(item.label)
        self._text_label.setObjectName("SidebarButtonText")

        self._layout.addWidget(self._icon_label)
        self._layout.addWidget(self._text_label, 1)

    def set_collapsed(self, collapsed: bool) -> None:
        """Oculta o texto do botão quando a sidebar está colapsada."""
        self._text_label.setVisible(not collapsed)
        self.setToolTip(self._item.label if collapsed else "")


class Sidebar(QFrame):
    """Sidebar lateral com marca, navegação e botão de colapsar."""

    nav_selected = Signal(str)
    toggle_requested = Signal()

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("Sidebar")
        self._collapsed = False

        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        root.addWidget(self._build_brand_row())
        root.addWidget(self._build_divider())
        root.addLayout(self._build_nav())
        root.addStretch(1)
        root.addWidget(self._build_footer())

        self.setFixedWidth(SIDEBAR_EXPANDED_WIDTH)

    # -- construção -------------------------------------------------------- #

    def _build_brand_row(self) -> QWidget:
        row = QWidget()
        row.setObjectName("SidebarBrandRow")
        layout = QHBoxLayout(row)
        layout.setContentsMargins(18, 20, 14, 20)
        layout.setSpacing(10)

        mark = QLabel("Z")
        mark.setObjectName("BrandMark")
        mark.setFixedSize(32, 32)
        mark.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self._brand_text = QLabel("ZYZZ")
        self._brand_text.setObjectName("BrandText")

        layout.addWidget(mark)
        layout.addWidget(self._brand_text, 1)
        return row

    def _build_divider(self) -> QFrame:
        divider = QFrame()
        divider.setObjectName("SidebarDivider")
        divider.setFixedHeight(1)
        return divider

    def _build_nav(self) -> QVBoxLayout:
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 16, 12, 0)
        layout.setSpacing(4)

        self._button_group = QButtonGroup(self)
        self._button_group.setExclusive(True)
        self._nav_buttons: list[SidebarButton] = []

        for index, item in enumerate(NAV_ITEMS):
            button = SidebarButton(item)
            if index == 0:
                button.setChecked(True)
            button.clicked.connect(
                lambda _=False, key=item.key: self.nav_selected.emit(key)
            )
            self._button_group.addButton(button)
            self._nav_buttons.append(button)
            layout.addWidget(button)

        return layout

    def _build_footer(self) -> QWidget:
        row = QWidget()
        row.setObjectName("SidebarFooter")
        layout = QHBoxLayout(row)
        layout.setContentsMargins(12, 14, 12, 18)

        self._collapse_btn = QPushButton("«")
        self._collapse_btn.setObjectName("CollapseButton")
        self._collapse_btn.setFixedSize(32, 32)
        self._collapse_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._collapse_btn.clicked.connect(self.toggle_requested.emit)

        layout.addWidget(self._collapse_btn)
        layout.addStretch(1)
        return row

    # -- comportamento ------------------------------------------------------ #

    def set_collapsed(self, collapsed: bool) -> None:
        self._collapsed = collapsed
        self.setFixedWidth(
            SIDEBAR_COLLAPSED_WIDTH if collapsed else SIDEBAR_EXPANDED_WIDTH
        )
        self._brand_text.setVisible(not collapsed)
        self._collapse_btn.setText("»" if collapsed else "«")
        for button in self._nav_buttons:
            button.set_collapsed(collapsed)

    def is_collapsed(self) -> bool:
        return self._collapsed


# --------------------------------------------------------------------------- #
# Header
# --------------------------------------------------------------------------- #


class Header(QFrame):
    """Cabeçalho superior com título de contexto e status."""

    menu_requested = Signal()

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("Header")
        self.setFixedHeight(64)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(20, 0, 24, 0)
        layout.setSpacing(14)

        self._menu_btn = QPushButton("☰")
        self._menu_btn.setObjectName("MenuButton")
        self._menu_btn.setFixedSize(34, 34)
        self._menu_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._menu_btn.clicked.connect(self.menu_requested.emit)

        title_box = QVBoxLayout()
        title_box.setSpacing(0)

        title = QLabel("Assistente ZYZZ")
        title.setObjectName("HeaderTitle")

        subtitle = QLabel("Sempre pronto para ajudar")
        subtitle.setObjectName("HeaderSubtitle")

        title_box.addWidget(title)
        title_box.addWidget(subtitle)

        status = QWidget()
        status.setObjectName("StatusPill")
        status_layout = QHBoxLayout(status)
        status_layout.setContentsMargins(12, 6, 14, 6)
        status_layout.setSpacing(8)

        dot = QLabel()
        dot.setObjectName("StatusDot")
        dot.setFixedSize(8, 8)

        status_label = QLabel("Online")
        status_label.setObjectName("StatusLabel")

        status_layout.addWidget(dot)
        status_layout.addWidget(status_label)

        layout.addWidget(self._menu_btn)
        layout.addLayout(title_box)
        layout.addStretch(1)
        layout.addWidget(status)


# --------------------------------------------------------------------------- #
# Área de chat
# --------------------------------------------------------------------------- #


class MessageBubble(QFrame):
    """Bolha de mensagem individual, estilizada conforme o autor (role)."""

    def __init__(
        self, text: str, role: str = "assistant", parent: QWidget | None = None
    ) -> None:
        super().__init__(parent)
        self.setObjectName("MessageBubble")
        self.setProperty("role", role)

        outer = QHBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)

        bubble = QFrame()
        bubble.setObjectName("BubbleContent")
        bubble.setProperty("role", role)
        bubble.setMaximumWidth(560)
        bubble.setSizePolicy(QSizePolicy.Policy.Maximum, QSizePolicy.Policy.Preferred)

        inner = QVBoxLayout(bubble)
        inner.setContentsMargins(16, 12, 16, 12)

        label = QLabel(text)
        label.setObjectName("BubbleText")
        label.setWordWrap(True)
        label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)

        inner.addWidget(label)

        if role == "user":
            outer.addStretch(1)
            outer.addWidget(bubble)
        else:
            outer.addWidget(bubble)
            outer.addStretch(1)


class ChatArea(QScrollArea):
    """Área rolável que contém o histórico de mensagens da conversa."""

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("ChatScrollArea")
        self.setWidgetResizable(True)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.setFrameShape(QFrame.Shape.NoFrame)

        container = QWidget()
        container.setObjectName("ChatContainer")

        self._layout = QVBoxLayout(container)
        self._layout.setContentsMargins(32, 24, 32, 24)
        self._layout.setSpacing(16)
        self._layout.addStretch(1)

        self.setWidget(container)

    def add_message(self, text: str, role: str = "assistant") -> None:
        bubble = MessageBubble(text, role)
        # insere antes do stretch final, mantendo mensagens ancoradas no topo
        self._layout.insertWidget(self._layout.count() - 1, bubble)
        self._scroll_to_bottom()

    def _scroll_to_bottom(self) -> None:
        bar = self.verticalScrollBar()
        bar.setValue(bar.maximum())


# --------------------------------------------------------------------------- #
# Campo de mensagem
# --------------------------------------------------------------------------- #


class ChatTextEdit(QTextEdit):
    """QTextEdit customizado: Enter envia, Shift+Enter quebra linha,
    e a altura cresce automaticamente até um limite máximo."""

    submitted = Signal()

    MIN_HEIGHT = 44
    MAX_HEIGHT = 160

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("MessageInput")
        self.setPlaceholderText("Envie uma mensagem para o ZYZZ...")
        self.setAcceptRichText(False)
        self.setFixedHeight(self.MIN_HEIGHT)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        self.textChanged.connect(self._auto_resize)

    def keyPressEvent(self, event: QKeyEvent) -> None:  # noqa: N802 (Qt override)
        is_enter = event.key() in (Qt.Key.Key_Return, Qt.Key.Key_Enter)
        if is_enter and not (event.modifiers() & Qt.KeyboardModifier.ShiftModifier):
            self.submitted.emit()
            return
        super().keyPressEvent(event)

    def _auto_resize(self) -> None:
        doc_height = int(self.document().size().height()) + 16
        new_height = max(self.MIN_HEIGHT, min(doc_height, self.MAX_HEIGHT))
        self.setFixedHeight(new_height)


class MessageInputBar(QFrame):
    """Barra inferior com o campo de mensagem e o botão de enviar."""

    message_sent = Signal(str)

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("InputBar")

        outer = QVBoxLayout(self)
        outer.setContentsMargins(24, 12, 24, 20)

        wrapper = QFrame()
        wrapper.setObjectName("InputWrapper")

        layout = QHBoxLayout(wrapper)
        layout.setContentsMargins(16, 6, 10, 6)
        layout.setSpacing(10)

        self._input = ChatTextEdit()
        self._input.submitted.connect(self._handle_send)

        self._send_btn = QPushButton("➤")
        self._send_btn.setObjectName("SendButton")
        self._send_btn.setFixedSize(38, 38)
        self._send_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._send_btn.clicked.connect(self._handle_send)

        layout.addWidget(self._input, 1)
        layout.addWidget(self._send_btn, 0, Qt.AlignmentFlag.AlignBottom)

        hint = QLabel("Enter para enviar · Shift+Enter para nova linha")
        hint.setObjectName("InputHint")
        hint.setAlignment(Qt.AlignmentFlag.AlignCenter)

        outer.addWidget(wrapper)
        outer.addWidget(hint)

    def _handle_send(self) -> None:
        text = self._input.toPlainText().strip()
        if not text:
            return
        self.message_sent.emit(text)
        self._input.clear()


# --------------------------------------------------------------------------- #
# Janela principal
# --------------------------------------------------------------------------- #


class MainWindow(QMainWindow):
    """Janela principal do ZYZZ: sidebar + header + chat + input."""

    def __init__(self) -> None:
        super().__init__()
        self.setObjectName("MainWindow")
        self.setWindowTitle("ZYZZ")
        self.resize(1180, 760)
        self.setMinimumSize(QSize(720, 480))

        self._router = RouterService()

        self._sidebar = Sidebar()
        self._header = Header()
        self._chat_area = ChatArea()
        self._input_bar = MessageInputBar()

        self._sidebar.toggle_requested.connect(self._toggle_sidebar)
        self._header.menu_requested.connect(self._toggle_sidebar)
        self._input_bar.message_sent.connect(self._on_message_sent)

        self._build_layout()
        self._seed_welcome_messages()

    # -- layout -------------------------------------------------------------- #

    def _build_layout(self) -> None:
        central = QWidget()
        central.setObjectName("CentralWidget")

        root_layout = QHBoxLayout(central)
        root_layout.setContentsMargins(0, 0, 0, 0)
        root_layout.setSpacing(0)

        content = QWidget()
        content.setObjectName("ContentArea")
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(0)

        content_layout.addWidget(self._header)
        content_layout.addWidget(self._chat_area, 1)
        content_layout.addWidget(self._input_bar)

        root_layout.addWidget(self._sidebar)
        root_layout.addWidget(content, 1)

        self.setCentralWidget(central)

    def _seed_welcome_messages(self) -> None:
        self._chat_area.add_message(
            "Olá! Eu sou o ZYZZ 👋. Este é apenas o layout visual — "
            "a inteligência ainda será conectada nas próximas etapas.",
            role="assistant",
        )

    # -- eventos --------------------------------------------------------------- #

    def _on_message_sent(self, text: str) -> None:
        self._chat_area.add_message(text, role="user")
        decision = self._router.route(text)
        reply = f"Provider selected:\n{decision.provider.value}\n\nReason:\n{decision.reason}"
        self._chat_area.add_message(reply, role="assistant")

    def _toggle_sidebar(self) -> None:
        self._sidebar.set_collapsed(not self._sidebar.is_collapsed())

    def resizeEvent(self, event: QResizeEvent) -> None:  # noqa: N802 (Qt override)
        super().resizeEvent(event)
        should_collapse = self.width() < COLLAPSE_BREAKPOINT
        if should_collapse != self._sidebar.is_collapsed():
            self._sidebar.set_collapsed(should_collapse)
