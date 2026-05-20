# -*- coding: utf-8 -*-
"""
Helper: read JSON from stdin, return a single match result.
Usage:
    echo $JSON | python check.py <expr>
where <expr> is one of:
    msg_contains:<vietnamese substring>
    field:<jsonpath>           — print value
    eq:<jsonpath>:<expected>   — print "TRUE"/"FALSE"
"""
import json
import sys
import io

# Force UTF-8 on stdout for child cmd output
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', newline='')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', newline='')

if len(sys.argv) < 2:
    print("USAGE")
    sys.exit(2)

expr = sys.argv[1]
data = json.load(sys.stdin)


def get_path(d, path):
    """Walk dotted path; '?' means optional dict; supports nested via .a.b.c"""
    cur = d
    for part in path.split('.'):
        if cur is None:
            return None
        if isinstance(cur, dict):
            cur = cur.get(part)
        else:
            return None
    return cur


if expr.startswith('msg_contains:'):
    needle = expr[len('msg_contains:'):]
    msg = get_path(data, 'message') or ''
    if isinstance(msg, str) and needle in msg:
        print('YES')
    else:
        # also try data.message
        msg2 = get_path(data, 'data.message') or ''
        if isinstance(msg2, str) and needle in msg2:
            print('YES')
        else:
            print('NO')

elif expr.startswith('field:'):
    path = expr[len('field:'):]
    val = get_path(data, path)
    if val is None:
        print('null')
    elif isinstance(val, bool):
        print('true' if val else 'false')
    else:
        print(val)

elif expr.startswith('eq:'):
    rest = expr[len('eq:'):]
    path, _, expected = rest.partition('::')
    val = get_path(data, path)
    if val is None:
        print('TRUE' if expected == 'null' else 'FALSE')
    elif isinstance(val, bool):
        print('TRUE' if (str(val).lower() == expected.lower()) else 'FALSE')
    else:
        print('TRUE' if str(val) == expected else 'FALSE')

elif expr.startswith('contains_path:'):
    rest = expr[len('contains_path:'):]
    path, _, needle = rest.partition('::')
    val = get_path(data, path) or ''
    print('YES' if isinstance(val, str) and needle in val else 'NO')

else:
    print('BAD_EXPR')
    sys.exit(2)
