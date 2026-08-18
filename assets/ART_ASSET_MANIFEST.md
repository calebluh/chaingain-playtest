# ChainGain - Master Art & Sound Asset Blueprint

Welcome to the **ChainGain** master asset blueprint! This document is your complete catalog of every image, sprite, texture, and sound file used by the game engine.

The game features an **automatic asset pipeline**:
- **Point Filtering (`nearest`)**: All graphics are automatically rendered using crisp, pixel-perfect nearest-neighbor filtering (ideal for 16-bit retro pixel art!).
- **Seamless Fallbacks**: If any PNG or audio file is missing, the engine automatically renders procedural retro graphics or plays synthesized audio so the game never crashes.
- **Hot Syncing**: Drop any PNG into the designated folder path below, and the game will immediately pick it up on launch!

---

## 📁 Project Directory Structure

Place your custom art files in the `assets/` folder following this exact layout:

```text
ChainGain/
└── assets/
    ├── ART_ASSET_MANIFEST.md      <-- (This Document)
    ├── sprites/                   <-- Field animations, particles, spotlight & UI icons
    ├── templates/                 <-- Canvas reference guides for custom art creation
    └── images/
        ├── cards/                 <-- Playbook Card Artwork (512x640 or 114x90 px)
        ├── players/               <-- Player Bust Portraits (64x64 or 512x512 px)
        ├── blinds/                <-- Defensive Blind Badges (256x256 px)
        ├── stadiums/              <-- Field Background Textures (1920x1080 px)
        ├── ui/                    <-- Title Logo, Cap Cash Coin, Whistles, Indicators
        ├── consumables/           <-- Sideline Perk Badges (128x128 px)
        └── vouchers/              <-- Staff Upgrade Badges (128x128 px)
```

---

## 🎨 1. Field Animation Sprites (`assets/sprites/`)

All sprites should be transparent PNGs rendered in 16-bit retro pixel art style.

| Asset Filename | Recommended Size | Target Canvas | Description & Design Notes |
| :--- | :--- | :--- | :--- |
| `football.png` | 20 × 16 px | 20×16 | Classic brown pigskin with white laces and highlight reflection |
| `tackle_boom.png` | 32 × 32 px | 32×32 | High-impact comic starburst / collision hit graphic (yellow/orange) |
| `spotlight.png` | 64 × 128 px | 64×128 | Vertical conical overhead spotlight beam (white to transparent gradient) |
| `pedestal.png` | 48 × 16 px | 48×16 | Dark isometric oval floor disc / shadow platform for locker room spotlight |
| `turf_tile.png` | 32 × 32 px | 32×32 | Seamless alternating light/dark green grass stripe tile |
| `arrow_left.png` | 16 × 16 px | 16×16 | Retro green/cyan directional UI arrow pointing left |
| `arrow_right.png` | 16 × 16 px | 16×16 | Retro green/cyan directional UI arrow pointing right |
| `btn_a.png` | 24 × 24 px | 24×24 | Controller "A" / Enter button prompt badge (neon green border) |
| `btn_b.png` | 24 × 24 px | 24×24 | Controller "B" / Back button prompt badge (crimson red border) |
| `btn_lt.png` | 32 × 24 px | 32×24 | Controller "LT" shoulder trigger prompt badge (slate grey) |

---

## 🏈 2. Playbook Play Cards (`assets/images/cards/`)

*Aspect Ratio: 5:6 or 4:3 ratio (Recommended: 512×640 px hi-res OR 114×90 px pixel art)*  
All play cards feature dark background frames with vibrant neon play route diagrams.

| Asset Filename | Size | Description & Style Guidelines |
| :--- | :--- | :--- |
| `card_hb_dive.png` | 512 × 640 px | Power run through A-gap; RB diving through D-line collision |
| `card_hb_stretch.png` | 512 × 640 px | Outside sweep run; RB turning corner around block |
| `card_inside_zone.png` | 512 × 640 px | Zone blocking scheme; OL pushing D-line laterally |
| `card_quick_slant.png` | 512 × 640 px | Receiver sharp 45° cut inside over linebacker zone |
| `card_drag_route.png` | 512 × 640 px | Underneath crossing route right along the scrimmage line |
| `card_mesh.png` | 512 × 640 px | Dual crossing receivers creating a pick / mesh in short yardage |
| `card_dig_route.png` | 512 × 640 px | 10-yard vertical stem cutting 90° across the middle |
| `card_out_route.png` | 512 × 640 px | 10-yard vertical stem cutting 90° toward the sideline |
| `card_four_verticals.png` | 512 × 640 px | 4 receivers streaking deep upfield against Cover 3/4 |
| `card_pa_crossers.png` | 512 × 640 px | Play-action fake to RB with deep crossing routes downfield |
| `card_hail_mary.png` | 512 × 640 px | Desperation deep bomb into a crowded endzone pack |
| `card_flea_flicker.png` | 512 × 640 px | Trick play: pitch to RB who tosses back to QB for deep pass |
| `card_screen_pass.png` | 512 × 640 px | OL pulling in front of RB catching short pass behind LOS |
| `card_field_goal.png` | 512 × 640 px | Kicker launching football high through yellow uprights |

---

## 👤 3. Player Roster Cards ("Jokers") (`assets/images/players/`)

*Aspect Ratio: Square (Recommended: 64×64 px pixel art OR 512×512 px)*  
These images represent specific named players or archetype templates on player cards and in roster displays.

| Asset Filename | Recommended Size | Description |
| :--- | :--- | :--- |
| `player_marcus_vance.png` | 64 × 64 px | Pixel bust portrait: Star QB with navy helmet & clear visor |
| `player_jalen_carter.png` | 64 × 64 px | Pixel bust portrait: Star DL with red helmet & dark visor |
| `player_qb_gunslinger.png` | 512 × 512 px | Gunslinger QB throwing deep bomb with electric aura |
| `player_qb_scrambler.png` | 512 × 512 px | Athletic dual-threat QB dodging defenders in open field |
| `player_qb_clutch.png` | 512 × 512 px | Ice-cold QB calling audibles under late-game pressure |
| `player_rb_power.png` | 512 × 512 px | Bruising power back breaking tackles in the trench |
| `player_rb_speedster.png` | 512 × 512 px | Speedster running back sprinting down the sideline |
| `player_wr_deep_threat.png` | 512 × 512 px | High-flying receiver making toe-tap catch overhead |
| `player_wr_slot_god.png` | 512 × 512 px | Agile slot receiver making quick cut in traffic |
| `player_te_blocking.png` | 512 × 512 px | Massive tight end pancake-blocking defensive end |
| `player_te_receiving.png` | 512 × 512 px | Flex tight end catching seam pass over linebackers |
| `player_kicker_clutch.png` | 512 × 512 px | Focused kicker lining up game-winning kick |

---

## 🛡️ 4. Defensive Blinds (`assets/images/blinds/`)

*Icon Size: 256 × 256 px PNG (Transparent Shield Badge)*

| Asset Filename | Recommended Size | Description |
| :--- | :--- | :--- |
| `blind_standard.png` | 256 × 256 px | Classic blue defensive shield emblem |
| `blind_blitz.png` | 256 × 256 px | Red aggressive skull & lightning bolt blitz badge |
| `blind_cover2.png` | 256 × 256 px | Cyan dual-safety coverage shield |
| `blind_goal_line.png` | 256 × 256 px | Heavy iron wall / goal-line barrier badge |
| `blind_weather_rain.png` | 256 × 256 px | Dark storm cloud with rain & wind indicators |
| `blind_boss_championship.png` | 256 × 256 px | Gold trophy & crown championship boss emblem |

---

## 🏟️ 5. Stadium Environments (`assets/images/stadiums/`)

*Texture Resolution: 1920 × 1080 px*

| Asset Filename | Recommended Size | Description |
| :--- | :--- | :--- |
| `stadium_default.png` | 1920 × 1080 px | Classic outdoor grass field with yard lines & stadium lights |
| `stadium_snow.png` | 1920 × 1080 px | Frozen snow-covered field with icy yard markers & snow flurries |
| `stadium_dome.png` | 1920 × 1080 px | High-tech indoor turf dome stadium under bright LED spotlights |

---

## 🎮 6. UI & HUD Elements (`assets/images/ui/`)

| Asset Filename | Recommended Size | Description |
| :--- | :--- | :--- |
| `ui_logo.png` | 1024 × 512 px | Main title logo: "CHAIN GAIN" |
| `ui_cap_coin.png` | 128 × 128 px | Gold Cap Cash currency coin icon |
| `ui_audible_icon.png` | 128 × 128 px | Whistle / megaphone audible indicator |
| `ui_down_marker.png` | 128 × 128 px | First down marker sign icon |

---

## 🔊 7. Audio Assets (`assets/audio/`)

### Sound Effects (`assets/audio/sfx/`) — *Format: 16-bit 44.1kHz OGG / WAV*

| Asset Filename | Description |
| :--- | :--- |
| `whistle.ogg` | Sharp referee whistle blow when play starts |
| `card_slide.ogg` | Clean card draw / hover sound |
| `tackle_impact.ogg` | Heavy pad-crunch tackle impact sound |
| `touchdown_cheer.ogg` | Stadium crowd cheer + horn on scoring |
| `coin_drop.ogg` | Cash register sound when earning Cap Cash |
| `button_click.ogg` | Crisp UI button click |

### Music Loops (`assets/audio/music/`) — *Format: OGG (Seamless Loop)*

| Asset Filename | Description |
| :--- | :--- |
| `menu_theme.ogg` | High-energy retro sports anthem background track |
| `gameplay_theme.ogg` | Tense, rhythmic drum & synth loop during football drives |
| `shop_theme.ogg` | Smooth front-office synth lounge loop |

---

## 🛠️ 8. Template Reference Directory (`assets/templates/`)

For artists creating custom player assets, the `assets/templates/` directory provides base template PNG files and grid guides:
- `template_player_bust.png` (64×64 px pixel grid guide for character heads/helmets)
- `template_card_frame.png` (512×640 px card frame boundary template)
- `template_sprite_sheet.png` (128×128 px grid canvas for character animations)