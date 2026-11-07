"""2K faces and clothes for the cast: the Rocketbox textures at their full
2048 px (the game's own copies are cut to 1024), plus the specular maps the
first conversion dropped, turned into gloss maps so skin, lips and eyes
shine where they should and wool stays matt.

Writes models/people/<folder>/hd/<part>_color.webp, <part>_normal.webp and
<part>_spec.webp; Person loads them when «Текстуры 2K» is on. The killer's
dyed clothes and Колесников's repainted uniform keep their game copies
(only their heads get the 2K maps).

    git clone --filter=blob:none --no-checkout --depth 1 https://github.com/microsoft/Microsoft-Rocketbox rb
    git -C rb sparse-checkout set --no-cone 'Assets/Avatars/Adults/Male_Adult_03/Textures/*' ...
    git -C rb checkout
    python tools/make_people_hd.py rb
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PEOPLE = ROOT / "models/people"

CAST = {
    "kovpak": "Adults/Male_Adult_03", "tamara": "Professions/Business_Female_02",
    "vasya": "Professions/Gardener_Male_01", "edik": "Adults/Male_Adult_07",
    "woman1": "Adults/Female_Adult_09", "woman2": "Adults/Female_Adult_14", "man1": "Adults/Male_Adult_02",
    "killer": "Adults/Male_Adult_20", "kolesnikov": "Professions/Police_Male_01",
    "woman3": "Adults/Female_Adult_02", "woman4": "Adults/Female_Adult_07", "woman5": "Adults/Female_Adult_11",
    "woman6": "Professions/Business_Female_03", "man2": "Adults/Male_Adult_05", "man3": "Adults/Male_Adult_08",
    "man4": "Adults/Male_Adult_10", "man5": "Adults/Male_Adult_14", "man6": "Professions/Business_Male_04",
}
# Their clothes were repainted for the game: keep the game's body texture.
OWN_BODY = {"killer", "kolesnikov"}

IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
metadata={{
"vram_texture": true
}}

[deps]

source_file="res://models/people/{folder}/hd/{name}"

[params]

compress/mode=2
compress/high_quality=false
compress/normal_map={nm}
mipmaps/generate=true
mipmaps/limit=-1
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
detect_3d/compress_to=0
"""


def convert(rb: Path, folder: str, avatar: str) -> None:
    src = rb / "Assets/Avatars" / avatar / "Textures"
    out = PEOPLE / folder / "hd"
    out.mkdir(exist_ok=True)
    for tga in sorted(src.glob("*.tga")):
        _, part, kind = tga.stem.split("_", 2)
        if kind not in ("color", "normal", "specular"):
            continue
        if part == "body" and folder in OWN_BODY and kind != "specular":
            continue
        if part not in ("head", "body", "opacity", "equipment"):
            continue
        im = Image.open(tga)
        if kind == "specular":
            im = im.convert("L")
            if im.width > 1024:
                im = im.resize((1024, im.height * 1024 // im.width), Image.LANCZOS)
            kind = "spec"
        elif part == "opacity":
            im = im.convert("RGBA")
        else:
            im = im.convert("RGB")
        name = f"{part}_{kind}.webp"
        im.save(out / name, "WEBP", quality=92 if kind != "normal" else 94, method=6)
        imp = out / (name + ".import")
        if not imp.exists():
            imp.write_text(IMPORT.format(folder=folder, name=name, nm=1 if kind == "normal" else 0))
    print(folder, "<-", avatar)


if __name__ == "__main__":
    rb = Path(sys.argv[1])
    for f, a in CAST.items():
        if (PEOPLE / f).exists():
            convert(rb, f, a)
