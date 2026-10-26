#!/usr/bin/env python3
"""Validate owned UI resource coverage and refresh the legacy typed adapter.

Run after gen-l10n. Vehicle/marque names, technical codes, source credits and
external article bodies intentionally retain their source spelling.
"""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
# Logo lettering, manufacturer name, physical unit glyphs and keyboard shortcut.
UNTRANSLATED = {'BRAND', 'CENTRAL', 'bA', 'PlayStation', 'E', 'F', 'H', 'g', '°C'}
LITERAL = r"(?:'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")"

def decode(literal):
    return re.sub(r'\\([nrt\'"\\$])', lambda m: {'n':'\n','r':'\r','t':'\t'}.get(m[1],m[1]),literal[1:-1])

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-adapter', action='store_true')
    args = parser.parse_args()
    en = json.loads((ROOT/'lib/l10n/app_en.arb').read_text())
    ru = json.loads((ROOT/'lib/l10n/app_ru.arb').read_text())
    errors = []
    if en.keys() != ru.keys(): errors.append('RU/EN key sets differ')
    messages = {k:v for k,v in en.items() if not k.startswith('@')}
    static = {v.strip().lower():k for k,v in messages.items() if '@'+k not in en}
    for key,value in messages.items():
        if not isinstance(ru.get(key),str) or not ru[key].strip(): errors.append(f'Empty/missing RU: {key}')
        if en.get('@'+key) != ru.get('@'+key): errors.append(f'Placeholder schema differs: {key}')
        if '@'+key in en:
            for name in en['@'+key]['placeholders']:
                if '{'+name not in value or '{'+name not in ru.get(key,''): errors.append(f'Missing placeholder {key}.{name}')
    adapter = ROOT/'lib/l10n/ui_messages.dart'
    source = adapter.read_text()
    if args.write_adapter:
        cases = '\n'.join('      '+json.dumps(value,ensure_ascii=False).replace('$','\\$')+f' => {key},' for value,key in sorted(static.items()))
        source = re.sub(r'(final translated = switch \(normalized\) \{).*?(      _ => null,)', lambda m:m[1]+'\n'+cases+'\n'+m[2], source, flags=re.S)
        adapter.write_text(source)
    for value,key in static.items():
        if not re.search(r'=>\s*'+re.escape(key)+r'\s*,', source): errors.append(f'Adapter missing: {key}')
    count = 0
    for folder in ('lib/widgets','lib/pages'):
        for path in (ROOT/folder).rglob('*.dart'):
            text = path.read_text()
            for match in re.finditer(r'context\.tr\(\s*((?:'+LITERAL+r'\s*)+)\)',text):
                literals = re.findall(LITERAL,match[1]);value = ''.join(map(decode,literals))
                if '$' in value: continue  # Typed/dynamic templates are covered in widget tests.
                count += 1
                if re.search('[A-Za-z]',value) and value not in UNTRANSLATED and value.strip().lower() not in static:
                    errors.append(f'{path.relative_to(ROOT)}: missing owned message {value!r}')
    if errors:
        print('\n'.join(errors),file=sys.stderr);return 1
    print(f'Localization OK: {len(messages)} messages, identical RU/EN keys and placeholder schemas; {count} static UI uses checked.')
    return 0
if __name__ == '__main__': sys.exit(main())
