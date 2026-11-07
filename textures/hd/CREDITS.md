# 2K surfaces / Сканированные материалы

`textures/hd/*.webp` are the game's own drawn surfaces (tools/make_textures.py,
make_exterior.py) enlarged to 2048 px with the fine detail of real scanned
materials laid into them by `tools/make_hd_textures.py`: grain and pores in the
colour, relief in the normal map, smudges in the gloss, dirt in the hollows.

All scans are **CC0** (public domain), taken from the MatSynth collection
(https://huggingface.co/datasets/gvecchio/MatSynth), which gathers them from
their original sites:

| Surface | Scan | Source |
|---|---|---|
| floor | Terrazzo 005 | ambientCG |
| kafel, enamel, ceiling | Plaster 001 | ambientCG |
| concrete, ext_slabs, ext_panel | Concrete Wall 005 | Poly Haven |
| wall | White Rough Plaster | Poly Haven |
| metal, paint, locker, ext_profnastil | Painted Metal 009 | ambientCG |
| galv, frozen, corrugated | Galvanized Steel 001 | cgbookcase |
| door, wood | Painted Wood 004 | ambientCG |
| cardboard | Cardboard 004 | ambientCG |
| ext_asphalt | Asphalt 024 C | ambientCG |
