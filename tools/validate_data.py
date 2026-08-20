#!/usr/bin/env python3
import sys
import os
import re
from datetime import datetime
from urllib.parse import urlparse, parse_qs

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DATA_FILES = {
    '_data/current.yml': {
        'allowed': {'name', 'location', 'dates', 'url', 'twitter', 'status'},
        'required': {'name', 'location', 'dates', 'url'},
        'order': 'ascending',
        'strict': True,
        'check_tracking': True
    },
    '_data/past.yml': {
        'allowed': {'name', 'location', 'dates', 'url', 'twitter', 'status', 'video_playlist', 'video_url'},
        'required': {'name', 'location', 'dates', 'url'},
        'order': None,
        'strict': False,
        'check_tracking': False
    },
    '_data/closed.yml': {
        'allowed': {'name', 'location', 'first_date', 'last_date', 'url', 'twitter', 'status'},
        'required': {'name', 'location', 'first_date', 'last_date', 'url'},
        'order': None,
        'strict': True,
        'check_tracking': True
    }
}

MONTH_MAP = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12
}

MONTH_PATTERN = r'(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)'

def parse_simple_yaml_list(filepath):
    entries = []
    curr = None
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    for line in lines:
        raw = line
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        if stripped.startswith('- '):
            if curr is not None:
                entries.append(curr)
            curr = {}
            body = stripped[2:].strip()
            if ':' in body:
                k, v = body.split(':', 1)
                curr[k.strip()] = v.strip().strip('\"\'')
        elif curr is not None and ':' in stripped:
            k, v = stripped.split(':', 1)
            curr[k.strip()] = v.strip().strip('\"\'')
    if curr is not None:
        entries.append(curr)
    return entries

def parse_event_date(value, boundary='start'):
    if not value:
        return None
    text = str(value).strip().replace('–', '-').replace('—', '-')
    
    m = re.match(r'^(' + MONTH_PATTERN + r')\s+(\d{1,2})\s*-\s*(' + MONTH_PATTERN + r')\s*(\d{1,2}),?\s*(\d{4})$', text, re.IGNORECASE)
    if m:
        s_m, s_d, e_m, e_d, year = m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)
    else:
        m = re.match(r'^(' + MONTH_PATTERN + r')\s+(\d{1,2})\s*-\s*(\d{1,2}),?\s*(\d{4})$', text, re.IGNORECASE)
        if m:
            s_m = e_m = m.group(1)
            s_d, e_d, year = m.group(2), m.group(3), m.group(4)
        else:
            m = re.match(r'^(' + MONTH_PATTERN + r')\s+(\d{1,2}),?\s*(\d{4})$', text, re.IGNORECASE)
            if m:
                s_m = e_m = m.group(1)
                s_d = e_d = m.group(2)
                year = m.group(3)
            else:
                return None

    month_name = e_m if boundary == 'end' else s_m
    day = e_d if boundary == 'end' else s_d
    m_idx = MONTH_MAP.get(month_name.lower())
    if not m_idx:
        return None
    try:
        return datetime(int(year), m_idx, int(day))
    except ValueError:
        return None

def valid_url(url_str):
    try:
        u = urlparse(url_str)
        return u.scheme in ('http', 'https') and bool(u.netloc)
    except Exception:
        return False

def has_tracking_source(url_str):
    try:
        u = urlparse(url_str)
        qs = parse_qs(u.query)
        return 'testingconferences' in qs.get('utm_source', [])
    except Exception:
        return False

def main():
    errors = []
    warnings = []
    seen_names = {}

    for rel_path, rules in DATA_FILES.items():
        abs_path = os.path.join(ROOT, rel_path)
        if not os.path.exists(abs_path):
            errors.append(f"{rel_path}: file not found")
            continue
        
        data = parse_simple_yaml_list(abs_path)
        local_names = set()
        previous_date = None

        for index, event in enumerate(data, 1):
            label = f"{rel_path}[{index}]"
            name = event.get('name', '').strip()
            display = f"{rel_path}: {name}" if name else label

            unknown_fields = set(event.keys()) - rules['allowed']
            if unknown_fields:
                msg = f"{display}: unknown fields: {', '.join(sorted(unknown_fields))}"
                if rules['strict']:
                    errors.append(msg)
                else:
                    warnings.append(msg)

            for req in rules['required']:
                if not event.get(req):
                    msg = f"{display}: missing required field `{req}`"
                    if rules['strict']:
                        errors.append(msg)
                    else:
                        warnings.append(msg)

            if name:
                if name in local_names:
                    warnings.append(f"{display}: duplicate name in {rel_path}")
                local_names.add(name)
                seen_names.setdefault(name, []).append(rel_path)

            if '@' in event.get('twitter', ''):
                errors.append(f"{display}: twitter value should not include @")

            if 'url' in event:
                u = event['url']
                if not valid_url(u):
                    errors.append(f"{display}: url is not a valid HTTP(S) URL")
                elif rules['check_tracking'] and not has_tracking_source(u):
                    warnings.append(f"{display}: url is missing utm_source=testingconferences")

            if 'video_playlist' in event and not valid_url(event['video_playlist']):
                errors.append(f"{display}: video_playlist is not a valid HTTP(S) URL")

            if 'video_url' in event and not valid_url(event['video_url']):
                warnings.append(f"{display}: video_url is not a valid HTTP(S) URL")

            if rel_path == '_data/closed.yml':
                f_date = parse_event_date(event.get('first_date'), 'start')
                l_date = parse_event_date(event.get('last_date'), 'end')
                if event.get('first_date') and not f_date:
                    warnings.append(f"{display}: could not parse first_date")
                if event.get('last_date') and not l_date:
                    warnings.append(f"{display}: could not parse last_date")
                if f_date and l_date and f_date > l_date:
                    errors.append(f"{display}: first_date is after last_date")
            elif event.get('dates'):
                order_date = parse_event_date(event.get('dates'), 'start')
                if not order_date and 'TBA' not in event.get('dates', '') and not re.search(r'20\d\d', event.get('dates','')):
                    warnings.append(f"{display}: could not parse dates for ordering")

                if rules['order'] and order_date and previous_date:
                    if rules['order'] == 'ascending' and order_date < previous_date:
                        warnings.append(f"{display}: appears out of chronological order ({order_date.strftime('%Y-%m-%d')} < {previous_date.strftime('%Y-%m-%d')})")
                if order_date:
                    previous_date = order_date

    for w in warnings:
        print(f"WARNING: {w}", file=sys.stderr)
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)

    if not errors:
        print(f"Conference data validation passed with {len(warnings)} warning(s).")
        sys.exit(0)
    else:
        print(f"Conference data validation failed with {len(errors)} error(s) and {len(warnings)} warning(s).", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
