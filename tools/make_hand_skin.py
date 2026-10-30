"""Grades the hand model's photo texture (models/hand/caucasian_baseColor.png,
CC0, Godot XR Tools) into Gordeev's skin: models/hand/hand_skin.png.

The source is a young, sunburnt orange. A night guard past fifty in October
is paler and greyer, with a ruddy tinge on the knuckles; under the sodium-
green of the shop lamps the orange would read as plastic.

    python3 tools/make_hand_skin.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

HAND = Path(__file__).resolve().parent.parent / "models" / "hand"


def main():
    src = Image.open(HAND / "caucasian_baseColor.png").convert("RGBA")
    a = np.asarray(src).astype(np.float32) / 255.0
    rgb = a[..., :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    # Take out most of the orange, keep the veins and creases (they are in
    # the luminance), then tint towards a pale, slightly ruddy grey-pink.
    grey = lum[..., None]
    rgb = grey + (rgb - grey) * 0.42
    tone = np.array([1.0, 0.89, 0.83], np.float32)
    rgb = rgb * tone
    # Deepen the creases a touch and pull the overall value down.
    rgb = np.clip((rgb - 0.5) * 1.12 + 0.5, 0, 1) * 0.7
    a[..., :3] = rgb
    Image.fromarray((a * 255 + 0.5).astype(np.uint8)).save(HAND / "hand_skin.png", optimize=True)
    print("hand_skin.png")


if __name__ == "__main__":
    main()
