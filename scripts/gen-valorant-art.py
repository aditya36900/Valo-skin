#!/usr/bin/env python3
"""Generates the original Valorant-style art bundled with Valo-skin.

Outputs assets/wallpaper.webp (default wallpaper) and assets/logo.svg (crosshair
emblem). Everything here is drawn from scratch: no Riot Games assets are used.

Requires PySide6. Usage: QT_QPA_PLATFORM=offscreen python3 scripts/gen-valorant-art.py
"""

import math
import random
import sys
from pathlib import Path

from PySide6.QtCore import QPointF, QRectF, Qt
from PySide6.QtGui import (QBrush, QColor, QGuiApplication, QImage, QLinearGradient, QPainter, QPainterPath, QPen,
                           QPolygonF, QRadialGradient)

ROOT = Path(__file__).resolve().parent.parent

NAVY = QColor("#0f1923")
DEEP = QColor("#0a0e12")
RED = QColor("#ff4655")
WHITE = QColor("#ece8e1")

# Emblem geometry in a 128 x 90.38 design box (matches components/Logo.qml)
EMBLEM_TICKS = [(34, 43, 18, 4.4), (76, 43, 18, 4.4), (61.8, 15, 4.4, 18), (61.8, 57.4, 4.4, 18), (61.8, 43, 4.4, 4.4)]
EMBLEM_BRACKET = [(22, 8), (8, 22), (8, 68.4), (22, 82.4), (30, 82.4), (30, 76.4), (24.5, 76.4), (14, 65.9), (14, 24.5),
                  (24.5, 14), (30, 14), (30, 8)]


def mirrored(points):
    return [(128 - x, y) for x, y in points]


def poly(points, ox=0.0, oy=0.0, s=1.0):
    return QPolygonF([QPointF(ox + x * s, oy + y * s) for x, y in points])


def draw_emblem(p: QPainter, ox: float, oy: float, s: float, top: QColor, bottom: QColor):
    p.setPen(Qt.NoPen)
    p.setBrush(bottom)
    p.drawPolygon(poly(EMBLEM_BRACKET, ox, oy, s))
    p.drawPolygon(poly(mirrored(EMBLEM_BRACKET), ox, oy, s))
    p.setBrush(top)
    for x, y, w, h in EMBLEM_TICKS:
        p.drawRect(QRectF(ox + x * s, oy + y * s, w * s, h * s))


def wallpaper(w=3840, h=2160):
    img = QImage(w, h, QImage.Format_RGB32)
    p = QPainter(img)
    p.setRenderHint(QPainter.Antialiasing)

    # Base: deep navy with a soft light pool upper-left
    g = QLinearGradient(0, 0, w, h)
    g.setColorAt(0, QColor("#13202c"))
    g.setColorAt(0.6, NAVY)
    g.setColorAt(1, DEEP)
    p.fillRect(img.rect(), g)

    rg = QRadialGradient(QPointF(w * 0.28, h * 0.32), w * 0.55)
    rg.setColorAt(0, QColor(236, 232, 225, 22))
    rg.setColorAt(1, QColor(236, 232, 225, 0))
    p.fillRect(img.rect(), rg)

    # Tactical grid
    p.setPen(QPen(QColor(236, 232, 225, 10), 1))
    step = 96
    for x in range(0, w, step):
        p.drawLine(x, 0, x, h)
    for y in range(0, h, step):
        p.drawLine(0, y, w, y)

    # Big red shards sweeping from the bottom-right
    random.seed(7)
    angle = math.radians(-24)
    dx, dy = math.cos(angle), math.sin(angle)
    nx, ny = -dy, dx

    def shard(cx, cy, length, thick, colour):
        hl, ht = length / 2, thick / 2
        slant = thick * 0.9
        pts = [(-hl + slant, -ht), (hl, -ht), (hl - slant, ht), (-hl, ht)]
        p.setBrush(colour)
        p.drawPolygon(QPolygonF([QPointF(cx + x * dx + y * nx, cy + x * dy + y * ny) for x, y in pts]))

    p.setPen(Qt.NoPen)
    shard(w * 0.80, h * 0.78, w * 0.75, h * 0.16, RED)
    shard(w * 0.92, h * 0.58, w * 0.42, h * 0.035, QColor(255, 70, 85, 210))
    shard(w * 0.60, h * 0.97, w * 0.5, h * 0.05, QColor(255, 70, 85, 150))
    shard(w * 0.70, h * 0.66, w * 0.3, h * 0.012, WHITE)
    for _ in range(26):
        t = random.random()
        cx = w * (0.45 + 0.55 * t) + random.uniform(-80, 80)
        cy = h * (0.95 - 0.5 * t) + random.uniform(-120, 120)
        a = random.randint(40, 200)
        shard(cx, cy, random.uniform(40, 260), random.uniform(4, 18), QColor(255, 70, 85, a))

    # Darken the red block's lower edge for depth
    edge = QLinearGradient(0, h * 0.7, 0, h)
    edge.setColorAt(0, QColor(10, 14, 18, 0))
    edge.setColorAt(1, QColor(10, 14, 18, 140))
    p.fillRect(img.rect(), edge)

    # Thin HUD lines and corner brackets
    pen = QPen(QColor(236, 232, 225, 70), 3)
    p.setPen(pen)
    m, L = 80, 140
    for (x, y, sx, sy) in [(m, m, 1, 1), (w - m, m, -1, 1), (m, h - m, 1, -1), (w - m, h - m, -1, -1)]:
        p.drawLine(x, y, x + L * sx, y)
        p.drawLine(x, y, x, y + L * sy)
    p.setPen(QPen(QColor(236, 232, 225, 40), 2))
    p.drawLine(int(w * 0.08), int(h * 0.5), int(w * 0.32), int(h * 0.5))
    p.setPen(QPen(RED, 6))
    p.drawLine(int(w * 0.08), int(h * 0.5), int(w * 0.11), int(h * 0.5))

    # Emblem, upper-left third
    draw_emblem(p, w * 0.1, h * 0.36, 2.2, RED, QColor(236, 232, 225, 200))

    # Subtle scanlines
    p.setPen(QPen(QColor(0, 0, 0, 18), 1))
    for y in range(0, h, 4):
        p.drawLine(0, y, w, y)

    p.end()
    return img


def logo_svg():
    def pts(points):
        return " ".join(f"{x:g},{y:g}" for x, y in points)

    rects = "\n".join(f'  <rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" fill="#ff4655"/>'
                      for x, y, w, h in EMBLEM_TICKS)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -18.81 128 128" width="128" height="128">
  <polygon points="{pts(EMBLEM_BRACKET)}" fill="#ece8e1"/>
  <polygon points="{pts(mirrored(EMBLEM_BRACKET))}" fill="#ece8e1"/>
{rects}
</svg>
"""


def main():
    app = QGuiApplication(sys.argv)  # noqa: F841 - needed for font/paint backends
    img = wallpaper()
    out = ROOT / "assets" / "wallpaper.webp"
    if not img.save(str(out), "WEBP", 90):
        out = out.with_suffix(".png")
        img.save(str(out))
    print("wrote", out)
    (ROOT / "assets" / "logo.svg").write_text(logo_svg())
    print("wrote", ROOT / "assets" / "logo.svg")


if __name__ == "__main__":
    main()
