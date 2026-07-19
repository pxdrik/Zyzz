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

import sys
from dataclasses import dataclass
from datetime import datetime, timezone

from PySide6.QtCore import Qt, Signal, QSize, QThread, QTimer, QEvent
from PySide6.QtGui import QKeyEvent, QResizeEvent, QEnterEvent, QMouseEvent
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
    QInputDialog,
)

from core.automations.service import AutomationService
from core.history.models import Conversation, Message
from core.history.service import ConversationService
from core.memory.service import MemoryService
from core.providers.providers import BaseProvider, get_provider
from core.router.service import RouterService
from core.voice.service import VoiceService


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


class ConversationItem(QWidget):
    """Row item representing a single conversation in the sidebar list."""

    clicked = Signal(str)
    delete_requested = Signal(str)
    rename_requested = Signal(str)

    def __init__(self, conversation: Conversation, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self._id = conversation.id
        self.setObjectName("ConversationItem")
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setAttribute(Qt.WidgetAttribute.WA_Hover, True)

        layout = QHBoxLayout(self)
        layout.setContentsMargins(8, 5, 6, 5)
        layout.setSpacing(4)

        self._title_label = QLabel(conversation.title)
        self._title_label.setObjectName("ConversationTitle")

        self._del_btn = QPushButton("×")
        self._del_btn.setObjectName("ConversationDeleteButton")
        self._del_btn.setFixedSize(18, 18)
        self._del_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._del_btn.clicked.connect(lambda: self.delete_requested.emit(self._id))
        self._del_btn.hide()

        layout.addWidget(self._title_label, 1)
        layout.addWidget(self._del_btn)

    def set_title(self, title: str) -> None:
        """Update the displayed conversation title."""
        self._title_label.setText(title)

    def enterEvent(self, event: QEnterEvent) -> None:  # noqa: N802
        self._del_btn.show()
        super().enterEvent(event)

    def leaveEvent(self, event: QEvent) -> None:  # noqa: N802
        self._del_btn.hide()
        super().leaveEvent(event)

    def mousePressEvent(self, event: QMouseEvent) -> None:  # noqa: N802
        if event.button() == Qt.MouseButton.LeftButton:
            self.clicked.emit(self._id)
        super().mousePressEvent(event)

    def mouseDoubleClickEvent(self, event: QMouseEvent) -> None:  # noqa: N802
        if event.button() == Qt.MouseButton.LeftButton:
            self.rename_requested.emit(self._id)
        super().mouseDoubleClickEvent(event)


class ConversationListPanel(QScrollArea):
    """Scrollable list of conversation items shown in the sidebar."""

    conversation_selected = Signal(str)
    conversation_deleted = Signal(str)
    conversation_renamed = Signal(str)

    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setObjectName("ConversationListPanel")
        self.setWidgetResizable(True)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.setFrameShape(QFrame.Shape.NoFrame)

        container = QWidget()
        container.setObjectName("ConversationListContainer")
        self._layout = QVBoxLayout(container)
        self._layout.setContentsMargins(0, 0, 0, 0)
        self._layout.setSpacing(2)
        self._layout.addStretch(1)
        self.setWidget(container)

        self._items: dict[str, ConversationItem] = {}

    def load_conversations(self, conversations: list[Conversation]) -> None:
        """Replace the current list with the given conversations."""
        for item in self._items.values():
            item.deleteLater()
        self._items.clear()
        for conv in conversations:
            self._insert_item(conv, at_top=False)

    def add_conversation(self, conversation: Conversation) -> None:
        """Prepend a new conversation to the top of the list."""
        self._insert_item(conversation, at_top=True)

    def remove_conversation(self, conv_id: str) -> None:
        """Remove a conversation item from the list."""
        if item := self._items.pop(conv_id, None):
            self._layout.removeWidget(item)
            item.deleteLater()

    def update_title(self, conv_id: str, title: str) -> None:
        """Update the title label for a specific conversation."""
        if item := self._items.get(conv_id):
            item.set_title(title)

    def _insert_item(self, conversation: Conversation, at_top: bool) -> None:
        item = ConversationItem(conversation)
        item.clicked.connect(self.conversation_selected)
        item.delete_requested.connect(self.conversation_deleted)
        item.rename_requested.connect(self.conversation_renamed)
        self._items[conversation.id] = item
        index = 0 if at_top else self._layout.count() - 1
        self._layout.insertWidget(index, item)


class Sidebar(QFrame):
    """Sidebar lateral com marca, navegação e botão de colapsar."""

    nav_selected = Signal(str)
    toggle_requested = Signal()
    conversation_selected = Signal(str)
    conversation_deleted = Signal(str)
    conversation_renamed = Signal(str)

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
        root.addWidget(self._build_divider())
        root.addWidget(self._build_conv_header())
        self._conv_panel = ConversationListPanel()
        self._conv_panel.conversation_selected.connect(self.conversation_selected)
        self._conv_panel.conversation_deleted.connect(self.conversation_deleted)
        self._conv_panel.conversation_renamed.connect(self.conversation_renamed)
        root.addWidget(self._conv_panel, 1)
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

    def _build_conv_header(self) -> QWidget:
        row = QWidget()
        layout = QHBoxLayout(row)
        layout.setContentsMargins(20, 10, 12, 4)
        label = QLabel("CONVERSAS")
        label.setObjectName("ConversationSectionLabel")
        layout.addWidget(label)
        return row

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
        self._conv_panel.setVisible(not collapsed)
        for button in self._nav_buttons:
            button.set_collapsed(collapsed)

    def is_collapsed(self) -> bool:
        return self._collapsed

    def load_conversations(self, conversations: list[Conversation]) -> None:
        """Populate the conversation list."""
        self._conv_panel.load_conversations(conversations)

    def add_conversation(self, conversation: Conversation) -> None:
        """Add a conversation to the top of the list."""
        self._conv_panel.add_conversation(conversation)

    def remove_conversation(self, conv_id: str) -> None:
        """Remove a conversation from the list."""
        self._conv_panel.remove_conversation(conv_id)

    def update_conversation_title(self, conv_id: str, title: str) -> None:
        """Update the title of a conversation in the list."""
        self._conv_panel.update_title(conv_id, title)


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

        self._label = QLabel(text)
        self._label.setObjectName("BubbleText")
        self._label.setWordWrap(True)
        self._label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)

        inner.addWidget(self._label)

        if role == "user":
            outer.addStretch(1)
            outer.addWidget(bubble)
        else:
            outer.addWidget(bubble)
            outer.addStretch(1)

    def set_text(self, text: str) -> None:
        """Replace the bubble text content."""
        self._label.setText(text)


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
        """Add a complete message bubble to the chat."""
        bubble = MessageBubble(text, role)
        self._layout.insertWidget(self._layout.count() - 1, bubble)
        QTimer.singleShot(0, self._scroll_to_bottom)

    def clear_messages(self) -> None:
        """Remove all message bubbles from the chat area."""
        while self._layout.count() > 1:
            item = self._layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

    def start_message(self, role: str = "assistant") -> MessageBubble:
        """Add an empty bubble and return it for incremental text updates."""
        bubble = MessageBubble("", role)
        self._layout.insertWidget(self._layout.count() - 1, bubble)
        return bubble

    def scroll_to_bottom(self) -> None:
        """Scroll the chat area to the bottom."""
        QTimer.singleShot(0, self._scroll_to_bottom)

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
    """Barra inferior com o campo de mensagem, botão de microfone e botão de enviar."""

    message_sent = Signal(str)
    mic_clicked = Signal()

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

        self._mic_btn = QPushButton("🎙")
        self._mic_btn.setObjectName("MicButton")
        self._mic_btn.setFixedSize(38, 38)
        self._mic_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._mic_btn.setProperty("recording", False)
        self._mic_btn.clicked.connect(self.mic_clicked.emit)

        self._send_btn = QPushButton("➤")
        self._send_btn.setObjectName("SendButton")
        self._send_btn.setFixedSize(38, 38)
        self._send_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self._send_btn.clicked.connect(self._handle_send)

        layout.addWidget(self._input, 1)
        layout.addWidget(self._mic_btn, 0, Qt.AlignmentFlag.AlignBottom)
        layout.addWidget(self._send_btn, 0, Qt.AlignmentFlag.AlignBottom)

        hint = QLabel("Enter para enviar · Shift+Enter para nova linha · 🎙 para voz")
        hint.setObjectName("InputHint")
        hint.setAlignment(Qt.AlignmentFlag.AlignCenter)

        outer.addWidget(wrapper)
        outer.addWidget(hint)

    def set_recording(self, recording: bool) -> None:
        """Update the mic button appearance to reflect recording state."""
        self._mic_btn.setText("⏹" if recording else "🎙")
        self._mic_btn.setProperty("recording", recording)
        self._mic_btn.style().unpolish(self._mic_btn)
        self._mic_btn.style().polish(self._mic_btn)

    def set_transcribed_text(self, text: str) -> None:
        """Insert transcribed text into the input field."""
        self._input.setPlainText(text)

    def _handle_send(self) -> None:
        text = self._input.toPlainText().strip()
        if not text:
            return
        self.message_sent.emit(text)
        self._input.clear()


# --------------------------------------------------------------------------- #
# Worker de streaming
# --------------------------------------------------------------------------- #


class ParallelWorker(QThread):
    """Runs all AI providers simultaneously and emits each result as it completes."""

    result_received = Signal(str, str)  # provider_name, response_text

    def __init__(self, prompt: str) -> None:
        super().__init__()
        self._prompt = prompt

    def run(self) -> None:
        """Dispatch the prompt to all providers in parallel via the Orchestrator."""
        from core.brain.orchestrator import Orchestrator

        orchestrator = Orchestrator()
        for provider_name, response in orchestrator.run_all_parallel(self._prompt):
            self.result_received.emit(provider_name, response)


class StreamWorker(QThread):
    """Runs a provider.stream() call in a background thread and emits each chunk."""

    chunk_received = Signal(str)

    def __init__(self, provider: BaseProvider, prompt: str) -> None:
        super().__init__()
        self._provider = provider
        self._prompt = prompt

    def run(self) -> None:
        for chunk in self._provider.stream(self._prompt):
            self.chunk_received.emit(chunk)


class RecordWorker(QThread):
    """Records audio from the microphone and emits the path to the saved WAV file when stopped."""

    recording_stopped = Signal(str)

    SAMPLE_RATE = 16000

    def __init__(self) -> None:
        super().__init__()
        self._active = True

    def stop_recording(self) -> None:
        """Signal the worker to stop recording."""
        self._active = False

    def run(self) -> None:
        """Record microphone input until stop_recording() is called, then save to a temp WAV."""
        import tempfile

        import numpy as np
        import sounddevice as sd
        import soundfile as sf

        frames: list[np.ndarray] = []

        def callback(indata: np.ndarray, _frames: int, _time: object, _status: object) -> None:
            frames.append(indata.copy())

        try:
            with sd.InputStream(
                samplerate=self.SAMPLE_RATE, channels=1, dtype="float32", callback=callback
            ):
                while self._active:
                    self.msleep(100)
        except Exception as exc:
            print(f"RecordWorker error: {exc}", file=sys.stderr)
            return

        if not frames:
            return

        audio = np.concatenate(frames, axis=0)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            sf.write(tmp.name, audio, self.SAMPLE_RATE)
            self.recording_stopped.emit(tmp.name)


class TranscribeWorker(QThread):
    """Transcribes an audio file using VoiceService in a background thread."""

    transcription_ready = Signal(str)

    def __init__(self, voice_service: VoiceService, audio_path: str) -> None:
        super().__init__()
        self._voice_service = voice_service
        self._audio_path = audio_path

    def run(self) -> None:
        """Send the audio file to Whisper and emit the resulting text."""
        text = self._voice_service.transcribe(self._audio_path)
        self.transcription_ready.emit(text)


class TtsWorker(QThread):
    """Speaks text using VoiceService in a background thread."""

    def __init__(self, voice_service: VoiceService, text: str) -> None:
        super().__init__()
        self._voice_service = voice_service
        self._text = text

    def run(self) -> None:
        """Speak the stored text via the system TTS engine."""
        self._voice_service.speak(self._text)


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
        self._conv_service = ConversationService()
        self._memory_service = MemoryService()
        self._automation_service = AutomationService()
        self._voice_service = VoiceService()
        self._current_conv: Conversation | None = None
        self._worker: StreamWorker | None = None
        self._parallel_worker: ParallelWorker | None = None
        self._record_worker: RecordWorker | None = None
        self._transcribe_worker: TranscribeWorker | None = None
        self._tts_worker: TtsWorker | None = None
        self._is_recording = False

        self._sidebar = Sidebar()
        self._header = Header()
        self._chat_area = ChatArea()
        self._input_bar = MessageInputBar()

        self._sidebar.toggle_requested.connect(self._toggle_sidebar)
        self._sidebar.nav_selected.connect(self._on_nav_selected)
        self._sidebar.conversation_selected.connect(self._on_conversation_selected)
        self._sidebar.conversation_deleted.connect(self._on_conversation_deleted)
        self._sidebar.conversation_renamed.connect(self._on_conversation_renamed)
        self._header.menu_requested.connect(self._toggle_sidebar)
        self._input_bar.message_sent.connect(self._on_message_sent)
        self._input_bar.mic_clicked.connect(self._on_mic_clicked)

        self._build_layout()
        self._init_conversations()

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
            "Olá! Eu sou o ZYZZ. Como posso ajudar?",
            role="assistant",
        )

    def _init_conversations(self) -> None:
        conversations = self._conv_service.list()
        self._sidebar.load_conversations(conversations)
        if conversations:
            self._current_conv = conversations[0]
            for msg in conversations[0].messages:
                self._chat_area.add_message(msg.text, role=msg.role)
        else:
            self._current_conv = self._conv_service.create()
            self._sidebar.add_conversation(self._current_conv)
            self._seed_welcome_messages()

    # -- eventos --------------------------------------------------------------- #

    def _on_nav_selected(self, key: str) -> None:
        if key == "new_chat":
            self._on_new_chat()

    def _on_new_chat(self) -> None:
        self._current_conv = self._conv_service.create()
        self._sidebar.add_conversation(self._current_conv)
        self._chat_area.clear_messages()
        self._seed_welcome_messages()

    def _on_conversation_selected(self, conv_id: str) -> None:
        conv = self._conv_service.load(conv_id)
        self._current_conv = conv
        self._chat_area.clear_messages()
        for msg in conv.messages:
            self._chat_area.add_message(msg.text, role=msg.role)

    def _on_conversation_deleted(self, conv_id: str) -> None:
        self._conv_service.delete(conv_id)
        self._sidebar.remove_conversation(conv_id)
        if self._current_conv and self._current_conv.id == conv_id:
            remaining = self._conv_service.list()
            if remaining:
                self._on_conversation_selected(remaining[0].id)
            else:
                self._on_new_chat()

    def _on_conversation_renamed(self, conv_id: str) -> None:
        current_title = ""
        if self._current_conv and self._current_conv.id == conv_id:
            current_title = self._current_conv.title
        else:
            try:
                current_title = self._conv_service.load(conv_id).title
            except Exception as exc:
                print(f"Could not load conversation title for rename: {exc}", file=sys.stderr)
        title, ok = QInputDialog.getText(
            self, "Renomear conversa", "Novo nome:", text=current_title
        )
        if ok and title.strip():
            self._conv_service.rename(conv_id, title.strip())
            self._sidebar.update_conversation_title(conv_id, title.strip())
            if self._current_conv and self._current_conv.id == conv_id:
                self._current_conv.title = title.strip()

    def _on_message_sent(self, text: str) -> None:
        self._process_message(text, voice_initiated=False)

    def _on_transcription_ready(self, text: str) -> None:
        if not text:
            return
        self._input_bar.set_transcribed_text("")
        self._process_message(text, voice_initiated=True)

    def _process_message(self, text: str, voice_initiated: bool = False) -> None:
        """Display the user message and dispatch it to the appropriate AI provider."""
        self._chat_area.add_message(text, role="user")
        self._save_message("user", text)

        # Handle memory trigger commands locally — do not forward to AI
        memory_content = self._memory_service.extract_from_message(text)
        if memory_content:
            self._memory_service.add(memory_content)
            confirmation = f"Memorizado: {memory_content}"
            self._chat_area.add_message(confirmation, role="assistant")
            self._save_message("assistant", confirmation)
            if voice_initiated:
                self._speak(confirmation)
            return

        # Handle /compare — run all providers in parallel and show all responses
        if text.lower().startswith("/compare "):
            query = text[9:].strip()
            if query:
                self._run_compare(query)
            return

        # Handle /run <name> automation trigger
        effective_text = text
        if text.lower().startswith("/run "):
            automation_name = text[5:].strip()
            automation = self._automation_service.get(automation_name)
            if automation is None:
                msg = f"Automação não encontrada: '{automation_name}'."
                self._chat_area.add_message(msg, role="assistant")
                self._save_message("assistant", msg)
                return
            effective_text = automation.prompt

        # Prepend stored memories to give the AI context about the user
        context = self._memory_service.build_context()
        prompt = f"{context}{effective_text}" if context else effective_text

        decision = self._router.route(effective_text)
        provider = get_provider(decision.provider)
        bubble = self._chat_area.start_message(role="assistant")
        buffer: list[str] = []

        self._worker = StreamWorker(provider, prompt)
        self._worker.chunk_received.connect(
            lambda chunk, b=bubble, buf=buffer: self._apply_chunk(b, buf, chunk)
        )
        self._worker.finished.connect(
            lambda buf=buffer, vi=voice_initiated: self._on_stream_finished(buf, vi)
        )
        self._worker.finished.connect(self._worker.deleteLater)
        self._worker.start()

    def _on_stream_finished(self, buffer: list[str], voice_initiated: bool) -> None:
        """Persist the completed assistant response and speak it if voice-initiated."""
        text = "".join(buffer)
        self._save_message("assistant", text)
        if voice_initiated and text:
            self._speak(text)

    # -- parallel / compare handlers ------------------------------------------- #

    def _run_compare(self, query: str) -> None:
        """Run all three providers simultaneously and display each response in chat."""
        self._parallel_worker = ParallelWorker(query)
        self._parallel_worker.result_received.connect(self._on_parallel_result)
        self._parallel_worker.finished.connect(self._parallel_worker.deleteLater)
        self._parallel_worker.start()

    def _on_parallel_result(self, provider_name: str, response: str) -> None:
        """Display a single provider result as a labelled assistant bubble."""
        labeled = f"[{provider_name}]\n\n{response}"
        self._chat_area.add_message(labeled, role="assistant")
        self._save_message("assistant", labeled)

    # -- voice handlers -------------------------------------------------------- #

    def _on_mic_clicked(self) -> None:
        """Toggle recording on/off when the microphone button is pressed."""
        if self._is_recording:
            self._stop_recording()
        else:
            self._start_recording()

    def _start_recording(self) -> None:
        """Begin microphone capture."""
        self._is_recording = True
        self._input_bar.set_recording(True)
        self._record_worker = RecordWorker()
        self._record_worker.recording_stopped.connect(self._on_recording_stopped)
        self._record_worker.finished.connect(self._record_worker.deleteLater)
        self._record_worker.start()

    def _stop_recording(self) -> None:
        """Stop microphone capture and trigger transcription."""
        self._is_recording = False
        self._input_bar.set_recording(False)
        if self._record_worker is not None:
            self._record_worker.stop_recording()

    def _on_recording_stopped(self, audio_path: str) -> None:
        """Transcribe the captured audio file in the background."""
        self._transcribe_worker = TranscribeWorker(self._voice_service, audio_path)
        self._transcribe_worker.transcription_ready.connect(self._on_transcription_ready)
        self._transcribe_worker.finished.connect(self._transcribe_worker.deleteLater)
        self._transcribe_worker.start()

    def _speak(self, text: str) -> None:
        """Speak the given text using TTS in a background thread."""
        self._tts_worker = TtsWorker(self._voice_service, text)
        self._tts_worker.finished.connect(self._tts_worker.deleteLater)
        self._tts_worker.start()

    def _save_message(self, role: str, text: str) -> None:
        if self._current_conv is None:
            return
        self._current_conv.messages.append(Message(role=role, text=text))
        self._current_conv.updated_at = datetime.now(timezone.utc).isoformat()
        if role == "user" and len(self._current_conv.messages) == 1:
            title = text[:40].strip()
            self._current_conv.title = title
            self._sidebar.update_conversation_title(self._current_conv.id, title)
        self._conv_service.save(self._current_conv)

    def _apply_chunk(self, bubble: MessageBubble, buffer: list[str], chunk: str) -> None:
        buffer.append(chunk)
        bubble.set_text("".join(buffer))
        self._chat_area.scroll_to_bottom()

    def _toggle_sidebar(self) -> None:
        self._sidebar.set_collapsed(not self._sidebar.is_collapsed())

    def resizeEvent(self, event: QResizeEvent) -> None:  # noqa: N802 (Qt override)
        super().resizeEvent(event)
        should_collapse = self.width() < COLLAPSE_BREAKPOINT
        if should_collapse != self._sidebar.is_collapsed():
            self._sidebar.set_collapsed(should_collapse)
