from PIL import Image
import os

ROOT = os.path.dirname(__file__)
SRC = os.path.join(ROOT, 'assets', '1x', 'Jokers.png')
OUT1 = os.path.join(ROOT, 'assets', '1x', 'Jokers_centered.png')
OUT2 = os.path.join(ROOT, 'assets', '2x', 'Jokers.png')

PX = 71
PY = 95

def center_cells():
    im = Image.open(SRC).convert('RGBA')
    w, h = im.size
    cols = w // PX
    rows = h // PY

    out = Image.new('RGBA', (w, h), (0,0,0,0))

    for r in range(rows):
        for c in range(cols):
            x0 = c * PX
            y0 = r * PY
            cell = im.crop((x0, y0, x0+PX, y0+PY))

            # find bbox of non-transparent pixels
            bbox = cell.getbbox()
            if bbox is None:
                # empty cell: paste as-is
                out.paste(cell, (x0, y0))
                continue

            # crop to content and center it in PXxPY
            content = cell.crop(bbox)
            cw, ch = content.size
            tx = x0 + (PX - cw)//2
            ty = y0 + (PY - ch)//2
            # paste content onto transparent PXxPY then into out
            canvas = Image.new('RGBA', (PX, PY), (0,0,0,0))
            canvas.paste(content, ((PX - cw)//2, (PY - ch)//2), content)
            out.paste(canvas, (x0, y0), canvas)

    out.save(OUT1)
    print('Saved centered 1x image to', OUT1)

    # Create 2x image (scale up)
    out2 = out.resize((w*2, h*2), Image.LANCZOS)

    # If a symlink exists at OUT2, remove it first
    try:
        if os.path.islink(OUT2) or os.path.exists(OUT2):
            os.remove(OUT2)
    except Exception as e:
        print('Warning removing existing 2x file:', e)

    out2.save(OUT2)
    print('Saved 2x image to', OUT2)

if __name__ == '__main__':
    center_cells()
