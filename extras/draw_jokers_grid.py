from PIL import Image, ImageDraw, ImageFont
import os

MOD_ROOT = os.path.dirname(__file__)
SRC = os.path.join(MOD_ROOT, 'assets', '1x', 'Jokers.png')
OUT = os.path.join(MOD_ROOT, 'assets', 'Jokers_grid.png')

# Grid cell size (matches playtime.lua: px=71, py=95)
PX = 71
PY = 95

def main():
    im = Image.open(SRC).convert('RGBA')
    w, h = im.size

    overlay = Image.new('RGBA', im.size, (0,0,0,0))
    draw = ImageDraw.Draw(overlay)

    # Draw vertical lines
    for i in range(0, w+PX, PX):
        draw.line([(i,0),(i,h)], fill=(255,0,0,200), width=2)
    # Draw horizontal lines
    for j in range(0, h+PY, PY):
        draw.line([(0,j),(w,j)], fill=(255,0,0,200), width=2)

    # Try to load a default font
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    cols = w // PX
    rows = h // PY

    # Label cells with column,row
    for r in range(rows):
        for c in range(cols):
            x = c * PX + 4
            y = r * PY + 2
            label = f"{c},{r}"
            draw.text((x,y), label, fill=(255,255,255,230), font=font)

    out = Image.alpha_composite(im, overlay)
    out.save(OUT)
    print('Saved grid overlay to', OUT)

if __name__ == '__main__':
    main()
