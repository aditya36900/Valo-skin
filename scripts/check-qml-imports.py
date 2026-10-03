#!/usr/bin/env python3
"""Catches QML files that use Qt Quick types without importing the module that provides them.

Quickshell refuses to load the whole shell when a single file does this ("Loader is not a
type"), and the offscreen test harness can hide it, so run this before pushing:

    scripts/check-qml-imports.py            # every tracked .qml file
    scripts/check-qml-imports.py a.qml b.qml
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Types provided by each module. Only types likely to appear in this repo are listed; anything
# not listed is ignored rather than guessed at.
MODULES = {
    "QtQuick": """
        Item Rectangle Text Image AnimatedImage BorderImage Loader Repeater MouseArea WheelHandler
        TapHandler HoverHandler DragHandler PointHandler Flickable ListView GridView PathView
        Column Row Grid Flow Positioner Canvas TextInput TextEdit FocusScope ShaderEffect
        ShaderEffectSource Behavior NumberAnimation ColorAnimation PropertyAnimation
        SequentialAnimation ParallelAnimation PauseAnimation ScriptAction PropertyAction
        SmoothedAnimation SpringAnimation RotationAnimation AnchorAnimation Transition State
        PropertyChanges StateGroup Translate Rotation Scale Matrix4x4 FontLoader IntValidator
        DoubleValidator RegularExpressionValidator ListModel ListElement Keys Gradient
        GradientStop Shortcut TextMetrics FontMetrics DropArea Drag MultiPointTouchArea
        PinchArea Window
    """,
    "QtQuick.Layouts": "RowLayout ColumnLayout GridLayout StackLayout",
    "QtQuick.Shapes": "Shape ShapePath",  # Path* elements also exist in QtQuick (PathView)
    "QtQuick.Effects": "MultiEffect RectangularShadow",
}
# QtQml types are also re-exported by QtQuick, so either import satisfies them.
# Names that also exist in Quickshell/Caelestia modules, so a repo file of the same name may not
# be what's meant
QS_TYPES = set("ShellScreen PersistentProperties Scope Singleton ScriptModel Notification".split())
QTQML = set("QtObject Timer Connections Component Binding Instantiator".split())

# Types defined by the repo's own qs.* modules: file stem -> module uri. Quickshell maps
# components/x/Foo.qml to qs.components.x, modules/... to qs.modules..., services, utils.
def repo_types() -> dict[str, set[str]]:
    types: dict[str, set[str]] = {}
    for top in ("components", "modules", "services", "utils"):
        for f in (ROOT / top).rglob("*.qml"):
            uri = "qs." + ".".join(f.relative_to(ROOT).parent.parts)
            types.setdefault(f.stem, set()).add(uri)
    return types


REPO_TYPES = repo_types()

TYPE_USE = re.compile(r"^\s*(?:component\s+\w+\s*:\s*)?([A-Z]\w*)\s*\{", re.M)
IMPORT = re.compile(r"^\s*import\s+([\w.]+)", re.M)
PROP_TYPE = re.compile(r"\bproperty\s+([A-Z]\w*)\s+\w+")
DIR_IMPORT = re.compile(r'^\s*import\s+"([^"]+)"', re.M)


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def check(path: Path) -> list[str]:
    text = strip_comments(path.read_text(encoding="utf-8"))
    imports = set(IMPORT.findall(text))
    # Directory imports (import "dash") count as the qs.* module for that directory
    for d in DIR_IMPORT.findall(text):
        rel = (path.parent / d).resolve().relative_to(ROOT)
        imports.add(".".join(("qs",) + rel.parts))
    local = {p.stem for p in path.parent.glob("*.qml")}
    problems = []
    for name in sorted(set(TYPE_USE.findall(text)) | set(PROP_TYPE.findall(text))):
        if name in local:
            continue  # same-directory component shadows module types
        if name in QTQML:
            if not imports & {"QtQml", "QtQuick"}:
                problems.append(f"{name} needs 'import QtQuick' (or QtQml)")
            continue
        for module, names in MODULES.items():
            if name in names.split() and module not in imports:
                problems.append(f"{name} needs 'import {module}'")
        uris = REPO_TYPES.get(name)
        if uris and not any(m in MODULES for m, n in MODULES.items() if name in n.split()):
            if not uris & imports and not any(i.startswith(("Quickshell", "Caelestia", "M3Shapes")) for i in imports if name in QS_TYPES):
                problems.append(f"{name} needs 'import {sorted(uris)[0]}'")
    return problems


def main() -> int:
    if len(sys.argv) > 1:
        files = [Path(a) for a in sys.argv[1:]]
    else:
        out = subprocess.run(["git", "ls-files", "*.qml"], cwd=ROOT, capture_output=True, text=True, check=True)
        files = [ROOT / f for f in out.stdout.split()]
    bad = 0
    for f in files:
        for problem in check(f):
            print(f"{f.relative_to(ROOT) if f.is_absolute() else f}: {problem}")
            bad += 1
    if bad:
        print(f"\n{bad} missing import(s)")
        return 1
    print(f"OK: {len(files)} QML files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
