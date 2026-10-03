#!/usr/bin/env python3
"""Generates the Valo-skin Plymouth theme images (original art). Requires PySide6.

Usage: QT_QPA_PLATFORM=offscreen python3 scripts/gen-plymouth-art.py [--accent '#ff4655']
"""

import importlib.util
import sys
from pathlib import Path

from PySide6.QtCore import QPointF, QRectF, Qt
from PySide6.QtGui import QColor, QGuiApplication, QImage, QPainter, QPen

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "themes" / "plymouth" / "valo-skin"
spec = importlib.util.spec_from_file_location("art", ROOT / "scripts" / "gen-valorant-art.py")
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)


def canvas(w, h):
    img = QImage(w, h, QImage.Format_ARGB32_Premultiplied)
    img.fill(Qt.transparent)
    p = QPainter(img)
    p.setRenderHint(QPainter.Antialiasing)
    return img, p


def main():
    accent = QColor(sys.argv[sys.argv.index("--accent") + 1]) if "--accent" in sys.argv else art.RED
    app = QGuiApplication(sys.argv)  # noqa: F841
    OUT.mkdir(parents=True, exist_ok=True)

    # Background: the tactical wallpaper without the emblem area busy-ness, at 1920x1080
    art.wallpaper(1920, 1080, accent, emblem=False).save(str(OUT / "background.png"))

    # Emblem brackets (white) and crosshair (accent) as separate layers so the crosshair can pulse
    s = 1.6
    img, p = canvas(int(128 * s), int(90.38 * s))
    p.setPen(Qt.NoPen)
    p.setBrush(art.WHITE)
    p.drawPolygon(art.poly(art.EMBLEM_BRACKET, 0, 0, s))
    p.drawPolygon(art.poly(art.mirrored(art.EMBLEM_BRACKET), 0, 0, s))
    p.end()
    img.save(str(OUT / "emblem.png"))

    img, p = canvas(int(128 * s), int(90.38 * s))
    p.setPen(Qt.NoPen)
    p.setBrush(accent)
    for x, y, w, h in art.EMBLEM_TICKS:
        p.drawRect(QRectF(x * s, y * s, w * s, h * s))
    p.end()
    img.save(str(OUT / "crosshair.png"))

    # Progress cells (slanted) and password box
    for name, colour in (("cell-on", accent), ("cell-off", QColor(236, 232, 225, 30))):
        img, p = canvas(26, 12)
        p.setPen(Qt.NoPen)
        p.setBrush(colour)
        p.drawPolygon([QPointF(0, 0), QPointF(20, 0), QPointF(26, 6), QPointF(26, 12), QPointF(6, 12), QPointF(0, 6)])
        p.end()
        img.save(str(OUT / f"{name}.png"))

    img, p = canvas(520, 58)
    p.setBrush(QColor(15, 25, 35, 220))
    p.setPen(QPen(accent, 2))
    p.drawPolygon([QPointF(13, 1), QPointF(519, 1), QPointF(519, 45), QPointF(507, 57), QPointF(1, 57), QPointF(1, 13)])
    p.end()
    img.save(str(OUT / "entry.png"))
    for f in sorted(OUT.glob("*.png")):
        print("wrote", f)


if __name__ == "__main__":
    main()
