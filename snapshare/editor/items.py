"""Custom QGraphicsItem subclasses for each annotation tool."""
from __future__ import annotations

import math

from PyQt6.QtCore import QLineF, QPointF, QRectF, Qt
from PyQt6.QtGui import (
    QBrush,
    QColor,
    QFont,
    QImage,
    QPainter,
    QPainterPath,
    QPen,
    QPixmap,
    QPolygonF,
)
from PyQt6.QtWidgets import (
    QGraphicsEllipseItem,
    QGraphicsItem,
    QGraphicsLineItem,
    QGraphicsPathItem,
    QGraphicsPixmapItem,
    QGraphicsRectItem,
    QGraphicsTextItem,
)

MOVABLE_FLAGS = (
    QGraphicsItem.GraphicsItemFlag.ItemIsMovable
    | QGraphicsItem.GraphicsItemFlag.ItemIsSelectable
    | QGraphicsItem.GraphicsItemFlag.ItemSendsGeometryChanges
)


class ArrowItem(QGraphicsLineItem):
    """A straight line with a filled triangular arrowhead at the end point."""

    def __init__(self, line: QLineF, color: QColor, width: int) -> None:
        super().__init__(line)
        self.setPen(QPen(color, width, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap))
        self.setFlags(MOVABLE_FLAGS)
        self._color = color

    def boundingRect(self) -> QRectF:
        extra = self.pen().width() * 4 + 4
        return super().boundingRect().adjusted(-extra, -extra, extra, extra)

    def paint(self, painter: QPainter, option, widget=None) -> None:  # noqa: D401
        painter.setPen(self.pen())
        painter.setBrush(QBrush(self._color))
        line = self.line()
        painter.drawLine(line)

        arrow_size = max(10.0, self.pen().widthF() * 4)
        angle = math.atan2(-line.dy(), line.dx())
        p1 = line.p2()
        p2 = p1 - QPointF(
            math.cos(angle - math.pi / 7) * arrow_size,
            -math.sin(angle - math.pi / 7) * arrow_size,
        )
        p3 = p1 - QPointF(
            math.cos(angle + math.pi / 7) * arrow_size,
            -math.sin(angle + math.pi / 7) * arrow_size,
        )
        painter.drawPolygon(QPolygonF([p1, p2, p3]))


class HighlightItem(QGraphicsRectItem):
    """Translucent marker-style highlight, multiply-blended over the image."""

    def __init__(self, rect: QRectF, color: QColor) -> None:
        super().__init__(rect)
        self.setPen(QPen(Qt.PenStyle.NoPen))
        color = QColor(color)
        color.setAlpha(110)
        self.setBrush(QBrush(color))
        self.setFlags(MOVABLE_FLAGS)

    def paint(self, painter: QPainter, option, widget=None) -> None:
        painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_Multiply)
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(self.brush())
        painter.drawRect(self.rect())


class StepNumberItem(QGraphicsEllipseItem):
    """A filled numbered circle, ShareX-style step counter."""

    def __init__(self, center: QPointF, number: int, color: QColor, diameter: int = 28) -> None:
        r = diameter / 2
        super().__init__(-r, -r, diameter, diameter)
        self.setPos(center)
        self.setBrush(QBrush(color))
        self.setPen(QPen(QColor("white"), 2))
        self.setFlags(MOVABLE_FLAGS)
        self._number = number
        self._diameter = diameter

    def paint(self, painter: QPainter, option, widget=None) -> None:
        super().paint(painter, option, widget)
        painter.setPen(QPen(QColor("white")))
        font = QFont()
        font.setBold(True)
        font.setPointSizeF(self._diameter * 0.42)
        painter.setFont(font)
        painter.drawText(self.rect(), Qt.AlignmentFlag.AlignCenter, str(self._number))


class FreehandItem(QGraphicsPathItem):
    """Freehand pen stroke built up while dragging."""

    def __init__(self, start: QPointF, color: QColor, width: int) -> None:
        path = QPainterPath(start)
        super().__init__(path)
        self.setPen(QPen(color, width, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap, Qt.PenJoinStyle.RoundJoin))
        self.setFlags(MOVABLE_FLAGS)

    def add_point(self, point: QPointF) -> None:
        path = self.path()
        path.lineTo(point)
        self.setPath(path)


class TextAnnotationItem(QGraphicsTextItem):
    """Editable text label."""

    def __init__(self, text: str, color: QColor, point_size: int = 18) -> None:
        super().__init__(text)
        font = QFont()
        font.setPointSize(point_size)
        font.setBold(True)
        self.setFont(font)
        self.setDefaultTextColor(color)
        self.setFlags(
            MOVABLE_FLAGS
            | QGraphicsItem.GraphicsItemFlag.ItemIsFocusable
        )
        self.setTextInteractionFlags(Qt.TextInteractionFlag.TextEditorInteraction)


def pixelate_pixmap(pixmap: QPixmap, block_size: int = 12) -> QPixmap:
    """Return a mosaic/pixelated copy of a pixmap."""
    small = pixmap.scaled(
        max(1, pixmap.width() // block_size),
        max(1, pixmap.height() // block_size),
        Qt.AspectRatioMode.IgnoreAspectRatio,
        Qt.TransformationMode.FastTransformation,
    )
    return small.scaled(
        pixmap.width(),
        pixmap.height(),
        Qt.AspectRatioMode.IgnoreAspectRatio,
        Qt.TransformationMode.FastTransformation,
    )


def blur_pixmap(pixmap: QPixmap, radius: int = 8) -> QPixmap:
    """Cheap box-blur approximation via down/up-scaling (no extra deps)."""
    image: QImage = pixmap.toImage()
    factor = max(2, radius // 2)
    small = image.scaled(
        max(1, image.width() // factor),
        max(1, image.height() // factor),
        Qt.AspectRatioMode.IgnoreAspectRatio,
        Qt.TransformationMode.SmoothTransformation,
    )
    blurred = small.scaled(
        image.width(),
        image.height(),
        Qt.AspectRatioMode.IgnoreAspectRatio,
        Qt.TransformationMode.SmoothTransformation,
    )
    return QPixmap.fromImage(blurred)


class RegionEffectItem(QGraphicsPixmapItem):
    """Overlay pixmap used for pixelate/blur tools: a processed copy of the
    base image cropped to the selected region, stacked on top of it.
    """

    def __init__(self, pixmap: QPixmap, top_left: QPointF) -> None:
        super().__init__(pixmap)
        self.setPos(top_left)
        self.setFlags(MOVABLE_FLAGS)


class RectAnnotationItem(QGraphicsRectItem):
    def __init__(self, rect: QRectF, color: QColor, width: int, fill: bool = False) -> None:
        super().__init__(rect)
        self.setPen(QPen(color, width))
        self.setBrush(QBrush(color) if fill else QBrush(Qt.BrushStyle.NoBrush))
        self.setFlags(MOVABLE_FLAGS)


class EllipseAnnotationItem(QGraphicsEllipseItem):
    def __init__(self, rect: QRectF, color: QColor, width: int, fill: bool = False) -> None:
        super().__init__(rect)
        self.setPen(QPen(color, width))
        self.setBrush(QBrush(color) if fill else QBrush(Qt.BrushStyle.NoBrush))
        self.setFlags(MOVABLE_FLAGS)


class LineAnnotationItem(QGraphicsLineItem):
    def __init__(self, line: QLineF, color: QColor, width: int) -> None:
        super().__init__(line)
        self.setPen(QPen(color, width, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap))
        self.setFlags(MOVABLE_FLAGS)
