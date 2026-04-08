#!/usr/bin/env python3
"""
App Icon 1024: 外周の白余白を OpenCV inpaint で内側の青に馴染ませる。
（距離変換の最近傍コピーは縞模様になりやすいため使わない）

依存: pip install opencv-python-headless pillow
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


def outer_white_mask(rgb: np.ndarray) -> np.ndarray:
    """角からつながる近白ピクセル = 画像外周の余白。"""
    h, w = rgb.shape[:2]
    near_white = np.all(rgb.astype(np.float32) >= 248, axis=2)
    visited = np.zeros((h, w), dtype=bool)
    stack: list[tuple[int, int]] = []
    for x in range(w):
        for y in (0, h - 1):
            if near_white[y, x]:
                stack.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if near_white[y, x]:
                stack.append((y, x))
    while stack:
        y, x = stack.pop()
        if visited[y, x]:
            continue
        if not near_white[y, x]:
            continue
        visited[y, x] = True
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and near_white[ny, nx]:
                stack.append((ny, nx))
    return visited


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    default_src = root / "scripts" / "AppIconSource.png"
    default_dst = root / "Kintore" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"

    p = argparse.ArgumentParser(description="Generate AppIcon.png from source with white margin removed via inpainting.")
    p.add_argument("--source", type=Path, default=default_src)
    p.add_argument("--output", type=Path, default=default_dst)
    p.add_argument("--radius", type=int, default=24, help="cv2.inpaint neighborhood radius")
    p.add_argument("--dilate", type=int, default=2, help="mask dilate iterations (ellipse 5x5)")
    args = p.parse_args()

    if not args.source.is_file():
        print(f"Source not found: {args.source}", file=sys.stderr)
        return 1

    img = np.array(Image.open(args.source).convert("RGB"))
    h, w = img.shape[:2]
    outer = outer_white_mask(img)
    mask_u8 = (outer.astype(np.uint8) * 255)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask_u8 = cv2.dilate(mask_u8, kernel, iterations=args.dilate)

    bgr = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    result_bgr = cv2.inpaint(bgr, mask_u8, args.radius, cv2.INPAINT_NS)
    out_rgb = cv2.cvtColor(result_bgr, cv2.COLOR_BGR2RGB)

    rgba = np.dstack([out_rgb, np.full((h, w), 255, dtype=np.uint8)])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(args.output)
    print(f"Wrote {args.output} (outer margin {outer.mean():.1%} filled)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
