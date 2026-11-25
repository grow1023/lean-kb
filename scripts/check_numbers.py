#!/usr/bin/env python3
"""check_numbers.py FACTS FILE [--allow ALLOWFILE]

Every measured number in FILE must exist in FACTS.
A measured number is: a number with a decimal point, a number followed by % / %p / 배 / x / times,
or an integer of 100 or more. Small bare integers (list numbers, step counts) are not checked.
HTML input: tags, <script> and <style> are removed. Text inside <svg> is checked.
ALLOWFILE: one number per line, then a tab or spaces, then the reason. Reasons are required.
Exit 0 = all found. Exit 1 = unknown numbers. Exit 2 = usage or read error (fail-closed).
"""
import html
import re
import sys

NUM = re.compile(r'(?<![\w.,])(\d{1,3}(?:,\d{3})+|\d+)(?!\d)(\.\d+(?!\d))?(?!\.\d)(\s?(?:%p|%|배|x\b|times\b))?')


ATTR = re.compile(r'(?is)\b(?:aria-label|alt|title|data-tip)\s*=\s*"([^"]*)"')


def text_of(raw):
    raw = re.sub(r'(?is)<(script|style)\b.*?</\1>', ' ', raw)
    raw = raw + ' ' + ' '.join(ATTR.findall(raw))  # readers hear these too
    raw = re.sub(r'(?s)<!--.*?-->', ' ', raw)
    raw = re.sub(r'(?s)<[^>]+>', ' ', raw)
    return html.unescape(raw)


def measured(text):
    out = {}
    for m in NUM.finditer(text):
        whole, frac, unit = m.group(1).replace(',', ''), m.group(2) or '', m.group(3)
        if not (frac or unit or int(whole) >= 100):
            continue
        key = whole.lstrip('0') or '0'
        key += frac
        out.setdefault(key, text[max(0, m.start() - 24):m.end() + 12].replace('\n', ' ').strip())
    return out


def known(text):
    s = set()
    for m in NUM.finditer(text):
        whole, frac = m.group(1).replace(',', ''), m.group(2) or ''
        s.add((whole.lstrip('0') or '0') + frac)
    return s


def read(path):
    with open(path, 'rb') as f:
        return f.read().decode('utf-8', 'replace')


def selftest():
    facts = '13.8%  10.3배  1,333,077 토큰  16/52  3,874'
    assert not set(measured('정답 근거는 13.8%였고 1333077토큰, 3,874')) - known(facts)
    assert set(measured('근거는 14.2%였다')) - known(facts) == {'14.2'}
    assert set(measured('1. 첫째 2. 둘째 8가지 52회')) == set()
    assert set(measured('<svg><text>99.9%</text></svg><script>var a = 77.7;</script>'.replace('<svg>', ' '))) >= {'99.9'}
    assert '77.7' not in measured(text_of('<script>var a = 77.7;</script><p>ok</p>'))
    assert '88.8' in measured(text_of('<svg aria-label="값 88.8%"></svg>'))
    # a dotted version or a date is not a measured number
    assert set(measured('version 0.1.0, 1000.0.1, 13.85.1, 2026.11.23')) == set()
    assert set(measured('13.8% and 1,333,077 and 0.355배')) == {'13.8', '1333077', '0.355'}
    print('selftest ok')


def main(argv):
    if argv[1:] == ['--selftest']:
        selftest()
        return 0
    allow = set()
    args = argv[1:]
    if '--allow' in args:
        i = args.index('--allow')
        try:
            for line in read(args[i + 1]).splitlines():
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(None, 1)
                if len(parts) < 2:
                    print('ERROR allow line has no reason: ' + line, file=sys.stderr)
                    return 2
                allow.add(parts[0].replace(',', ''))
        except (OSError, IndexError) as e:
            print('ERROR allow file: %s' % e, file=sys.stderr)
            return 2
        del args[i:i + 2]
    if len(args) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        base = known(read(args[0]))
    except OSError as e:
        print('ERROR facts: %s' % e, file=sys.stderr)
        return 2
    bad = 0
    for path in args[1:]:
        try:
            raw = read(path)
        except OSError as e:
            print('ERROR %s: %s' % (path, e), file=sys.stderr)
            return 2
        found = measured(text_of(raw) if '<' in raw and path.lower().endswith(('.html', '.htm')) else raw)
        if not found:
            print('ERROR %s: no measured number found (empty or wrong file?)' % path, file=sys.stderr)
            return 2
        for key, ctx in sorted(found.items()):
            if key not in base and key not in allow:
                bad += 1
                print('UNKNOWN %s in %s :: ...%s...' % (key, path, ctx))
        print('%s: %d measured numbers checked' % (path, len(found)))
    print('FAIL[numbers]: %d unknown' % bad if bad else 'PASS[numbers]')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
