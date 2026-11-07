"""Passers-by for the day episodes: nine more Rocketbox avatars (MIT, see
models/people/CREDITS.md), people in plain clothes who could have stood in
a Sverdlovsk shop queue in 1988.

Takes them from a checkout of github.com/microsoft/Microsoft-Rocketbox and
writes models/people/<folder>/ the way the rest of the cast is kept: the
FBX as it is, colour and normal maps at 1024 px JPEG, the hair/lash
cut-out card as PNG with its alpha.

    git clone --filter=blob:none --no-checkout --depth 1 https://github.com/microsoft/Microsoft-Rocketbox rb
    git -C rb sparse-checkout set --no-cone 'Assets/Avatars/*/Female_Adult_02/*' ...
    git -C rb checkout
    python tools/make_passersby.py rb
"""

import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

## game folder -> Rocketbox avatar
AVATARS = {
    "woman3": "Adults/Female_Adult_02",  # white sweater, denim skirt
    "woman4": "Adults/Female_Adult_07",  # brown jacket, jeans, boots
    "woman5": "Adults/Female_Adult_11",  # brown knitted dress, boots
    "woman6": "Professions/Business_Female_03",  # brown suit and skirt
    "man2": "Adults/Male_Adult_05",  # grey beard, quilted waistcoat
    "man3": "Adults/Male_Adult_08",  # blue shirt, a worker
    "man4": "Adults/Male_Adult_10",  # red tracksuit
    "man5": "Adults/Male_Adult_14",  # bald, grey shirt, a pensioner
    "man6": "Professions/Business_Male_04",  # bald, waistcoat
}


def convert(rb: Path, folder: str, avatar: str) -> None:
    src = rb / "Assets/Avatars" / avatar
    out = ROOT / "models/people" / folder
    out.mkdir(parents=True, exist_ok=True)
    name = avatar.split("/")[-1]
    shutil.copy(src / f"Export/{name}.fbx", out / f"{folder}.fbx")
    for tga in sorted((src / "Textures").glob("*.tga")):
        # m024_body_color.tga -> body_color.jpg
        _, part, kind = tga.stem.split("_", 2)
        if kind not in ("color", "normal"):
            continue
        im = Image.open(tga)
        if part == "opacity":
            im = im.convert("RGBA")
        else:
            im = im.convert("RGB")
        if im.width > 1024:
            im = im.resize((1024, im.height * 1024 // im.width), Image.LANCZOS)
        if part == "opacity":
            im.save(out / f"{part}_{kind}.png", optimize=True)
        else:
            im.save(out / f"{part}_{kind}.jpg", quality=88)
    print(folder, "<-", avatar)


if __name__ == "__main__":
    rb = Path(sys.argv[1])
    for f, a in AVATARS.items():
        convert(rb, f, a)
