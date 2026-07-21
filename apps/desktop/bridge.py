"""
ZyzzBridge — Python-to-QML bridge.

Exposes all business logic to the QML UI via properties, signals and slots.
This is the single point of contact between core/ and the visual layer.
"""

from __future__ import annotations

import sys
import threading
from datetime import datetime, timezone
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

from PySide6.QtCore import (
    QAbstractListModel,
    QModelIndex,
    QObject,
    QTimer,
    Property,
    Signal,
    Slot,
    Qt,
)

from core.shared.metrics import take_snapshot
from core.tools.builtin import set_finance_callback

from core.automations.service import AutomationService
from core.history.models import Conversation, Message
from core.history.service import ConversationService
from core.memory.service import MemoryService
from core.providers.providers import get_provider
from core.router.service import RouterService
from core.voice.service import VoiceService

from apps.desktop.workers import (
    ParallelWorker,
    RecordWorker,
    StreamWorker,
    TranscribeWorker,
    TtsWorker,
)


# --------------------------------------------------------------------------- #
# QML List Models
# --------------------------------------------------------------------------- #


class ConversationListModel(QAbstractListModel):
    """Exposes the conversation list to QML ListView."""

    TitleRole = Qt.ItemDataRole.UserRole + 1
    IdRole = Qt.ItemDataRole.UserRole + 2

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._items: list[Conversation] = []

    def roleNames(self) -> dict[int, bytes]:
        return {self.TitleRole: b"title", self.IdRole: b"convId"}

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return len(self._items)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> str | None:
        if not index.isValid():
            return None
        item = self._items[index.row()]
        if role == self.TitleRole:
            return item.title
        if role == self.IdRole:
            return item.id
        return None

    def load(self, conversations: list[Conversation]) -> None:
        """Replace the entire list."""
        self.beginResetModel()
        self._items = list(conversations)
        self.endResetModel()

    def prepend(self, conv: Conversation) -> None:
        """Add a conversation to the top of the list."""
        self.beginInsertRows(QModelIndex(), 0, 0)
        self._items.insert(0, conv)
        self.endInsertRows()

    def remove_by_id(self, conv_id: str) -> None:
        """Remove a conversation by its ID."""
        for i, item in enumerate(self._items):
            if item.id == conv_id:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._items.pop(i)
                self.endRemoveRows()
                return

    def update_title(self, conv_id: str, title: str) -> None:
        """Update the title of a conversation in the list."""
        for i, item in enumerate(self._items):
            if item.id == conv_id:
                item.title = title
                idx = self.index(i, 0)
                self.dataChanged.emit(idx, idx, [self.TitleRole])
                return


class PipelineModel(QAbstractListModel):
    """Exposes active pipeline nodes to QML."""

    NameRole = Qt.ItemDataRole.UserRole + 1
    ActiveRole = Qt.ItemDataRole.UserRole + 2

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._nodes: list[dict[str, object]] = []

    def roleNames(self) -> dict[int, bytes]:
        return {self.NameRole: b"name", self.ActiveRole: b"active"}

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return len(self._nodes)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> object:
        if not index.isValid():
            return None
        node = self._nodes[index.row()]
        if role == self.NameRole:
            return node["name"]
        if role == self.ActiveRole:
            return node["active"]
        return None

    def set_nodes(self, nodes: list[dict[str, object]]) -> None:
        """Replace all pipeline nodes."""
        self.beginResetModel()
        self._nodes = nodes
        self.endResetModel()

    def clear(self) -> None:
        """Remove all nodes."""
        self.beginResetModel()
        self._nodes = []
        self.endResetModel()


# --------------------------------------------------------------------------- #
# Bridge
# --------------------------------------------------------------------------- #


class ZyzzBridge(QObject):
    """Single bridge between Python business logic and the QML visual layer."""

    # Notifiers for QML property bindings
    stateChanged = Signal()
    responseTextChanged = Signal()
    recordingChanged = Signal()
    pipelineVisibleChanged = Signal()
    metricsChanged = Signal()
    activeModelChanged = Signal()
    totalTokensChanged = Signal()
    messageCountChanged = Signal()
    financeInject = Signal(str, arguments=["js"])

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)

        # Core services
        self._router = RouterService()
        self._conv_service = ConversationService()
        self._memory_service = MemoryService()
        self._automation_service = AutomationService()
        self._voice_service = VoiceService()

        # QML models
        self._conversation_model = ConversationListModel(self)
        self._pipeline_model = PipelineModel(self)

        # State
        self._current_conv: Conversation | None = None
        self._state = "idle"
        self._response_text = ""
        self._is_recording = False
        self._pipeline_visible = False
        self._voice_initiated = False
        self._buffer: list[str] = []

        # Telemetry state
        self._cpu_percent = 0.0
        self._mem_used = 0.0
        self._mem_total = 0.0
        self._mem_percent = 0.0
        self._disk_used = 0.0
        self._disk_total = 0.0
        self._disk_percent = 0.0
        self._active_model = "GEMINI-2.0-FLASH"
        self._total_tokens = 0
        self._message_count = 0

        # Workers
        self._worker: StreamWorker | None = None
        self._parallel_worker: ParallelWorker | None = None
        self._record_worker: RecordWorker | None = None
        self._transcribe_worker: TranscribeWorker | None = None
        self._tts_worker: TtsWorker | None = None

        self._init_conversations()
        self._update_counts()

        # Local HTTP server for web modules (finance, etc.)
        self._web_port = self._start_web_server()

        # Finance tool integration
        self._finance_result: str = ""
        set_finance_callback(self._finance_add_transaction)

        # Periodic system metrics (every 2 seconds)
        self._metrics_timer = QTimer(self)
        self._metrics_timer.timeout.connect(self._refresh_metrics)
        self._metrics_timer.start(2000)
        self._refresh_metrics()

    # -- QML Properties ------------------------------------------------------ #

    @Property(str, notify=stateChanged)  # type: ignore[arg-type]
    def state(self) -> str:
        """Current AI state: idle, listening, thinking, speaking, error."""
        return self._state

    @Property(str, notify=responseTextChanged)  # type: ignore[arg-type]
    def responseText(self) -> str:
        """Current response text being streamed or completed."""
        return self._response_text

    @Property(bool, notify=recordingChanged)  # type: ignore[arg-type]
    def recording(self) -> bool:
        """Whether the microphone is currently recording."""
        return self._is_recording

    @Property(bool, notify=pipelineVisibleChanged)  # type: ignore[arg-type]
    def pipelineVisible(self) -> bool:
        """Whether the processing pipeline should be displayed."""
        return self._pipeline_visible

    @Property(QObject, constant=True)  # type: ignore[arg-type]
    def conversations(self) -> ConversationListModel:
        """Conversation list model for QML binding."""
        return self._conversation_model

    @Property(QObject, constant=True)  # type: ignore[arg-type]
    def pipeline(self) -> PipelineModel:
        """Pipeline node model for QML binding."""
        return self._pipeline_model

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def cpuPercent(self) -> float:
        """Current CPU usage percentage."""
        return self._cpu_percent

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def memUsed(self) -> float:
        """RAM used in GB."""
        return self._mem_used

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def memTotal(self) -> float:
        """Total RAM in GB."""
        return self._mem_total

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def memPercent(self) -> float:
        """RAM usage percentage."""
        return self._mem_percent

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def diskUsed(self) -> float:
        """Disk used in GB."""
        return self._disk_used

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def diskTotal(self) -> float:
        """Total disk in GB."""
        return self._disk_total

    @Property(float, notify=metricsChanged)  # type: ignore[arg-type]
    def diskPercent(self) -> float:
        """Disk usage percentage."""
        return self._disk_percent

    @Property(str, notify=activeModelChanged)  # type: ignore[arg-type]
    def activeModel(self) -> str:
        """Name of the currently active AI model."""
        return self._active_model

    @Property(int, notify=totalTokensChanged)  # type: ignore[arg-type]
    def totalTokens(self) -> int:
        """Approximate total tokens processed this session."""
        return self._total_tokens

    @Property(int, notify=messageCountChanged)  # type: ignore[arg-type]
    def messageCount(self) -> int:
        """Total messages in current conversation."""
        return self._message_count

    @Property(int, constant=True)  # type: ignore[arg-type]
    def memoryFactsCount(self) -> int:
        """Number of stored memory facts."""
        return len(self._memory_service.list())

    @Property(int, constant=True)  # type: ignore[arg-type]
    def automationsCount(self) -> int:
        """Number of saved automations."""
        return len(self._automation_service.list())

    @Property(int, constant=True)  # type: ignore[arg-type]
    def conversationCount(self) -> int:
        """Total number of conversations."""
        return len(self._conv_service.list())

    @Property(str, constant=True)  # type: ignore[arg-type]
    def financeUrl(self) -> str:
        """URL for the finance web module served locally."""
        return f"http://localhost:{self._web_port}/finance.html"

    # -- Finance integration ------------------------------------------------- #

    def _finance_add_transaction(self, desc: str, val: float, cat: str = "Alimentação",
                                 date: str = "", form: str = "pix",
                                 tx_type: str = "Saída") -> str:
        """Inject a transaction into the Finance WebEngineView via JS."""
        import json
        data = json.dumps({
            "desc": desc, "val": val, "cat": cat,
            "date": date, "form": form, "type": tx_type,
        })
        js = f"window.addTransactionFromZyzz && window.addTransactionFromZyzz({data})"
        self.financeInject.emit(js)
        return f"Despesa lançada: {desc} — R${val:.2f} ({cat})"

    # -- Web server ---------------------------------------------------------- #

    def _start_web_server(self) -> int:
        """Start a local HTTP server for web modules and return the port."""
        web_dir = Path(__file__).resolve().parent / "ui" / "web"
        handler = partial(SimpleHTTPRequestHandler, directory=str(web_dir))
        server = HTTPServer(("127.0.0.1", 0), handler)
        port = server.server_address[1]
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        return port

    # -- State helpers ------------------------------------------------------- #

    def _set_state(self, state: str) -> None:
        if self._state != state:
            self._state = state
            self.stateChanged.emit()

    def _set_response(self, text: str) -> None:
        if self._response_text != text:
            self._response_text = text
            self.responseTextChanged.emit()

    def _set_pipeline_visible(self, visible: bool) -> None:
        if self._pipeline_visible != visible:
            self._pipeline_visible = visible
            self.pipelineVisibleChanged.emit()

    # -- Metrics ------------------------------------------------------------- #

    def _refresh_metrics(self) -> None:
        try:
            snap = take_snapshot()
            self._cpu_percent = snap.cpu_percent
            self._mem_used = snap.memory_used_gb
            self._mem_total = snap.memory_total_gb
            self._mem_percent = snap.memory_percent
            self._disk_used = snap.disk_used_gb
            self._disk_total = snap.disk_total_gb
            self._disk_percent = snap.disk_percent
            self.metricsChanged.emit()
        except Exception as exc:
            print(f"Metrics error: {exc}", file=sys.stderr)

    def _update_counts(self) -> None:
        if self._current_conv:
            self._message_count = len(self._current_conv.messages)
        else:
            self._message_count = 0
        self.messageCountChanged.emit()

    # -- Init ---------------------------------------------------------------- #

    def _init_conversations(self) -> None:
        conversations = self._conv_service.list()
        self._conversation_model.load(conversations)
        if conversations:
            self._current_conv = conversations[0]
        else:
            self._current_conv = self._conv_service.create()
            self._conversation_model.prepend(self._current_conv)

    # -- Slots (callable from QML) ------------------------------------------- #

    @Slot(str)
    def sendMessage(self, text: str) -> None:
        """Process a user message from the input bar."""
        text = text.strip()
        if not text:
            return
        self._save_message("user", text)
        self._process_message(text, voice_initiated=False)

    @Slot()
    def toggleRecording(self) -> None:
        """Toggle microphone recording on/off."""
        if self._is_recording:
            self._stop_recording()
        else:
            self._start_recording()

    @Slot()
    def newConversation(self) -> None:
        """Create a fresh conversation."""
        self._current_conv = self._conv_service.create()
        self._conversation_model.prepend(self._current_conv)
        self._set_response("")

    @Slot(str)
    def loadConversation(self, conv_id: str) -> None:
        """Load and display a previous conversation."""
        try:
            conv = self._conv_service.load(conv_id)
            self._current_conv = conv
            last_response = ""
            for msg in reversed(conv.messages):
                if msg.role == "assistant":
                    last_response = msg.text
                    break
            self._set_response(last_response)
        except Exception as exc:
            print(f"Failed to load conversation: {exc}", file=sys.stderr)

    @Slot(str)
    def deleteConversation(self, conv_id: str) -> None:
        """Delete a conversation."""
        self._conv_service.delete(conv_id)
        self._conversation_model.remove_by_id(conv_id)
        if self._current_conv and self._current_conv.id == conv_id:
            remaining = self._conv_service.list()
            if remaining:
                self.loadConversation(remaining[0].id)
            else:
                self.newConversation()

    # -- Message processing -------------------------------------------------- #

    def _process_message(self, text: str, voice_initiated: bool) -> None:
        self._voice_initiated = voice_initiated

        # Memory trigger
        memory_content = self._memory_service.extract_from_message(text)
        if memory_content:
            self._memory_service.add(memory_content)
            confirmation = f"Memorizado: {memory_content}"
            self._save_message("assistant", confirmation)
            self._set_response(confirmation)
            if voice_initiated:
                self._speak(confirmation)
            return

        # /compare
        if text.lower().startswith("/compare "):
            query = text[9:].strip()
            if query:
                self._run_compare(query)
            return

        # /run automation
        effective_text = text
        if text.lower().startswith("/run "):
            automation_name = text[5:].strip()
            automation = self._automation_service.get(automation_name)
            if automation is None:
                msg = f"Automacao nao encontrada: '{automation_name}'."
                self._save_message("assistant", msg)
                self._set_response(msg)
                return
            effective_text = automation.prompt

        # Build context
        context = self._memory_service.build_context()
        effective_prompt = f"{context}{effective_text}" if context else effective_text

        # Build conversation history
        messages: list[dict] = []
        if self._current_conv:
            for msg in self._current_conv.messages[:-1]:
                messages.append({"role": msg.role, "content": msg.text})
        messages.append({"role": "user", "content": effective_prompt})

        # Route
        decision = self._router.route(effective_text)
        provider = get_provider(decision.provider)
        self._active_model = decision.provider.value.upper()
        self.activeModelChanged.emit()

        # Pipeline
        nodes: list[dict[str, object]] = []
        if voice_initiated:
            nodes.append({"name": "VOZ", "active": True})
        if context:
            nodes.append({"name": "MEMORIA", "active": True})
        nodes.append({"name": "ROUTER", "active": True})
        nodes.append({"name": decision.provider.value.upper(), "active": True})
        self._pipeline_model.set_nodes(nodes)
        self._set_pipeline_visible(True)

        # Start streaming
        self._set_state("thinking")
        self._set_response("")
        self._buffer = []

        self._worker = StreamWorker(provider, messages)
        self._worker.chunk_received.connect(self._on_chunk)
        self._worker.error_occurred.connect(self._on_stream_error)
        self._worker.finished.connect(self._on_stream_finished)
        self._worker.finished.connect(self._worker.deleteLater)
        self._worker.start()

    def _on_chunk(self, chunk: str) -> None:
        if self._state == "thinking":
            self._set_state("speaking")
        self._buffer.append(chunk)
        self._set_response("".join(self._buffer))

    def _on_stream_error(self, error: str) -> None:
        self._set_response(f"Erro: {error}")
        self._set_pipeline_visible(False)
        self._pipeline_model.clear()
        self._set_state("error")

    def _on_stream_finished(self) -> None:
        text = "".join(self._buffer)
        self._save_message("assistant", text)
        self._set_pipeline_visible(False)
        self._pipeline_model.clear()

        if self._voice_initiated and text:
            self._speak(text)
        else:
            self._set_state("idle")

    # -- Compare ------------------------------------------------------------- #

    def _run_compare(self, query: str) -> None:
        self._set_state("thinking")
        self._set_response("")
        self._buffer = []

        nodes: list[dict[str, object]] = [
            {"name": "ROUTER", "active": True},
            {"name": "CLAUDE", "active": True},
            {"name": "CHATGPT", "active": True},
            {"name": "GEMINI", "active": True},
        ]
        self._pipeline_model.set_nodes(nodes)
        self._set_pipeline_visible(True)

        self._parallel_worker = ParallelWorker(query)
        self._parallel_worker.result_received.connect(self._on_parallel_result)
        self._parallel_worker.finished.connect(self._on_compare_finished)
        self._parallel_worker.finished.connect(self._parallel_worker.deleteLater)
        self._parallel_worker.start()

    def _on_parallel_result(self, provider_name: str, response: str) -> None:
        labeled = f"[{provider_name}]\n{response}\n\n"
        self._buffer.append(labeled)
        self._set_response("".join(self._buffer))
        self._save_message("assistant", labeled.strip())
        if self._state == "thinking":
            self._set_state("speaking")

    def _on_compare_finished(self) -> None:
        self._set_pipeline_visible(False)
        self._pipeline_model.clear()
        self._set_state("idle")

    # -- Voice --------------------------------------------------------------- #

    def _start_recording(self) -> None:
        self._is_recording = True
        self.recordingChanged.emit()
        self._set_state("listening")

        self._record_worker = RecordWorker()
        self._record_worker.recording_stopped.connect(self._on_recording_stopped)
        self._record_worker.finished.connect(self._record_worker.deleteLater)
        self._record_worker.start()

    def _stop_recording(self) -> None:
        self._is_recording = False
        self.recordingChanged.emit()
        if self._record_worker is not None:
            self._record_worker.stop_recording()

    def _on_recording_stopped(self, audio_path: str) -> None:
        self._transcribe_worker = TranscribeWorker(self._voice_service, audio_path)
        self._transcribe_worker.transcription_ready.connect(self._on_transcription_ready)
        self._transcribe_worker.finished.connect(self._transcribe_worker.deleteLater)
        self._transcribe_worker.start()

    def _on_transcription_ready(self, text: str) -> None:
        if not text:
            self._set_state("idle")
            return
        self._save_message("user", text)
        self._process_message(text, voice_initiated=True)

    def _speak(self, text: str) -> None:
        self._tts_worker = TtsWorker(self._voice_service, text)
        self._tts_worker.finished.connect(lambda: self._set_state("idle"))
        self._tts_worker.finished.connect(self._tts_worker.deleteLater)
        self._tts_worker.start()

    # -- Persistence --------------------------------------------------------- #

    def _save_message(self, role: str, text: str) -> None:
        if self._current_conv is None:
            return
        self._current_conv.messages.append(Message(role=role, text=text))
        self._current_conv.updated_at = datetime.now(timezone.utc).isoformat()
        if role == "user" and len(self._current_conv.messages) == 1:
            title = text[:40].strip()
            self._current_conv.title = title
            self._conversation_model.update_title(self._current_conv.id, title)
        self._conv_service.save(self._current_conv)

        # Update telemetry
        self._total_tokens += len(text.split())
        self.totalTokensChanged.emit()
        self._update_counts()
