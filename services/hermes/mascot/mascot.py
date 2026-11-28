"""Brian mascot: a little CRT terminal with an 8-bit face. Writes one transparent
SVG per expression into OUT (sticker sources). Pixel grid is 14x10 inside the
screen. Render: rsvg-convert -w 512 -h 512 happy.svg -o stickers/happy.png"""
import sys, os

OUT = sys.argv[1]
GREEN, DIM = "#39ff8a", "#1f8f4f"
FACES = {
    "happy": [
        "..............",
        "..............",
        "...##....##...",
        "..#..#..#..#..",
        "..............",
        "..............",
        "...#......#...",
        "....######....",
        "..............",
        "..............",
    ],
    "neutral": [
        "..............",
        "..............",
        "...##....##...",
        "...##....##...",
        "...##....##...",
        "..............",
        "..............",
        "....######....",
        "..............",
        "..............",
    ],
    "wink": [
        "..............",
        "..............",
        "...##.........",
        "...##....###..",
        "...##.........",
        "..............",
        "...#......#...",
        "....######....",
        "..............",
        "..............",
    ],
    "thinking": [
        "..............",
        "....##....##..",
        "....##....##..",
        "..............",
        "..............",
        "..............",
        ".....####.....",
        "..............",
        "..#.#.#.......",
        "..............",
    ],
    "wow": [
        "..............",
        "..##......##..",
        "..##......##..",
        "..##......##..",
        "..............",
        "......##......",
        ".....#..#.....",
        ".....#..#.....",
        "......##......",
        "..............",
    ],
    "sleepy": [
        "..........###.",
        "............#.",
        "...........#..",
        "..###...####..",
        "..............",
        "..............",
        "..............",
        ".....####.....",
        "..............",
        "..............",
    ],
}

def svg(face, with_bg=True):
    cell, gx, gy = 24, 152, 196   # 14*24=336 wide, 10*24=240 tall
    px = []
    for r, row in enumerate(face):
        for c, ch in enumerate(row):
            if ch == "#":
                px.append(f'<rect x="{gx + c*cell}" y="{gy + r*cell}" width="{cell-2}" height="{cell-2}" rx="3"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640">
  {'<rect width="640" height="640" fill="#0d1110"/>' if with_bg else ''}
  <!-- antenna -->
  <rect x="314" y="96" width="12" height="54" rx="6" fill="#2c3a34"/>
  <circle cx="320" cy="92" r="16" fill="{GREEN}"/>
  <circle cx="320" cy="92" r="28" fill="{GREEN}" opacity="0.15"/>
  <!-- CRT head -->
  <rect x="112" y="146" width="416" height="344" rx="48" fill="#121a17" stroke="#2c3a34" stroke-width="12"/>
  <rect x="136" y="170" width="368" height="296" rx="30" fill="#0a120e"/>
  <!-- face -->
  <g fill="{GREEN}">{''.join(px)}</g>
  <!-- glow + sheen -->
  <rect x="136" y="170" width="368" height="296" rx="30" fill="{GREEN}" opacity="0.04"/>
  <rect x="136" y="170" width="368" height="90" rx="30" fill="#ffffff" opacity="0.03"/>
  <!-- little feet/stand -->
  <rect x="236" y="496" width="168" height="22" rx="11" fill="#2c3a34"/>
</svg>'''

# Stickers: transparent background (Telegram shows them floating in chat).
os.makedirs(OUT, exist_ok=True)
for name, face in FACES.items():
    open(os.path.join(OUT, f"{name}.svg"), "w").write(svg(face, with_bg=False))
print("ok", len(FACES))
