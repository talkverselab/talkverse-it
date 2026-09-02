"""앱 아이콘 생성 — icon_full.png(1024, 불투명) + icon_foreground.png(1024, adaptive 전경).

python assets/characters/make_icon.py && dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).parent
S = 1024
ROJO, ROJO_LIGHT, ROJO_DEEP = (0xAA, 0x15, 0x1B), (0xD9, 0x41, 0x3F), (0x6E, 0x0C, 0x10)
GUALDA, GUALDA_BRIGHT = (0xF1, 0xBF, 0x00), (0xFF, 0xD8, 0x4D)
WHITE = (0xFB, 0xF5, 0xE6)


def radial_bg():
    img = Image.new("RGB", (S, S), ROJO)
    px = img.load()
    cx, cy, r = S * 0.5, S * 0.4, S * 0.75
    for y in range(S):
        for x in range(S):
            d = min(((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r, 1.0)
            if d < 0.6:
                t = d / 0.6
                a, b = ROJO_LIGHT, ROJO
            else:
                t = (d - 0.6) / 0.4
                a, b = ROJO, ROJO_DEEP
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return img


def font(size):
    for name in ("segoeuib.ttf", "arialbd.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_content(draw: ImageDraw.ImageDraw, scale=1.0):
    """가운데 Ñ + 아래 금색 띠. scale<1 이면 adaptive safe zone 용 축소."""
    c = S / 2
    # 금색 띠 (국기 가운데 띠 느낌)
    band_h = 70 * scale
    band_y = c + 290 * scale
    half_w = 330 * scale
    draw.rounded_rectangle(
        [c - half_w, band_y - band_h / 2, c + half_w, band_y + band_h / 2],
        radius=band_h / 2, fill=GUALDA)
    # Ñ
    f = font(int(620 * scale))
    text = "Ñ"
    bbox = draw.textbbox((0, 0), text, font=f)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = c - w / 2 - bbox[0]
    y = c - h / 2 - bbox[1] - 40 * scale
    # 그림자
    draw.text((x + 12 * scale, y + 14 * scale), text, font=f, fill=ROJO_DEEP)
    # 금색 테두리
    draw.text((x, y), text, font=f, fill=WHITE, stroke_width=int(14 * scale), stroke_fill=GUALDA_BRIGHT)


def main():
    full = radial_bg().convert("RGBA")
    draw_content(ImageDraw.Draw(full))
    full.convert("RGB").save(OUT / "icon_full.png")

    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_content(ImageDraw.Draw(fg), scale=0.66)  # adaptive safe zone (~66%)
    fg.save(OUT / "icon_foreground.png")
    print("ok:", OUT / "icon_full.png", OUT / "icon_foreground.png")


if __name__ == "__main__":
    main()
