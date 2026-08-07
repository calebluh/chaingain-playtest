# Gridiron Deck: Franchise Edition - Art & Sound Asset Manifest

This document serves as your complete blueprint for replacing placeholder assets with your custom artwork and sound files. 

The game is designed to automatically detect when a file is placed in any of the paths below. If a file is missing, the engine seamlessly renders a crisp procedural placeholder in its place!

---

## 🎨 Image Assets (`assets/images/`)

All images should be transparent PNGs unless specified as full-rect backgrounds (e.g. stadium textures).

### 1. Play Cards (`assets/images/cards/`)
*Standard Card Aspect Ratio: 512 x 640 px (5:6 ratio)*

| File Name | Recommended Size | Description & Style Guidelines |
| :--- | :--- | :--- |
| `card_hb_dive.png` | 512 x 640 px | Power run down the middle, defensive line collision illustration |
| `card_hb_stretch.png` | 512 x 640 px | Outside run play, running back sweeping around the tackle |
| `card_inside_zone.png` | 512 x 640 px | Zone blocking scheme illustration, offensive linemen pushing |
| `card_quick_slant.png` | 512 x 640 px | Receiver cutting inside, quick pass trajectory |
| `card_drag_route.png` | 512 x 640 px | Receiver running across the field close to line of scrimmage |
| `card_mesh.png` | 512 x 640 px | Two receivers crossing paths over the middle |
| `card_dig_route.png` | 512 x 640 px | Intermediate cut in route, receiver making sharp turn |
| `card_out_route.png` | 512 x 640 px | Intermediate cut towards the sideline |
| `card_four_verticals.png` | 512 x 640 px | Deep routes, receivers streak upfield against cover 3/4 |
| `card_pa_crossers.png` | 512 x 640 px | Play action fake to RB with receivers crossing downfield |
| `card_hail_mary.png` | 512 x 640 px | Desperation deep pass into a crowded end zone |
| `card_flea_flicker.png` | 512 x 640 px | Trick play: toss to RB who pitches back to QB for deep pass |
| `card_screen_pass.png` | 512 x 640 px | Offensive linemen pulling out in front of RB for screen block |
| `card_field_goal.png` | 512 x 640 px | Kicker striking football through goalposts |

---

### 2. Player Roster Cards ("Jokers") (`assets/images/players/`)
*Portrait Card Aspect Ratio: 512 x 512 px (Square or Circle Portrait)*

| File Name | Recommended Size | Description |
| :--- | :--- | :--- |
| `player_qb_gunslinger.png` | 512 x 512 px | High-tech or heroic QB throwing deep pass |
| `player_qb_scrambler.png` | 512 x 512 px | Dynamic athletic QB running with the football |
| `player_qb_clutch.png` | 512 x 512 px | Calm, icy QB under pressure in late-game scenario |
| `player_rb_power.png` | 512 x 512 px | Muscular running back breaking tackles |
| `player_rb_speedster.png` | 512 x 512 px | Elusive running back in mid-sprint |
| `player_wr_deep_threat.png` | 512 x 512 px | Wide receiver catching ball overhead |
| `player_wr_slot_god.png` | 512 x 512 px | Agile wide receiver dodging defenders |
| `player_te_blocking.png` | 512 x 512 px | Massive tight end pancake blocking defensive end |
| `player_te_receiving.png` | 512 x 512 px | Versatile tight end catching ball in seam |
| `player_kicker_clutch.png` | 512 x 512 px | Focused kicker warming up leg |

---

### 3. Defensive Blinds (`assets/images/blinds/`)
*Icon Size: 256 x 256 px PNG (Transparent Badge)*

| File Name | Recommended Size | Description |
| :--- | :--- | :--- |
| `blind_standard.png` | 256 x 256 px | Standard defensive shield emblem |
| `blind_blitz.png` | 256 x 256 px | Aggressive lightning bolt / blitz skull icon |
| `blind_cover2.png` | 256 x 256 px | Dual safety defense zone icons |
| `blind_goal_line.png` | 256 x 256 px | Heavy wall / iron barrier icon |
| `blind_weather_rain.png` | 256 x 256 px | Storm cloud & rain drops icon |
| `blind_boss_championship.png` | 256 x 256 px | Gold trophy / crown defensive emblem |

---

### 4. Stadium Backgrounds (`assets/images/stadiums/`)
*Texture Size: 1920 x 1080 px*

| File Name | Recommended Size | Description |
| :--- | :--- | :--- |
| `stadium_default.png` | 1920 x 1080 px | Lush green gridiron field with yard lines |
| `stadium_snow.png` | 1920 x 1080 px | Frozen snow-covered field |
| `stadium_dome.png` | 1920 x 1080 px | Indoor turf dome stadium with bright floodlights |

---

### 5. UI Elements (`assets/images/ui/`)

| File Name | Recommended Size | Description |
| :--- | :--- | :--- |
| `ui_logo.png` | 1024 x 512 px | Main title logo: "GRIDIRON DECK" |
| `ui_cap_coin.png` | 128 x 128 px | Gold Cap Cash coin icon |
| `ui_audible_icon.png` | 128 x 128 px | Whistle / megaphone audible indicator |
| `ui_down_marker.png` | 128 x 128 px | Down marker sign icon |

---

## 🔊 Sound Assets (`assets/audio/`)

### 1. Sound Effects (`assets/audio/sfx/`)
*Format: 16-bit 44.1kHz WAV or OGG*

| File Name | Description |
| :--- | :--- |
| `whistle.ogg` | Referee whistle blow when play commences |
| `card_slide.ogg` | Card drawing / hovering sound |
| `tackle_impact.ogg` | Heavy tackle crunch on play execution |
| `touchdown_cheer.ogg` | Stadium crowd roar + horn on touchdown |
| `coin_drop.ogg` | Cash sound when earning Cap Cash |
| `button_click.ogg` | UI button click sound |

### 2. Music (`assets/audio/music/`)
*Format: OGG (Seamless Loop)*

| File Name | Description |
| :--- | :--- |
| `menu_theme.ogg` | High-energy sports anthem background track |
| `gameplay_theme.ogg` 
  Tense, rhythmic drum & synth loop during drive play |
| `shop_theme.ogg` | Smooth, relaxed front-office jazz/synth lounge loop |
 