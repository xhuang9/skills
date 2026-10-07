#!/usr/bin/env python3
"""WCAG contrast check. Usage: contrast.py FG BG [FG BG ...]  (hex colours, e.g. 1d2421 f6f7f5).
Prints each ratio and whether it meets AAA (7:1 for text under 24px regular / 18.66px bold)."""
import sys

def lum(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    def ch(c):
        c = int(c, 16) / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(h[i:i + 2]) for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

args = sys.argv[1:]
if not args or len(args) % 2:
    sys.exit(__doc__)
fail = 0
for fg, bg in zip(args[::2], args[1::2]):
    r = ratio(fg, bg)
    ok = r >= 7
    fail += not ok
    print(f"{'PASS' if ok else 'FAIL'} {r:5.2f}:1  #{fg.lstrip('#')} on #{bg.lstrip('#')}")
sys.exit(1 if fail else 0)
