"""Gera o ícone do jogo a partir do emblema, removendo o fundo quadriculado.

Uso:
    python tools/make_icon.py "D:\\caminho\\Emblema.png"

Saídas:
    assets/icon/icon.png    (512x512, transparência)
    assets/icon/app.ico     (16..256, transparência)
    installer/app.ico       (cópia para o Inno Setup)

O fundo é removido por preenchimento a partir das bordas, considerando apenas
pixels claros e neutros (o quadriculado é cinza/branco). O recorte é erodido em
meio pixel para evitar franja branca nas bordas.
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    r"D:\Meus Programas de PC\Jogos\Emblema Aventuras Bíblicas.png"
)
ICON_DIR = ROOT / "assets" / "icon"
ICO_SIZES = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]


def background_mask(image: Image.Image) -> Image.Image:
    """Retorna máscara L: 255 onde é fundo (quadriculado) conectado à borda."""
    width, height = image.size
    pixels = image.load()
    background = bytearray(width * height)
    stack: list[tuple[int, int]] = []

    def candidate(x: int, y: int) -> bool:
        r, g, b = pixels[x, y][:3]
        return min(r, g, b) >= 175 and max(r, g, b) - min(r, g, b) <= 14

    for x in range(width):
        for y in (0, height - 1):
            if candidate(x, y):
                stack.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if candidate(x, y):
                stack.append((x, y))

    while stack:
        x, y = stack.pop()
        index = y * width + x
        if background[index]:
            continue
        if not candidate(x, y):
            continue
        background[index] = 255
        if x > 0:
            stack.append((x - 1, y))
        if x + 1 < width:
            stack.append((x + 1, y))
        if y > 0:
            stack.append((x, y - 1))
        if y + 1 < height:
            stack.append((x, y + 1))

    mask = Image.frombytes("L", (width, height), bytes(background))
    return mask


def cut_out(image: Image.Image) -> Image.Image:
    mask = background_mask(image)
    # Fecha pequenos vazios do quadriculado que ficaram presos dentro de traços.
    mask = mask.filter(ImageFilter.MaxFilter(3))
    # Erode 1 px para dentro do emblema: remove a franja clara deixada pelo fundo.
    eroded = mask.filter(ImageFilter.MinFilter(5))
    alpha = Image.eval(eroded, lambda value: 255 - value)
    # Suaviza só a transição (meio pixel), sem reabrir o fundo.
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.6))
    result = image.convert("RGBA")
    result.putalpha(alpha)
    # Remove a cor branca residual dos pixels de borda, escurecendo a franja.
    data = result.load()
    width, height = result.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = data[x, y]
            if 0 < a < 255 and min(r, g, b) >= 190 and max(r, g, b) - min(r, g, b) <= 18:
                scale = a / 255.0
                data[x, y] = (
                    int(r * scale + 235 * (1.0 - scale) * 0.35),
                    int(g * scale + 226 * (1.0 - scale) * 0.35),
                    int(b * scale + 198 * (1.0 - scale) * 0.35),
                    a,
                )
    return result


def square(image: Image.Image, size: int, padding: float = 0.012) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError("A imagem ficou totalmente transparente; nada foi recortado.")
    content = image.crop(bbox)
    side = max(content.width, content.height)
    pad = int(round(side * padding))
    canvas = Image.new("RGBA", (side + pad * 2, side + pad * 2), (0, 0, 0, 0))
    canvas.paste(content, ((canvas.width - content.width) // 2, (canvas.height - content.height) // 2))
    return canvas.resize((size, size), Image.LANCZOS)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Emblema não encontrado: {SOURCE}")
    raw = Image.open(SOURCE).convert("RGBA")
    cut = cut_out(raw)
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    master = square(cut, 1024)
    master.save(ICON_DIR / "icon.png", optimize=True)

    ico_image = master.resize((256, 256), Image.LANCZOS)
    ico_image.save(
        ICON_DIR / "app.ico",
        format="ICO",
        sizes=[(size, size) for size in ICO_SIZES],
        bitmap_format="png",
    )
    shutil.copyfile(ICON_DIR / "app.ico", ROOT / "installer" / "app.ico")

    preview = ICON_DIR / "_preview.png"
    master.resize((512, 512), Image.LANCZOS).save(preview)
    print(f"master={master.size} -> {ICON_DIR / 'icon.png'}")
    print(f"ico={ICO_SIZES} -> {ICON_DIR / 'app.ico'}")
    print(f"preview={preview}")


if __name__ == "__main__":
    main()
