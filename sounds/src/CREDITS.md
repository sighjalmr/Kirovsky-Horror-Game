# Записи, из которых собраны шаги и звуки нападения

Это исходные полевые записи. Из них `tools/make_foley.py` режет, обрабатывает
и смешивает готовые звуки в `sounds/*.wav`. Godot эту папку не импортирует
(в ней лежит `.gdignore`).

| Файл | Что это | Автор | Лицензия | Откуда взят |
|---|---|---|---|---|
| `kenney_walking.ogg` | 12 шагов в ботинках по твёрдому полу | Kenney (kenney.nl) | CC0 1.0 | github.com/KenneyNL/Starter-Kit-FPS, `sounds/walking.ogg` |
| `erdie_concrete_1..3.ogg` | шаги по бетону | Erdie, freesound.org/s/41579 | CC BY 3.0 | github.com/minetest/minetest_game, `default_hard_footstep.*.ogg` |
| `thefitzyg_goresplat.ogg` | влажные удары по мясу | ThefitzyG, freesound.org/s/414296 | CC0 1.0 | github.com/tgstation/tgstation, `sound/effects/goresplat.ogg` |
| `niron3206_scream.ogg` | мужской предсмертный крик | Undefeatablesos, запись и обработка Niron3206 | CC0 1.0 | github.com/tgstation/tgstation, `sound/items/weapons/hammer_death_scream.ogg` |
| `scottemoil_male_cry.ogg` | мужские всхлипы | scottemoil, freesound.org/s/263776 | CC0 1.0 | github.com/tgstation/tgstation, `sound/mobs/humanoids/human/cry/male_cry2.ogg` |
| `rottako_heavy_drop_1..2.ogg` | падение тяжёлого тела | Rottako, freesound.org/s/693581 и 693582, чистка ArcaneMusic | CC0 1.0 | github.com/tgstation/tgstation, `sound/effects/heavy_drop*.ogg` |
| `altfuture_rip_1..4.ogg` | рвущаяся ткань | altfuture, freesound.org/s/174627 | CC0 1.0 | github.com/tgstation/tgstation, `sound/items/handling/cloth/rip*.ogg` |

Лицензия CC BY 3.0 (шаги Erdie) требует указать автора: в титрах игры нужно
написать «Footsteps on concrete by Erdie (freesound.org), CC BY 3.0». Остальные
записи CC0, их можно использовать как угодно, в том числе в платной игре.
