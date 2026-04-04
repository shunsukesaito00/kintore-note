#!/usr/bin/env python3
"""
iOS の AppIcon（1024）から Watch AppIcon 用 PNG と Contents.json を生成する。
App Store / actool が求める role・subtype 付きスロットを含む。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    print("Pillow が必要です: pip install Pillow", file=sys.stderr)
    raise SystemExit(1) from e

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Kintore/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
DEST_DIR = ROOT / "KintoreWatch/Assets.xcassets/AppIcon.appiconset"


def load_rgb_no_alpha(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
    bg.paste(img, (0, 0), img)
    return bg.convert("RGB")


def save_resize(src: Image.Image, px: int, name: str) -> str:
    im = src.resize((px, px), Image.Resampling.LANCZOS)
    im.save(DEST_DIR / name, "PNG")
    return name


def main() -> None:
    if not SRC.is_file():
        print(f"ソースが見つかりません: {SRC}", file=sys.stderr)
        raise SystemExit(1)
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    src = load_rgb_no_alpha(SRC)
    images: list[dict] = []

    # watch-marketing（App Store 必須・不透過）
    n = save_resize(src, 1024, "AppIcon-marketing-1024.png")
    images.append(
        {
            "size": "1024x1024",
            "idiom": "watch-marketing",
            "filename": n,
            "scale": "1x",
        }
    )

    # (role, subtype, size_pt, scale) -> pixel = pt * scale_num
    # size 文字列は Xcode テンプレに合わせる（pt x pt）
    slots: list[tuple[str, str | None, str, str, int]] = [
        # notificationCenter
        ("notificationCenter", "38mm", "24x24", "2x", 48),
        ("notificationCenter", "42mm", "27.5x27.5", "2x", 55),
        ("notificationCenter", "45mm", "33x33", "2x", 66),
        ("notificationCenter", "49mm", "33x33", "2x", 66),
        # companionSettings
        ("companionSettings", None, "29x29", "2x", 58),
        ("companionSettings", None, "29x29", "3x", 87),
        # appLauncher
        ("appLauncher", "38mm", "40x40", "2x", 80),
        ("appLauncher", "40mm", "44x44", "2x", 88),
        ("appLauncher", "41mm", "46x46", "2x", 92),
        ("appLauncher", "44mm", "50x50", "2x", 100),
        ("appLauncher", "45mm", "51x51", "2x", 102),
        ("appLauncher", "49mm", "54x54", "2x", 108),
        # quickLook (Short Look) — 44mm は Series 4 以降で App Store 検証必須
        ("quickLook", "38mm", "86x86", "2x", 172),
        ("quickLook", "42mm", "98x98", "2x", 196),
        ("quickLook", "44mm", "108x108", "2x", 216),
        ("quickLook", "45mm", "117x117", "2x", 234),
        ("quickLook", "49mm", "129x129", "2x", 258),
    ]

    for i, (role, subtype, size_pt, scale, px) in enumerate(slots):
        fname = f"watch-icon-{i:02d}-{role}-{subtype or 'na'}-{px}.png".replace("/", "-")
        fname = save_resize(src, px, fname)
        entry: dict = {
            "size": size_pt,
            "idiom": "watch",
            "filename": fname,
            "scale": scale,
            "role": role,
        }
        if subtype:
            entry["subtype"] = subtype
        images.append(entry)

    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }
    (DEST_DIR / "Contents.json").write_text(
        json.dumps(contents, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(images)} icons to {DEST_DIR}")


if __name__ == "__main__":
    main()
