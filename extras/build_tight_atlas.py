from PIL import Image
import os

ROOT = os.path.dirname(__file__)
SRC = os.path.join(ROOT, 'assets', '1x', 'Jokers.png')
OUT1 = os.path.join(ROOT, 'assets', '1x', 'Jokers_tight.png')
OUT2 = os.path.join(ROOT, 'assets', '2x', 'Jokers.png')

PX_OLD = 71
PY_OLD = 95

def build_tight_atlas():
    im = Image.open(SRC).convert('RGBA')
    w, h = im.size
    cols = w // PX_OLD
    rows = h // PY_OLD

    # Extract sprites with their content bboxes
    sprites = []
    for r in range(rows):
        for c in range(cols):
            x0, y0 = c * PX_OLD, r * PY_OLD
            cell = im.crop((x0, y0, x0+PX_OLD, y0+PY_OLD))
            bbox = cell.getbbox()
            if bbox:
                content = cell.crop(bbox)
                sprites.append({
                    'index': (c, r),
                    'content': content,
                    'size': content.size,
                    'bbox': bbox
                })

    # Arrange sprites in a single row for simplicity
    total_w = sum(s['size'][0] for s in sprites) + (len(sprites) - 1) * 2
    max_h = max(s['size'][1] for s in sprites)
    
    tight = Image.new('RGBA', (total_w, max_h), (0,0,0,0))
    
    x_offset = 0
    pos_map = {}
    for sp in sprites:
        idx = sp['index']
        tight.paste(sp['content'], (x_offset, 0), sp['content'])
        pos_map[idx] = (x_offset, 0)
        x_offset += sp['size'][0] + 2
    
    tight.save(OUT1)
    print(f'Saved tight 1x atlas to {OUT1}')
    print(f'Tight atlas size: {tight.size}')
    print(f'Sprite positions:')
    for idx in sorted(pos_map.keys()):
        print(f'  Cell {idx}: pos {pos_map[idx]}')
    
    # Create 2x version
    tight2 = tight.resize((tight.size[0]*2, tight.size[1]*2), Image.LANCZOS)
    
    try:
        if os.path.islink(OUT2) or os.path.exists(OUT2):
            os.remove(OUT2)
    except Exception as e:
        print('Warning removing existing 2x file:', e)
    
    tight2.save(OUT2)
    print(f'Saved 2x atlas to {OUT2} (size: {tight2.size})')
    
    # Return position map for Lua config
    return pos_map, tight.size, tight2.size

if __name__ == '__main__':
    pos_map, size1x, size2x = build_tight_atlas()
