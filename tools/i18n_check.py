#!/usr/bin/env python3
"""Lists Russian text in scripts/*.gd that i18n/en.json or i18n/hu.json lacks.

    python3 tools/i18n_check.py          # what is missing in each language
    python3 tools/i18n_check.py --stale  # also keys no script has any more

Keys are the exact Russian strings (the game passes Russian text around and
scripts/loc.gd translates it on the screen). Signs in the store stay Russian on
purpose and are listed in SIGNS. Text the game glues together at run time is
found best by playing: `godot --path . -- --lang=en --i18n-missing=/tmp/m.txt`
(add --nighttest, --night2 ... to run a chapter on fast clocks) writes every
Russian line that reached the screen untranslated.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CYR = re.compile('[А-Яа-яЁё]')
## Signs, plates and labels inside the 1988 store: never translated.
SIGNS = {
    'ПОБЕДИТЕЛЮ\nСОЦ.\nСОРЕВНОВАНИЯ', 'ШХ-1,12', 'МОНПАНСЬЕ', 'sign:МОЛОКО', 'МЯСО', 'ТРЕВОГА',
    'КЛЮЧ\nПРИ ПОЖАРЕ', 'Р.', 'БАКАЛЕЯ', 'КОНСЕРВЫ', 'МОЛОКО', 'ЗАМОРОЗКА', 'ПРОМТОВАРЫ', 'ТКАНИ',
    'ПОСУДА', 'ГАЛАНТЕРЕЯ', 'ДИРЕКТОР', 'ПОДВАЛ', 'МИЛИЦИЯ',
}
## Files whose strings carry a context (Loc.t(text, "<context>")).
CONTEXT = {'tactics.gd': 'plan'}


def literals(src):
    i, n, out = 0, len(src), []
    while i < n:
        c = src[i]
        if c == '#':
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if src.startswith('"""', i):
            j = src.find('"""', i + 3)
            out.append(src[i + 3:j])
            i = j + 3
            continue
        if c in '"\'':
            j, buf = i + 1, []
            while src[j] != c:
                if src[j] == '\\':
                    e = src[j + 1]
                    buf.append({'n': '\n', 't': '\t', '"': '"', "'": "'", '\\': '\\'}.get(e, '\\' + e))
                    j += 2
                else:
                    buf.append(src[j])
                    j += 1
            out.append(''.join(buf))
            i = j + 1
            continue
        i += 1
    return out


def main():
    used = {}
    for f in sorted(glob.glob(os.path.join(ROOT, 'scripts', '*.gd'))):
        name = os.path.basename(f)
        if name.startswith('dev_') or name == 'loc.gd':
            continue
        for s in literals(open(f, encoding='utf8').read()):
            if CYR.search(s) and s not in SIGNS:
                used.setdefault(s, name)
    bad = 0
    for lang in ('en', 'hu'):
        data = json.load(open(os.path.join(ROOT, 'i18n', lang + '.json'), encoding='utf8'))
        def has(k):
            ctx = CONTEXT.get(used[k], '')
            return k in data or k.strip() in data or (ctx and ctx + '|' + k in data)
        missing = [k for k in used if not has(k)]
        print('%s: %d keys, %d missing' % (lang, len(data), len(missing)))
        for k in missing:
            print('  %s: %s' % (used[k], json.dumps(k, ensure_ascii=False)))
        bad += len(missing)
        if '--stale' in sys.argv:
            plain = {u.strip() for u in used} | SIGNS
            stale = [k for k in data if '%' not in k and k.split('|')[-1].strip() not in plain]
            for k in stale:
                print('  stale: %s' % json.dumps(k, ensure_ascii=False))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
