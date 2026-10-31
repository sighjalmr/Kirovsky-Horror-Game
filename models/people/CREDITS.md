# Люди / People

The people of the store are avatars from the **Microsoft Rocketbox Avatar
Library** — https://github.com/microsoft/Microsoft-Rocketbox — © Microsoft,
released under the MIT licence (text below). Models and textures by the
Rocketbox team (Markus Wojcik and others); motion capture from the same
library's `Assets/Animations`.

| Role | Folder | Rocketbox avatar |
|---|---|---|
| Ковпак, director | kovpak | Adults/Male_Adult_03 |
| Тамара Ивановна, cashier | tamara | Professions/Business_Female_02 |
| Вася Кран, loader | vasya | Professions/Gardener_Male_01 |
| Эдик, фарцовщик | edik | Adults/Male_Adult_07 |
| shopper | woman1 | Adults/Female_Adult_09 |
| shopper | woman2 | Adults/Female_Adult_14 |
| shopper | man1 | Adults/Male_Adult_02 |
| the killer | killer | Adults/Male_Adult_20 (clothes dyed black) |
| Колесников, участковый | kolesnikov | Professions/Police_Male_01 (redressed, see below) |

Changes: textures scaled from 2048 to 1024 px and saved as JPEG/PNG
(specular maps dropped); the killer's body texture darkened; the clips in
`anims/` were cut from m/f_walk_neutral_01, m_walk_slow_01, m_run_neutral_01,
m/f_idle_neutral_01, m_idle_breathe_01, m/f_gestic_talk_neutral_01,
f_sit_chair_idle_neutral_01 and m_hold_bag_idle / f_hold_bag_idle_01 by
`tools/make_people_anims.gd`. Колесников's uniform was repainted by `tools/make_kolesnikov.py` (foreign
insignia painted out, Soviet shoulder boards and sleeve shield painted in,
darker trousers, goatee shaved to a moustache); his peaked cap is the game's
own. Kovpak's spectacles (tools/build_glasses.py), the hats, bags, the scarf and the cleaver are the
game's own (scripts/characters.gd).

Citation asked for by the authors: M. Gonzalez-Franco et al., "The Rocketbox
library and the utility of freely available rigged avatars", Frontiers in
Virtual Reality, 2020, doi:10.3389/frvir.2020.561558.

```
MIT License

Copyright (c) 2020 Microsoft

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
