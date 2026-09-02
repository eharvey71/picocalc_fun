# picocalc_fun — platform notes

Retro projects in MMBasic for the **ClockworkPi PicoCalc**.

## Target hardware (verified from `OPTION LIST` on the actual device)

- **Firmware:** PicoMite MMBasic **RP2040 Edition V6.00.02RC23**
- **Core:** Raspberry Pi Pico 1 H — RP2040, dual Cortex-M0+, **264 KB SRAM**, 2 MB flash
- **CPU speed:** `OPTION CPUSPEED 200000` → **200 MHz** (this is PicoMite 6.x's *default* for RP2040, not an overclock)
- **Display:** `ILI9488P`, **PORTRAIT**, GP14/GP15/GP13, `;INVERT` → **320 × 320**
- **Console:** `OPTION DISPLAY 26,40` → **26 lines × 40 chars** (font 1 = 8 × 12 px; 40×8=320, 26×12=312)
- **Keyboard:** `OPTION KEYBOARD I2C` — PicoCalc's STM32 matrix keyboard on system I2C (GP6/GP7, SLOW)
- **Audio:** `OPTION AUDIO GP26,GP27, ON PWM CHANNEL` — PWM audio, `PLAY TONE freq, duration_ms, volume`
- **SD card:** GP17, GP18, GP19, GP16
- **System SPI:** GP10, GP11, GP12 · **Serial console:** COM1, GP0/GP1
- **Platform:** `OPTION PLATFORM PicoCalc` (auto-configured by 6.x firmware on a blank Pico)
- Default colours GREEN on BLACK; `OPTION COLOURCODE ON`

## Language facts — verified against the PicoMite manual and firmware source

Verified against the **6.03.x** manual + `UKTailwind/PicoMite` source. The device runs **6.00.02RC23**,
three point releases behind, so items marked ⚠️ are worth a one-line check at the `>` prompt.

| Fact | Status |
|---|---|
| `IF cond THEN action ELSE action` on one line | **Supported.** Single-line IF is documented and normal. |
| Multi-line `IF … ELSEIF … ELSE … ENDIF` | Supported; each component on its own line. |
| SUB/FUNCTION definition order | **Irrelevant.** "The definition of a subroutine can be anywhere in the program." |
| `Trim$(s$ [,mask$] [,"L"\|"R"\|"B"])` | Built-in in 6.03.x source (`fun_trim`). ⚠️ Confirm on 6.00.02: `? Trim$("  x  ")` |
| Default string allocation | **255 bytes per element.** Use `DIM a$(n) LENGTH m` (m = 1–255) to cut array cost. |
| Max string length | 255 chars. Use LONGSTRING for more. |
| Max program line | 255 chars. |
| `OPTION BASE` | Defaults to **0**; must be set before any `DIM`. |

### Corrections to `wip/MMB4L-to-PicoCalc-Conversion-Guide.md`

That guide is from Oct 2025 and predates this firmware. Three claims in it are **wrong for 6.00.02**:

1. "Inline `IF … THEN … ELSE …`: one statement per line only" — single-line IF/ELSE works.
2. "Functions must be defined before use" — they can be anywhere in the program.
3. "133 MHz" — the RP2040 default in 6.x is 200 MHz, and this unit is set to 200 MHz.

The guide's `TrimCopy$`/`Upper$` helpers and its heap-discipline advice are still sound;
the memory pressure is real, just not for the reasons listed.

## Memory

264 KB SRAM total, but MMBasic's variable heap is a fraction of that. Don't guess — measure:

- `MEMORY` — program / saved-variable / RAM breakdown
- `MM.INFO(HEAP)`, `MM.INFO(CHEAPTOTAL)`, `MM.INFO(CHEAPMAX)`, `MM.INFO(SYSTEM HEAP)`
- `MM.INFO(STACK)`, `MM.INFO(STACKPEAK)`, `MM.INFO(MAX VARS)`, `MM.INFO(VARCNT)`

**The one rule that matters:** a string array without `LENGTH` costs 256 bytes per element.
`DIM x$(50,5)` is 51×6×256 ≈ **78 KB**. Always add `LENGTH`.

## PicoCalc-only MMBasic extensions

- `MM.INFO(BATTERY)` — battery level
- `MM.INFO(CHARGING)` — charging status
- `MM.INFO(BIOS)` — keyboard/BIOS firmware version
- `OPTION BACKLIGHT LCD n` — display backlight, 0–100%
- `OPTION BACKLIGHT KBD n` — keyboard backlight, 0–100%

These need PicoCalc keyboard firmware **≥ 1.4**; older keyboard firmware also causes
I2C keyboard disconnect errors.

## Repo layout

| Path | What |
|---|---|
| `castle_dungeon/castledgn.bas` | Complete graphical maze game. The reference for this repo's graphics/audio idiom. |
| `tiny-adv-maker/advplay-pico.bas` | Text-adventure engine, PicoMite build (heap-tuned, `LENGTH` everywhere). |
| `tiny-adv-maker/advplay-mmbasic.bas` | Older MMB4L desktop build. Diverged; not maintained in step. |
| `tiny-adv-maker/advcreate.bas` | Adventure authoring tool. **Still uses MMB4L-sized DIMs — will not fit RP2040 heap.** |
| `tiny-adv-maker/*.adv` | Pipe-delimited adventure data. Sections: SETTINGS, ROOMS, OBJECTS, VOCABULARY, RESPONSES, MESSAGES. |
| `wip/` | Prototypes + notes. `starfield.bas` complete; `wumpus.bas` is a stub (no hazard detection). |
| `pico_serial_xmodem.md` | macOS picocom + XMODEM transfer workflow. |

## Coding conventions in this repo

- `OPTION DEFAULT INTEGER` at the top; `OPTION EXPLICIT` in newer files (`wip/wumpus.bas`).
- Screen geometry from `MM.HRES` / `MM.VRES`, not hardcoded, where practical.
- Graphics: `BOX`, `TEXT x, y, s$, "LT"|"CM", font, scale, RGB(...)`.
- Input: `INKEY$` polled in a `DO WHILE` loop, with a drain loop (`DO WHILE INKEY$ <> "" : LOOP`)
  after handling a key to swallow repeats.
- `castledgn.bas` uses labels + `GOSUB`; `wumpus.bas` uses `SUB`. Both are fine — match the file.
- One global `DIM` block at the top; no re-`DIM` inside routines.

## Getting code onto the device

See `pico_serial_xmodem.md` — `picocom` + `lsx`/`lrx` over serial. On the device:
`XMODEM RECEIVE "file.bas"`. Strip debug `PRINT`s before transferring; they cost heap.

## Testing

There is no emulator or CI here. **Nothing in this repo can be run or verified in a dev
environment** — every change must be transferred to the PicoCalc and run there. When
proposing changes, say plainly what was reasoned about versus what was actually run.
