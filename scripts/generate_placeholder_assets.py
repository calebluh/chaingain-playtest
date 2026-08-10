from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import random

root = Path(__file__).resolve().parents[1]
assets = root / "assets"

FONT_PATHS = [
    "C:/Windows/Fonts/arialbd.ttf",
    "C:/Windows/Fonts/calibri.ttf",
    "C:/Windows/Fonts/consola.ttf",
    "C:/Windows/Fonts/tahoma.ttf",
]


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_PATHS:
        p = Path(path)
        if p.exists():
            return ImageFont.truetype(str(p), size=size)
    return ImageFont.load_default()


def grain(img: Image.Image, amount: int = 250) -> Image.Image:
    px = img.load()
    w, h = img.size
    for _ in range(amount):
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, min(255, a + random.randint(8, 28)))
    return img


def save_png(path: Path, img: Image.Image):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def card_template(path: Path, label: str, accent=(0, 204, 255), tint=(24, 54, 103)):
    img = Image.new("RGBA", (512, 640), (18, 22, 30, 255))
    d = ImageDraw.Draw(img)

    d.rounded_rectangle((18, 18, 494, 622), radius=28, fill=(16, 20, 28, 255), outline=accent, width=6)
    d.rounded_rectangle((32, 32, 480, 80), radius=12, fill=accent, outline=(255, 255, 255, 120), width=2)
    d.rounded_rectangle((42, 98, 470, 570), radius=18, fill=(20, 24, 32, 255), outline=(255, 255, 255, 60), width=2)

    # subtle background strips
    for i in range(0, 500, 38):
        d.line((i + 8, 104, i + 28, 156), fill=(255, 255, 255, 18), width=2)
    d.line((54, 140, 458, 140), fill=(255, 255, 255, 35), width=2)

    # central emblem
    d.line((256, 200, 256, 386), fill=accent, width=8)
    d.ellipse((184, 148, 328, 282), outline=accent, width=6)
    d.line((170, 300, 342, 300), fill=accent, width=8)

    # bottom info bar
    d.rounded_rectangle((46, 532, 466, 592), radius=14, fill=(8, 10, 16, 220), outline=(255, 255, 255, 90), width=2)
    d.rounded_rectangle((54, 540, 186, 584), radius=10, fill=(18, 90, 150, 220), outline=(255, 255, 255, 100), width=2)
    d.rounded_rectangle((326, 540, 454, 584), radius=10, fill=(170, 50, 50, 220), outline=(255, 255, 255, 100), width=2)

    d.text((256, 56), label.upper(), fill=(255, 255, 255, 240), anchor="mm", font=load_font(24))
    d.text((256, 430), "TEMPLATE", fill=accent, anchor="mm", font=load_font(30))
    d.text((256, 560), "PLAY", fill=(255, 255, 255, 190), anchor="mm", font=load_font(18))
    d.text((120, 562), "YDS", fill=(255, 255, 255, 220), anchor="mm", font=load_font(18))
    d.text((390, 562), "MTM", fill=(255, 255, 255, 220), anchor="mm", font=load_font(18))

    img = grain(img, amount=220)
    save_png(path, img)


def player_template(path: Path, name: str, primary=(28, 92, 170), accent=(240, 214, 90)):
    img = Image.new("RGBA", (512, 512), (18, 22, 30, 255))
    d = ImageDraw.Draw(img)

    d.rounded_rectangle((18, 18, 494, 494), radius=28, fill=(28, 36, 45, 255), outline=accent, width=6)
    d.rounded_rectangle((34, 34, 478, 478), radius=18, fill=(18, 24, 32, 255), outline=(255, 255, 255, 55), width=2)

    d.ellipse((150, 100, 362, 228), fill=(220, 182, 135, 255), outline=(0, 0, 0, 120), width=4)
    d.rounded_rectangle((120, 242, 392, 400), radius=26, fill=primary, outline=(0, 0, 0, 120), width=4)
    d.rounded_rectangle((188, 184, 324, 240), radius=10, fill=accent, outline=(0, 0, 0, 120), width=2)
    d.rounded_rectangle((188, 292, 324, 350), radius=12, fill=(12, 15, 20, 255), outline=(255, 255, 255, 80), width=2)
    d.rounded_rectangle((120, 398, 390, 462), radius=18, fill=(20, 24, 28, 255), outline=(0, 0, 0, 120), width=3)

    d.ellipse((120, 72, 392, 200), fill=(25, 30, 38, 255), outline=(255, 255, 255, 80), width=3)
    d.rounded_rectangle((188, 142, 324, 176), radius=8, fill=(130, 200, 255, 150), outline=(255, 255, 255, 70), width=2)
    d.rounded_rectangle((74, 416, 438, 472), radius=10, fill=(10, 14, 18, 230), outline=(255, 255, 255, 80), width=2)

    d.text((256, 444), name.upper(), fill=(255, 255, 255, 220), anchor="mm", font=load_font(24))
    img = grain(img, amount=180)
    save_png(path, img)


def blind_template(path: Path, label: str, accent=(232, 128, 68), fill=(28, 20, 30)):
    img = Image.new("RGBA", (256, 256), (18, 22, 30, 255))
    d = ImageDraw.Draw(img)

    d.ellipse((12, 12, 244, 244), fill=fill, outline=accent, width=8)
    d.polygon([(128, 28), (220, 128), (128, 228), (36, 128)], fill=accent, outline=(255, 255, 255, 120), width=4)
    d.ellipse((82, 82, 174, 174), fill=(255, 255, 255, 35), outline=(255, 255, 255, 90), width=3)
    d.text((128, 128), label[:2].upper(), fill=(255, 255, 255, 220), anchor="mm", font=load_font(28))
    save_png(path, img)


def ui_template(path: Path, label: str, kind: str):
    if kind == "logo":
        img = Image.new("RGBA", (1024, 512), (18, 22, 30, 255))
        d = ImageDraw.Draw(img)
        d.rounded_rectangle((30, 30, 994, 482), radius=24, fill=(18, 22, 30, 255), outline=(0, 204, 255, 255), width=6)
        d.rounded_rectangle((80, 100, 944, 334), radius=18, fill=(0, 204, 255, 220), outline=(255, 255, 255, 80), width=2)
        d.text((512, 256), label.upper(), fill=(255, 255, 255, 245), anchor="mm", font=load_font(86))
    else:
        size = (128, 128)
        img = Image.new("RGBA", size, (18, 22, 30, 255))
        d = ImageDraw.Draw(img)
        d.rounded_rectangle((12, 12, 116, 116), radius=22, fill=(18, 22, 30, 255), outline=(0, 204, 255, 255), width=6)
        d.ellipse((28, 28, 100, 100), fill=(0, 204, 255, 180), outline=(255, 255, 255, 90), width=4)
        d.text((64, 64), label[:2].upper(), fill=(255, 255, 255, 230), anchor="mm", font=load_font(32))
    save_png(path, img)


def stadium_template(path: Path, name: str):
    w, h = 1920, 1080
    img = Image.new("RGBA", (w, h), (110, 168, 78, 255))
    d = ImageDraw.Draw(img)

    for x in range(0, w, 120):
        d.rectangle((x, 0, x + 60, h), fill=(83, 142, 62, 255))
    for x in range(120, w - 120, 120):
        for y in range(0, h, 20):
            d.rectangle((x, y, x + 4, y + 10), fill=(255, 255, 255, 120))

    d.rectangle((0, 0, 120, h), fill=(25, 52, 95, 255))
    d.rectangle((w - 120, 0, w, h), fill=(175, 38, 38, 255))
    for y in range(0, 120, 16):
        d.rectangle((0, y, w, y + 8), fill=(20, 20, 20, 80))

    d.text((w // 2, 40), name.upper(), fill=(255, 255, 255, 180), anchor="ma", font=load_font(54))
    if name == "stadium_snow":
        for _ in range(1200):
            x = random.randint(0, w - 1)
            y = random.randint(0, h - 1)
            d.point((x, y), fill=(255, 255, 255, random.randint(60, 140)))
    elif name == "stadium_dome":
        for i in range(0, w, 60):
            d.rectangle((i, 0, i + 30, 150), fill=(255, 255, 255, 30))
    img = img.filter(ImageFilter.GaussianBlur(0.2))
    save_png(path, img)


def badge_template(path: Path, label: str):
    img = Image.new("RGBA", (256, 256), (18, 22, 30, 255))
    d = ImageDraw.Draw(img)
    d.ellipse((12, 12, 244, 244), fill=(22, 28, 38, 255), outline=(0, 204, 255, 255), width=4)
    d.ellipse((48, 48, 208, 208), fill=(0, 204, 255, 100), outline=(255, 255, 255, 110), width=4)
    d.text((128, 128), label[:2].upper(), fill=(255, 255, 255, 220), anchor="mm", font=load_font(36))
    save_png(path, img)


def generic_icon(path: Path, label: str):
    img = Image.new("RGBA", (256, 256), (18, 22, 30, 255))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((12, 12, 244, 244), radius=26, fill=(18, 22, 30, 255), outline=(0, 204, 255, 255), width=4)
    d.ellipse((50, 50, 206, 206), fill=(0, 204, 255, 120), outline=(255, 255, 255, 130), width=4)
    d.text((128, 128), label[:2].upper(), fill=(255, 255, 255, 220), anchor="mm", font=load_font(36))
    save_png(path, img)


# Cards
card_names = [
    "card_hb_dive", "card_hb_stretch", "card_inside_zone", "card_quick_slant", "card_drag_route",
    "card_mesh", "card_dig_route", "card_out_route", "card_four_verticals", "card_pa_crossers",
    "card_hail_mary", "card_flea_flicker", "card_screen_pass", "card_field_goal",
]
for name in card_names:
    label = name.replace("card_", "").replace("_", " ").title()
    card_template(assets / "images" / "cards" / f"{name}.png", label[:3])
    card_template(assets / "2x" / "cards" / f"{name}.png", label[:3])

# Players
player_names = [
    "player_qb_gunslinger", "player_qb_scrambler", "player_qb_clutch", "player_rb_power", "player_rb_speedster",
    "player_wr_deep_threat", "player_wr_slot_god", "player_te_blocking", "player_te_receiving", "player_kicker_clutch",
]
for name in player_names:
    label = name.replace("player_", "").replace("_", " ").title().split()[-1][:8]
    primary = (24, 76, 136) if "qb" in name or "wr" in name else (70, 112, 60)
    player_template(assets / "images" / "players" / f"{name}.png", label, primary)
    player_template(assets / "2x" / "players" / f"{name}.png", label, primary)

# Blinds
blind_names = [
    "blind_standard", "blind_blitz", "blind_cover2", "blind_goal_line", "blind_weather_rain", "blind_boss_championship",
]
for name in blind_names:
    label = name.replace("blind_", "").replace("_", " ")[:2].upper()
    accent = (232, 128, 68) if "boss" not in name else (255, 214, 92)
    fill = (28, 20, 30) if "boss" not in name else (50, 38, 20)
    blind_template(assets / "images" / "blinds" / f"{name}.png", label, accent, fill)
    blind_template(assets / "2x" / "blinds" / f"{name}.png", label, accent, fill)

# UI
ui_names = [
    "ui_logo", "ui_cap_coin", "ui_audible_icon", "ui_down_marker",
]
for name in ui_names:
    kind = "logo" if name == "ui_logo" else "icon"
    label = name.replace("ui_", "").replace("_", " ").upper()
    ui_template(assets / "images" / "ui" / f"{name}.png", label, kind)
    ui_template(assets / "2x" / "ui" / f"{name}.png", label, kind)

# Stadiums
for stadium_name in ["stadium_default", "stadium_snow", "stadium_dome"]:
    stadium_template(assets / "images" / "stadiums" / f"{stadium_name}.png", stadium_name)
    stadium_template(assets / "2x" / "stadiums" / f"{stadium_name}.png", stadium_name)

# Extra categories
badge_names = [
    "badge_sticky_gloves", "badge_speed_cleats", "badge_pancake_block", "badge_captains_badge",
]
for name in badge_names:
    label = name.replace("badge_", "").replace("_", " ").title()[:2].upper()
    badge_template(assets / "images" / "badges" / f"{name}.png", label)
    badge_template(assets / "2x" / "badges" / f"{name}.png", label)

vouch_names = [
    "voucher_analytics_dept", "voucher_salary_cap_inflation", "voucher_no_huddle_master",
    "voucher_scouting_network", "voucher_booster_budget", "voucher_audible_overdrive",
    "voucher_red_zone_specialist", "voucher_veteran_leadership", "voucher_franchise_tag",
    "voucher_clutch_kicker", "voucher_halftime_adjuster", "voucher_dynasty_mode",
]
for name in vouch_names:
    label = name.replace("voucher_", "").replace("_", " ").title()[:2].upper()
    generic_icon(assets / "images" / "vouchers" / f"{name}.png", label)
    generic_icon(assets / "2x" / "vouchers" / f"{name}.png", label)

cons_names = [
    "consumable_bribe_ref", "consumable_no_huddle", "consumable_sticky_gloves", "consumable_audible_overdrive",
    "consumable_red_zone_special", "consumable_enhancement_glass", "consumable_enhancement_steel",
    "consumable_enhancement_gold", "consumable_enhancement_stone", "consumable_seal_red",
    "consumable_seal_gold", "consumable_seal_blue",
]
for name in cons_names:
    label = name.replace("consumable_", "").replace("_", " ").title()[:2].upper()
    generic_icon(assets / "images" / "consumables" / f"{name}.png", label)
    generic_icon(assets / "2x" / "consumables" / f"{name}.png", label)

tag_names = ["tag_economy", "tag_arcana", "tag_voucher", "tag_scout"]
for name in tag_names:
    label = name.replace("tag_", "").replace("_", " ").title()[:2].upper()
    generic_icon(assets / "images" / "tags" / f"{name}.png", label)
    generic_icon(assets / "2x" / "tags" / f"{name}.png", label)

print("Generated placeholder asset set in", assets)
print("Counts:")
for rel in [
    "images/cards", "images/players", "images/blinds", "images/ui", "images/stadiums",
    "images/badges", "images/vouchers", "images/consumables", "images/tags",
]:
    folder = assets / rel
    print(f"- {rel}: {len(list(folder.glob('*.png')))}")
