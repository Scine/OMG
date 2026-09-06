"""The annotation canvas: a QGraphicsScene/View pair that turns mouse
gestures into annotation items, based on the currently selected tool.
"""
from __future__ import annotations

from enum import Enum, auto

from PyQt6.QtCore import QLineF, QPointF, QRectF, Qt, pyqtSignal
from PyQt6.QtGui import QColor, QPainter, QPen, QPixmap
from PyQt6.QtWidgets import (
    QGraphicsPixmapItem,
    QGraphicsRectItem,
    QGraphicsScene,
    QGraphicsView,
)

from snapshare.editor.items import (
    ArrowItem,
    EllipseAnnotationItem,
    FreehandItem,
    HighlightItem,
    LineAnnotationItem,
    RectAnnotationItem,
    RegionEffectItem,
    StepNumberItem,
    TextAnnotationItem,
    blur_pixmap,
    pixelate_pixmap,
)


class Tool(Enum):
    SELECT = auto()
    PEN = auto()
    LINE = auto()
    ARROW = auto()
    RECT = auto()
    ELLIPSE = auto()
    HIGHLIGHT = auto()
    TEXT = auto()
    STEP = auto()
    PIXELATE = auto()
    BLUR = auto()
    CROP = auto()


class EditorScene(QGraphicsScene):
    def __init__(self, pixmap: QPixmap) -> None:
        super().__init__()
        self.base_pixmap = pixmap
        self.setSceneRect(QRectF(pixmap.rect()))
        self.base_item = QGraphicsPixmapItem(pixmap)
        self.base_item.setZValue(-1000)
        self.addItem(self.base_item)


class EditorView(QGraphicsView):
    text_item_created = pyqtSignal(object)
    crop_rect_changed = pyqtSignal(object)

    def __init__(self, scene: EditorScene) -> None:
        super().__init__(scene)
        self.editor_scene = scene
        self.setRenderHints(
            QPainter.RenderHint.Antialiasing | QPainter.RenderHint.SmoothPixmapTransform
        )
        self.setDragMode(QGraphicsView.DragMode.NoDrag)
        self.setMouseTracking(True)

        self.tool = Tool.SELECT
        self.color = QColor("#ff3b30")
        self.stroke_width = 4
        self.fill_shapes = False

        self._drawing_item = None
        self._start_pos: QPointF | None = None
        self._temp_rect_item: QGraphicsRectItem | None = None

        self._undo_stack: list[object] = []
        self._redo_stack: list[object] = []
        self._step_counter = 1

        self.crop_rect: QRectF | None = None
        self._crop_visual: QGraphicsRectItem | None = None

    # -- tool config -----------------------------------------------------
    def set_tool(self, tool: Tool) -> None:
        self.tool = tool
        self.setCursor(Qt.CursorShape.CrossCursor if tool != Tool.SELECT else Qt.CursorShape.ArrowCursor)

    def set_color(self, color: QColor) -> None:
        self.color = color

    def set_stroke_width(self, width: int) -> None:
        self.stroke_width = width

    def set_fill_shapes(self, fill: bool) -> None:
        self.fill_shapes = fill

    # -- undo/redo ---------------------------------------------------------
    def _register(self, item) -> None:
        self._undo_stack.append(item)
        self._redo_stack.clear()

    def undo(self) -> None:
        if not self._undo_stack:
            return
        item = self._undo_stack.pop()
        self.editor_scene.removeItem(item)
        self._redo_stack.append(item)

    def redo(self) -> None:
        if not self._redo_stack:
            return
        item = self._redo_stack.pop()
        self.editor_scene.addItem(item)
        self._undo_stack.append(item)

    # -- mouse handling ------------------------------------------------
    def mousePressEvent(self, event) -> None:
        if self.tool == Tool.SELECT:
            super().mousePressEvent(event)
            return

        pos = self.mapToScene(event.pos())
        self._start_pos = pos

        if self.tool == Tool.TEXT:
            item = TextAnnotationItem("Text", self.color, point_size=8 + self.stroke_width * 3)
            item.setPos(pos)
            self.editor_scene.addItem(item)
            self._register(item)
            self.text_item_created.emit(item)
            return

        if self.tool == Tool.STEP:
            item = StepNumberItem(pos, self._step_counter, self.color, diameter=18 + self.stroke_width * 3)
            self._step_counter += 1
            self.editor_scene.addItem(item)
            self._register(item)
            return

        if self.tool == Tool.PEN:
            self._drawing_item = FreehandItem(pos, self.color, self.stroke_width)
            self.editor_scene.addItem(self._drawing_item)
            return

        if self.tool in (Tool.LINE, Tool.ARROW, Tool.RECT, Tool.ELLIPSE, Tool.HIGHLIGHT, Tool.PIXELATE, Tool.BLUR, Tool.CROP):
            pen = QPen(self.color, 1, Qt.PenStyle.DashLine)
            self._temp_rect_item = QGraphicsRectItem(QRectF(pos, pos))
            self._temp_rect_item.setPen(pen)
            self.editor_scene.addItem(self._temp_rect_item)
            return

    def mouseMoveEvent(self, event) -> None:
        if self.tool == Tool.SELECT:
            super().mouseMoveEvent(event)
            return

        pos = self.mapToScene(event.pos())

        if self.tool == Tool.PEN and self._drawing_item is not None:
            self._drawing_item.add_point(pos)
            return

        if self._temp_rect_item is not None and self._start_pos is not None:
            rect = QRectF(self._start_pos, pos).normalized()
            self._temp_rect_item.setRect(rect)

    def mouseReleaseEvent(self, event) -> None:
        if self.tool == Tool.SELECT:
            super().mouseReleaseEvent(event)
            return

        pos = self.mapToScene(event.pos())

        if self.tool == Tool.PEN:
            if self._drawing_item is not None:
                self._register(self._drawing_item)
            self._drawing_item = None
            self._start_pos = None
            return

        if self._start_pos is None:
            return

        rect = QRectF(self._start_pos, pos).normalized()
        if self._temp_rect_item is not None:
            self.editor_scene.removeItem(self._temp_rect_item)
            self._temp_rect_item = None

        if rect.width() < 2 and rect.height() < 2 and self.tool not in (Tool.LINE, Tool.ARROW):
            self._start_pos = None
            return

        line = QLineF(self._start_pos, pos)

        item = None
        if self.tool == Tool.LINE:
            item = LineAnnotationItem(line, self.color, self.stroke_width)
        elif self.tool == Tool.ARROW:
            item = ArrowItem(line, self.color, self.stroke_width)
        elif self.tool == Tool.RECT:
            item = RectAnnotationItem(rect, self.color, self.stroke_width, self.fill_shapes)
        elif self.tool == Tool.ELLIPSE:
            item = EllipseAnnotationItem(rect, self.color, self.stroke_width, self.fill_shapes)
        elif self.tool == Tool.HIGHLIGHT:
            item = HighlightItem(rect, self.color)
        elif self.tool in (Tool.PIXELATE, Tool.BLUR):
            clipped = rect.intersected(self.editor_scene.sceneRect())
            if clipped.width() >= 2 and clipped.height() >= 2:
                region = self.editor_scene.base_pixmap.copy(clipped.toRect())
                processed = pixelate_pixmap(region) if self.tool == Tool.PIXELATE else blur_pixmap(region)
                item = RegionEffectItem(processed, clipped.topLeft())
        elif self.tool == Tool.CROP:
            self.crop_rect = rect.intersected(self.editor_scene.sceneRect())
            if self._crop_visual is not None:
                self.editor_scene.removeItem(self._crop_visual)
            pen = QPen(QColor("#00c2ff"), 2, Qt.PenStyle.DashLine)
            self._crop_visual = QGraphicsRectItem(self.crop_rect)
            self._crop_visual.setPen(pen)
            self._crop_visual.setZValue(1000)
            self.editor_scene.addItem(self._crop_visual)
            self.crop_rect_changed.emit(self.crop_rect)

        if item is not None:
            self.editor_scene.addItem(item)
            self._register(item)

        self._start_pos = None

    def clear_crop(self) -> None:
        self.crop_rect = None
        if self._crop_visual is not None:
            self.editor_scene.removeItem(self._crop_visual)
            self._crop_visual = None
        self.crop_rect_changed.emit(None)

    def render_final_pixmap(self) -> QPixmap:
        """Flatten the scene (annotations burned in) to a single QPixmap,
        honoring the pending crop rectangle if one was set.
        """
        if self._crop_visual is not None:
            self._crop_visual.setVisible(False)

        target_rect = self.crop_rect if self.crop_rect else self.editor_scene.sceneRect()
        image_size = target_rect.size().toSize()
        pixmap = QPixmap(image_size)
        pixmap.fill(Qt.GlobalColor.transparent)

        painter = QPainter(pixmap)
        painter.setRenderHints(
            QPainter.RenderHint.Antialiasing | QPainter.RenderHint.SmoothPixmapTransform
        )
        self.editor_scene.render(painter, target=QRectF(pixmap.rect()), source=target_rect)
        painter.end()

        if self._crop_visual is not None:
            self._crop_visual.setVisible(True)

        return pixmap
