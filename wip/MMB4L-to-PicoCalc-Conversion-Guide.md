# 🧭 MMB4L → PicoCalc Conversion Guide  
**Project:** Adventure Game Engine (`advplay.bas` → `engs.bas`)

---

## ⚙️ 1. Environment & Architecture Differences

| Topic | MMB4L | PicoMite (PicoCalc) | Key Takeaway |
|-------|--------|----------------------|---------------|
| **Heap Memory** | Generous (hundreds of KB–MB). | Limited (~60–90 KB usable). | Minimize arrays, strings, and locals. Declare all globally. |
| **Program Storage** | Loads from file instantly. | Runs from RAM; large files eat heap. | Strip comments and debug text. |
| **Speed** | Desktop CPU. | RP2040 microcontroller (133 MHz). | Avoid string-heavy loops. Pre-tokenize where possible. |

---

## 🧱 2. Language & Syntax Incompatibilities

| Issue | MMB4L Behavior | PicoMite Behavior | Fix Applied |
|--------|----------------|-------------------|-------------|
| **`TRIM$` function** | Built-in. | Not defined. | Added `TrimCopy$()` helper. |
| **Inline `IF … THEN … ELSE …`** | Fully supported. | One statement per line only. | Rewrote as multi-line `IF … ENDIF`. |
| **Function placement** | Can be called before defined. | Must be defined *before* use. | Moved all helper functions to top. |
| **Redefining built-ins** | Allowed. | Prohibited. | Renamed helpers (`TrimCopy$`, `Upper$`, etc.). |
| **Implicit variables** | Allowed by default. | Must be declared if `OPTION EXPLICIT`. | All variables declared globally. |
| **Case sensitivity** | Tolerant. | Stricter. | Standardized uppercase labels and function names. |

---

## 💾 3. Memory Management Challenges

| Symptom | Root Cause | Solution |
|----------|-------------|-----------|
| `Not enough Heap memory` | Large arrays (e.g., `DIM objects$(50,5)`). | Reduce `CAP_*` constants. Reuse arrays. |
| `... already declared` | Same variable declared in multiple scopes. | All DIMs moved global; no re-DIM in routines. |
| Heap fragmentation | Many transient strings in loops. | Reuse string variables (`s$`, `t$`, etc.). |

---

## 🧩 4. Functional Behavior Gaps

| Feature | Problem on Pico | Fix |
|----------|----------------|-----|
| **File reading** | Case-sensitive, no `.ADV` fallback. | Added `.ADV` extension auto-append. |
| **Conditional tags (`[[IF FLAG:…]]`)** | Displayed raw tags. | Added `RenderCond` parser. |
| **Object interaction (`TAKE/GET`)** | Exact-match string comparison failed. | Implemented fuzzy `INSTR(UCASE$())` matching. |
| **Verb parsing (`USE key on gate`)** | Multi-word parsing failed. | Rebuilt tokenization for “ON/WITH” patterns. |
| **Movement** | Inline IF caused “Unexpected text” errors. | Converted to block `IF ... ENDIF`. |

---

## 🧠 5. Development Workflow Lessons

| Stage | Problem | Solution |
|--------|----------|----------|
| **File Transfer (XMODEM)** | Corruption from macOS newlines. | Use `lsx -vv` / `lrx -vv` with picocom. |
| **Testing on PC only** | Hid Pico-specific syntax issues. | Always re-test final build on PicoCalc. |
| **Debug Printing** | Too memory-heavy. | Remove `[DEBUG]` logs post-testing. |
| **Incremental Fixing** | Tiny patches broke others. | Keep a “stable base” file and layer changes intentionally. |

---

## 🪶 6. Code Design Principles for PicoCalc

- **One global DIM block** — all arrays declared once at top.
- **Small, flat loops** — avoid deep nesting.
- **String reuse** — recycle variables instead of creating new ones.
- **Tight constants** — `CAP_ROOMS`, `CAP_OBJECTS`, etc., tuned to actual file size.
- **Single RETURN per subroutine** — prevents control flow confusion.

---

## 🧩 7. Known Limitations

- Adventure complexity limited by fixed `CAP_*` sizes.  
- No modular includes (`CHAIN` not supported).  
- No dynamic heap growth — all memory static.  
- No JSON or CSV parsing; use `|` as a delimiter.  
- Condition parser doesn’t yet support nested logic.

---

## 🧰 8. Stable Function Order (for PicoMite)

```
1. DIM declarations
2. Helper functions (TrimCopy$, DropStops$, FuzzyMatch$, HasFlag$, GetMsg$, etc.)
3. Loader routines (LoadAdv, ParseRoom, ParseObj, ParseResp)
4. Rendering (ShowRoom, RenderCond)
5. Parser & Command Handling (HandleCommand, FindResp)
6. Condition Engine (CheckConds$, EvalCond$)
7. Action Engine (DoAct, ActTake, ActDrop, etc.)
8. Movement (GoN, GoS, GoE, GoW)
9. Main Loop
```

This function order eliminates “Function not declared” and memory fragmentation errors.

---

## ✅ 9. Current Stable Behavior

- `run "engs3.bas"` loads any `.ADV` (e.g., `tiny_test.adv`).  
- Movement and conditionals behave as expected.  
- Fuzzy matching supports `TAKE`, `USE`, `ATTACK`, etc.  
- Memory footprint fits PicoCalc limits.  
- Tags like `[[IF FLAG:GATE_OPEN]]...[[END]]` render correctly.

---

### 🧩 Summary

The PicoMite build isn’t a straight port — it’s a **compact, heap-optimized rewrite**.  
Treat it as an embedded engine: every line must justify its memory cost.  

For best results:
- Keep `.adv` files tiny (≤ 40 rooms, ≤ 20 objects).  
- Avoid repeating long strings.  
- Comment out debug output before transferring to device.

---

**Maintained by:** Eric Harvey  
**Platform:** PicoCalc / PicoMite BASIC ≥ 5.07  
**Last Updated:** October 2025
