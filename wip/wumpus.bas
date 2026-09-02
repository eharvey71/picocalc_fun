' ============================================================================
'  HUNT THE WUMPUS  --  PicoCalc / PicoMite MMBasic
'
'  Modelled on the Texas Instruments TI-99/4A Solid State Cartridge (1980).
'  Rules taken from the original module manual:
'
'    - A maze of caverns joined by long twisting tunnels.  The screen wraps
'      around both horizontally and vertically.
'    - EASY / HARD / PRO mazes hold about 32 / 24 / 16 caverns.  Fewer
'      caverns means longer tunnels between them.
'    - Bloodspots (a red dot) appear in every cavern within TWO caverns of
'      the Wumpus.
'    - Green cavern walls appear within ONE cavern of a slime pit.  There
'      are two slime pits.  Entering one loses the game.
'    - Tunnels carry no warnings at all.
'    - Bats ignore you the first time.  Re-enter and they may carry you off
'      anywhere - a cavern, a tunnel, a pit, or the Wumpus' lair - then they
'      move house.
'    - ONE arrow.  Fire it into a tunnel from a cavern or a tunnel.  Hit the
'      Wumpus and you win; miss and the Wumpus gets you.  There is no second
'      shot.
'
'  Controls:  arrow keys move.  Q arms the arrow (Q again cancels), then an
'  arrow key fires it.  ESC quits.
'
'  NOTE: never run or tested off-device.  Written against PicoMite MMBasic
'  6.x on a 320x320 PicoCalc.
' ============================================================================

OPTION EXPLICIT
OPTION DEFAULT INTEGER

' ---- maze lattice -----------------------------------------------------------
CONST COLS  = 8
CONST ROWS  = 6
CONST NSLOT = 48
CONST CELL  = 40
CONST MAPH  = 240
CONST CAVR  = 13

' ---- directions -------------------------------------------------------------
CONST DUP = 0
CONST DDN = 1
CONST DLF = 2
CONST DRT = 3

' ---- key codes (PicoMite special keys) --------------------------------------
CONST KUP  = 128
CONST KDN  = 129
CONST KLF  = 130
CONST KRT  = 131
CONST KESC = 27

' ---- outcomes ---------------------------------------------------------------
CONST OUT_WIN  = 1
CONST OUT_WUMP = 2
CONST OUT_PIT  = 3
CONST OUT_QUIT = 4

' ---- maze -------------------------------------------------------------------
DIM cav(47)              ' 1 = this lattice slot holds a cavern
DIM link(47, 3)          ' cavern reached by leaving in direction d, -1 = rock
DIM tlen(47, 3)          ' length of that tunnel, in moves
DIM tseen(47, 3)         ' 1 = the hunter has walked this tunnel
DIM blood(47)            ' 1 = bloodspot (within two caverns of the Wumpus)
DIM slime(47)            ' 1 = green walls (within one cavern of a pit)
DIM seen(47)             ' 1 = the hunter has been here
DIM batAt(47)            ' 1 = bats live here
DIM batSeen(47)          ' 1 = the hunter has seen these bats
DIM q(47)                ' scratch queue, also used to collect candidates
DIM dep(47)              ' scratch BFS depth

DIM wumpSlot, pitA, pitB, nCav

' ---- hunter -----------------------------------------------------------------
DIM pSlot                ' cavern the hunter is in (when inTun = 0)
DIM inTun, tFrom, tDir, tStep, tTotal
DIM armed
DIM hx, hy               ' hunter pixel position, set by HunterXY

' ---- game -------------------------------------------------------------------
DIM difficulty, optNum, optBlind, optExpress
DIM outcome, revealAll
DIM tallyWin, tallyWump, tallyPit
DIM msg$
DIM state

' ---- colours ----------------------------------------------------------------
DIM CBLUE, CGRN, CRED, CYEL, CYELD, CWHT, CBLK, CBAT, CARM, CGRY
CBLUE = RGB(60, 90, 255)
CGRN  = RGB(0, 200, 70)
CRED  = RGB(230, 30, 30)
CYEL  = RGB(255, 210, 0)
CYELD = RGB(120, 95, 0)
CWHT  = RGB(255, 255, 255)
CBLK  = RGB(0, 0, 0)
CBAT  = RGB(190, 190, 190)
CARM  = RGB(0, 160, 255)
CGRY  = RGB(120, 120, 120)

RANDOMIZE TIMER
tallyWin = 0 : tallyWump = 0 : tallyPit = 0
difficulty = 1 : optNum = 1
revealAll = 0

' ============================================================================
'  MAIN
' ============================================================================
state = 0
DO
  SELECT CASE state
    CASE 0
      ShowTitle
      state = 1
    CASE 1
      ChooseDifficulty
      state = 2
    CASE 2
      ChooseOptions
      state = 3
    CASE 3
      NewGame
      PlayGame
      ShowOutcome
      state = 4
    CASE 4
      state = ShowTally()
  END SELECT
LOOP
END

' ============================================================================
'  SET-UP SCREENS
' ============================================================================

SUB ShowTitle
  CLS CBLK
  TEXT 160, 70,  "HUNT THE WUMPUS", "CM", 1, 2, CYEL, CBLK
  TEXT 160, 110, "after the TI-99/4A original", "CM", 1, 1, CGRY, CBLK
  TEXT 160, 160, "Deep in a maze of caverns and", "CM", 1, 1, CWHT, CBLK
  TEXT 160, 176, "twisting tunnels lives the Wumpus.", "CM", 1, 1, CWHT, CBLK
  TEXT 160, 200, "You have one arrow.", "CM", 1, 1, CRED, CBLK
  TEXT 160, 250, "Press any key", "CM", 1, 1, CGRN, CBLK
  Bugle
  DrainKeys
  WaitAnyKey
END SUB

SUB ChooseDifficulty
  LOCAL k
  CLS CBLK
  TEXT 160, 40, "HUNT THE WUMPUS", "CM", 1, 2, CYEL, CBLK
  TEXT 60, 100, "PRESS   FOR", "LT", 1, 1, CWHT, CBLK
  TEXT 60, 130, "  1     EASY MAZE", "LT", 1, 1, CWHT, CBLK
  TEXT 60, 150, "  2     HARD MAZE", "LT", 1, 1, CWHT, CBLK
  TEXT 60, 170, "  3     PRO MAZE", "LT", 1, 1, CWHT, CBLK
  TEXT 160, 220, "about 32 / 24 / 16 caverns", "CM", 1, 1, CGRY, CBLK
  TEXT 160, 240, "fewer caverns, longer tunnels", "CM", 1, 1, CGRY, CBLK
  DrainKeys
  DO
    k = WaitAnyKey()
  LOOP UNTIL k >= 49 AND k <= 51
  difficulty = k - 48
END SUB

SUB ChooseOptions
  LOCAL k
  CLS CBLK
  TEXT 160, 40, "HUNT THE WUMPUS", "CM", 1, 2, CYEL, CBLK
  TEXT 50, 90,  "PRESS   OPTION", "LT", 1, 1, CWHT, CBLK
  TEXT 50, 120, "  1     NORMAL", "LT", 1, 1, CWHT, CBLK
  TEXT 50, 140, "  2     BLINDFOLD", "LT", 1, 1, CWHT, CBLK
  TEXT 50, 160, "  3     EXPRESS", "LT", 1, 1, CWHT, CBLK
  TEXT 50, 180, "  4     BLINDFOLD & EXPRESS", "LT", 1, 1, CWHT, CBLK
  TEXT 160, 225, "BLINDFOLD erases the map behind you", "CM", 1, 1, CGRY, CBLK
  TEXT 160, 245, "EXPRESS skips you through tunnels", "CM", 1, 1, CGRY, CBLK
  DrainKeys
  DO
    k = WaitAnyKey()
  LOOP UNTIL k >= 49 AND k <= 52
  optNum = k - 48
  optBlind = 0 : optExpress = 0
  IF optNum = 2 OR optNum = 4 THEN optBlind = 1
  IF optNum = 3 OR optNum = 4 THEN optExpress = 1
END SUB

' ============================================================================
'  MAZE CONSTRUCTION
' ============================================================================

SUB NewGame
  revealAll = 0
  DO
    BuildMaze
    ComputeWarnings
  LOOP UNTIL PlaceHunter() = 1
  armed = 0
  outcome = 0
END SUB

SUB BuildMaze
  LOCAL i, d, s, c, r, k, t, placed

  FOR i = 0 TO NSLOT - 1
    cav(i) = 0 : blood(i) = 0 : slime(i) = 0 : seen(i) = 0
    batAt(i) = 0 : batSeen(i) = 0
    FOR d = 0 TO 3
      link(i, d) = -1
      tlen(i, d) = 0
      tseen(i, d) = 0
    NEXT d
  NEXT i

  SELECT CASE difficulty
    CASE 1
      nCav = 32
    CASE 2
      nCav = 24
    CASE ELSE
      nCav = 16
  END SELECT

  placed = 0
  DO WHILE placed < nCav
    s = INT(RND * NSLOT)
    IF cav(s) = 0 THEN
      cav(s) = 1
      placed = placed + 1
    ENDIF
  LOOP

  ' A tunnel runs from each cavern to the next cavern along that row or
  ' column, wrapping at the screen edge.  If a cavern is the only one in its
  ' row (or column) the scan wraps all the way round and the tunnel loops
  ' back into the cavern it left - exactly the "SURPRISE!" case the manual
  ' describes.  Scanning this way also makes the graph symmetric: if A leads
  ' right to B then B leads left to A.
  FOR s = 0 TO NSLOT - 1
    IF cav(s) = 1 THEN
      c = s MOD COLS
      r = s \ COLS
      FOR k = 1 TO COLS
        t = r * COLS + ((c + k) MOD COLS)
        IF cav(t) = 1 THEN
          link(s, DRT) = t : tlen(s, DRT) = k
          EXIT FOR
        ENDIF
      NEXT k
      FOR k = 1 TO COLS
        t = r * COLS + ((c - k + COLS + COLS) MOD COLS)
        IF cav(t) = 1 THEN
          link(s, DLF) = t : tlen(s, DLF) = k
          EXIT FOR
        ENDIF
      NEXT k
      FOR k = 1 TO ROWS
        t = ((r + k) MOD ROWS) * COLS + c
        IF cav(t) = 1 THEN
          link(s, DDN) = t : tlen(s, DDN) = k
          EXIT FOR
        ENDIF
      NEXT k
      FOR k = 1 TO ROWS
        t = ((r - k + ROWS + ROWS) MOD ROWS) * COLS + c
        IF cav(t) = 1 THEN
          link(s, DUP) = t : tlen(s, DUP) = k
          EXIT FOR
        ENDIF
      NEXT k
    ENDIF
  NEXT s

  DO
    wumpSlot = INT(RND * NSLOT)
  LOOP UNTIL cav(wumpSlot) = 1

  ' The manual notes the Wumpus sometimes makes its lair in a slime pit, so
  ' pits are not excluded from the Wumpus' cavern.
  DO
    pitA = INT(RND * NSLOT)
  LOOP UNTIL cav(pitA) = 1
  DO
    pitB = INT(RND * NSLOT)
  LOOP UNTIL cav(pitB) = 1 AND pitB <> pitA

  placed = 0
  DO WHILE placed < 3
    s = INT(RND * NSLOT)
    IF cav(s) = 1 AND batAt(s) = 0 AND s <> wumpSlot AND s <> pitA AND s <> pitB THEN
      batAt(s) = 1
      placed = placed + 1
    ENDIF
  LOOP
END SUB

SUB ComputeWarnings
  LOCAL i, d, s, n, head, tail
  FOR i = 0 TO NSLOT - 1
    blood(i) = 0 : slime(i) = 0 : dep(i) = -1
  NEXT i

  ' bloodspots reach two caverns from the Wumpus
  head = 0 : tail = 0
  q(tail) = wumpSlot : tail = tail + 1
  dep(wumpSlot) = 0
  DO WHILE head < tail
    s = q(head) : head = head + 1
    blood(s) = 1
    IF dep(s) < 2 THEN
      FOR d = 0 TO 3
        n = link(s, d)
        IF n >= 0 THEN
          IF dep(n) = -1 THEN
            dep(n) = dep(s) + 1
            q(tail) = n : tail = tail + 1
          ENDIF
        ENDIF
      NEXT d
    ENDIF
  LOOP

  MarkSlime pitA
  MarkSlime pitB
END SUB

SUB MarkSlime(p)
  LOCAL d, n
  slime(p) = 1
  FOR d = 0 TO 3
    n = link(p, d)
    IF n >= 0 THEN
      slime(n) = 1
    ENDIF
  NEXT d
END SUB

' Places the hunter in a safe cavern that can actually reach the Wumpus.
' Returns 0 if this maze has no such cavern, so NewGame can build another.
FUNCTION PlaceHunter()
  LOCAL i, d, s, n, head, tail, cand
  FOR i = 0 TO NSLOT - 1
    dep(i) = -1
  NEXT i
  head = 0 : tail = 0
  q(tail) = wumpSlot : tail = tail + 1
  dep(wumpSlot) = 0
  DO WHILE head < tail
    s = q(head) : head = head + 1
    FOR d = 0 TO 3
      n = link(s, d)
      IF n >= 0 THEN
        IF dep(n) = -1 THEN
          dep(n) = dep(s) + 1
          q(tail) = n : tail = tail + 1
        ENDIF
      ENDIF
    NEXT d
  LOOP

  ' BFS is finished with q(), so reuse it to collect the candidates
  cand = 0
  FOR i = 0 TO NSLOT - 1
    IF dep(i) > 0 AND i <> pitA AND i <> pitB AND batAt(i) = 0 THEN
      q(cand) = i
      cand = cand + 1
    ENDIF
  NEXT i
  IF cand = 0 THEN
    PlaceHunter = 0
    EXIT FUNCTION
  ENDIF
  pSlot = q(INT(RND * cand))
  inTun = 0
  seen(pSlot) = 1
  PlaceHunter = 1
END FUNCTION

' ============================================================================
'  PLAY
' ============================================================================

SUB PlayGame
  LOCAL k, ky$, blinkT, blinkOn
  SetMsg "The hunt begins."
  DrawAll
  blinkT = TIMER
  blinkOn = 1
  DO
    ky$ = INKEY$
    IF ky$ <> "" THEN
      k = ASC(ky$)
      HandleKey k
      IF outcome = 0 THEN
        DrawAll
        blinkT = TIMER
        blinkOn = 1
      ENDIF
    ENDIF
    IF TIMER - blinkT > 400 THEN
      blinkT = TIMER
      blinkOn = 1 - blinkOn
      DrawHunter blinkOn
    ENDIF
  LOOP UNTIL outcome <> 0
END SUB

SUB HandleKey(k)
  LOCAL d
  IF k = KESC THEN
    outcome = OUT_QUIT
    SetMsg "You flee the caverns."
    EXIT SUB
  ENDIF
  IF k = 81 OR k = 113 THEN            ' Q
    IF armed = 1 THEN
      armed = 0
      SetMsg "Arrow lowered."
    ELSE
      armed = 1
      SetMsg "Arrow ready. Pick a tunnel."
    ENDIF
    EXIT SUB
  ENDIF

  d = -1
  IF k = KUP THEN d = DUP
  IF k = KDN THEN d = DDN
  IF k = KLF THEN d = DLF
  IF k = KRT THEN d = DRT
  IF d < 0 THEN EXIT SUB

  IF armed = 1 THEN
    FireArrow d
  ELSE
    TryMove d
  ENDIF
END SUB

SUB TryMove(d)
  LOCAL n
  IF inTun = 0 THEN
    n = link(pSlot, d)
    IF n < 0 THEN
      Bonk
      SetMsg "Solid rock that way."
      EXIT SUB
    ENDIF
    Blip
    MarkTunnel pSlot, d
    IF optExpress = 1 OR tlen(pSlot, d) <= 1 THEN
      pSlot = n
      ResolveLocation
    ELSE
      tFrom = pSlot
      tDir = d
      tStep = 1
      tTotal = tlen(pSlot, d)
      inTun = 1
      SetMsg "Into the tunnel."
    ENDIF
  ELSE
    IF d = tDir THEN
      Blip
      tStep = tStep + 1
      IF tStep >= tTotal THEN
        inTun = 0
        pSlot = link(tFrom, tDir)
        ResolveLocation
      ENDIF
    ELSEIF d = Opposite(tDir) THEN
      Blip
      tStep = tStep - 1
      IF tStep <= 0 THEN
        inTun = 0
        pSlot = tFrom
        ResolveLocation
      ENDIF
    ELSE
      Bonk
      SetMsg "The tunnel runs only two ways."
    ENDIF
  ENDIF
END SUB

' Works out what happens where the hunter has landed.  Bats can throw you
' straight into another bat cavern, so this loops - but only a few times, so
' a pathological maze cannot hang the game.
SUB ResolveLocation
  LOCAL guard
  guard = 0
  DO
    guard = guard + 1
    IF guard > 6 THEN
      EXIT SUB
    ENDIF
    IF inTun = 1 THEN
      SetMsg "Dropped in a pitch black tunnel."
      EXIT SUB
    ENDIF
    seen(pSlot) = 1
    IF pSlot = wumpSlot THEN
      outcome = OUT_WUMP
      SetMsg "You blunder into the Wumpus' lair!"
      EXIT SUB
    ENDIF
    IF pSlot = pitA OR pSlot = pitB THEN
      outcome = OUT_PIT
      EXIT SUB
    ENDIF
    IF batAt(pSlot) = 0 THEN
      DescribeCavern
      EXIT SUB
    ENDIF
    IF batSeen(pSlot) = 0 THEN
      batSeen(pSlot) = 1
      SetMsg "Giant bats. They ignore you for now."
      EXIT SUB
    ENDIF
    IF INT(RND * 4) = 0 THEN
      SetMsg "You creep past the bats."
      EXIT SUB
    ENDIF
    SetMsg "The bats snatch you and fly off!"
    BatSound
    BatCarry
  LOOP
END SUB

SUB BatCarry
  LOCAL s, d
  ' the disturbed bats find somewhere new to live
  batAt(pSlot) = 0
  batSeen(pSlot) = 0
  DO
    s = INT(RND * NSLOT)
  LOOP UNTIL cav(s) = 1 AND batAt(s) = 0
  batAt(s) = 1

  ' and they drop the hunter anywhere at all
  DO
    s = INT(RND * NSLOT)
  LOOP UNTIL cav(s) = 1
  pSlot = s
  inTun = 0
  IF INT(RND * 4) = 0 THEN
    d = INT(RND * 4)
    IF link(s, d) >= 0 THEN
      IF tlen(s, d) > 1 THEN
        tFrom = s
        tDir = d
        tTotal = tlen(s, d)
        tStep = 1 + INT(RND * (tTotal - 1))
        inTun = 1
      ENDIF
    ENDIF
  ENDIF
END SUB

SUB DescribeCavern
  IF blood(pSlot) = 1 AND slime(pSlot) = 1 THEN
    SetMsg "Bloodspots, and the walls run green."
  ELSEIF blood(pSlot) = 1 THEN
    SetMsg "Bloodspots on the cavern floor."
  ELSEIF slime(pSlot) = 1 THEN
    SetMsg "The walls are green with slime."
  ELSE
    SetMsg "An empty cavern."
  ENDIF
END SUB

SUB FireArrow(d)
  LOCAL target
  target = -1
  IF inTun = 0 THEN
    target = link(pSlot, d)
  ELSE
    IF d = tDir THEN
      target = link(tFrom, tDir)
    ELSEIF d = Opposite(tDir) THEN
      target = tFrom
    ENDIF
  ENDIF
  IF target < 0 THEN
    Bonk
    SetMsg "No tunnel that way."
    EXIT SUB
  ENDIF
  armed = 0
  ArrowSound
  IF target = wumpSlot THEN
    outcome = OUT_WIN
  ELSE
    outcome = OUT_WUMP
    SetMsg "Your arrow hits rock. The Wumpus wakes."
  ENDIF
END SUB

SUB MarkTunnel(s, d)
  LOCAL n
  tseen(s, d) = 1
  n = link(s, d)
  IF n >= 0 THEN
    tseen(n, Opposite(d)) = 1
  ENDIF
END SUB

FUNCTION Opposite(d)
  SELECT CASE d
    CASE DUP
      Opposite = DDN
    CASE DDN
      Opposite = DUP
    CASE DLF
      Opposite = DRT
    CASE ELSE
      Opposite = DLF
  END SELECT
END FUNCTION

' ============================================================================
'  DRAWING
' ============================================================================

SUB DrawAll
  DrawMap
  DrawStatus
END SUB

SUB DrawMap
  LOCAL i, d
  BOX 0, 0, 320, MAPH, 0, CBLK, CBLK
  IF optExpress = 0 OR revealAll = 1 THEN
    FOR i = 0 TO NSLOT - 1
      IF cav(i) = 1 AND Visible(i) = 1 THEN
        FOR d = 0 TO 3
          IF d = DRT OR d = DDN THEN
            IF link(i, d) >= 0 AND (tseen(i, d) = 1 OR revealAll = 1) THEN
              DrawTunnel i, d
            ENDIF
          ENDIF
        NEXT d
      ENDIF
    NEXT i
  ENDIF
  FOR i = 0 TO NSLOT - 1
    IF cav(i) = 1 AND Visible(i) = 1 THEN DrawCavern i
  NEXT i
  DrawHunter 1
END SUB

FUNCTION Visible(s)
  IF revealAll = 1 THEN
    Visible = 1
  ELSEIF optBlind = 1 THEN
    Visible = 0
    IF inTun = 0 AND s = pSlot THEN Visible = 1
  ELSE
    Visible = seen(s)
  ENDIF
END FUNCTION

SUB DrawCavern(s)
  LOCAL cx, cy, wc
  cx = (s MOD COLS) * CELL + CELL \ 2
  cy = (s \ COLS) * CELL + CELL \ 2
  wc = CBLUE
  IF slime(s) = 1 THEN wc = CGRN
  CIRCLE cx, cy, CAVR, 2, 1, wc
  IF revealAll = 1 AND (s = pitA OR s = pitB) THEN
    CIRCLE cx, cy, 8, 0, 1, CGRN, CGRN
  ENDIF
  IF blood(s) = 1 THEN
    CIRCLE cx, cy, 5, 0, 1, CRED, CRED
  ENDIF
  IF revealAll = 1 AND s = wumpSlot THEN
    DrawWumpusMark cx, cy
  ENDIF
  IF batSeen(s) = 1 OR (revealAll = 1 AND batAt(s) = 1) THEN
    DrawBat cx, cy
  ENDIF
END SUB

SUB DrawWumpusMark(cx, cy)
  CIRCLE cx, cy, 6, 0, 1, CRED, CRED
  LINE cx - 5, cy + 5, cx - 2, cy + 1, 1, CBLK
  LINE cx + 5, cy + 5, cx + 2, cy + 1, 1, CBLK
END SUB

SUB DrawBat(cx, cy)
  LINE cx - 7, cy + 6, cx - 3, cy + 1, 1, CBAT
  LINE cx - 3, cy + 1, cx, cy + 5, 1, CBAT
  LINE cx, cy + 5, cx + 3, cy + 1, 1, CBAT
  LINE cx + 3, cy + 1, cx + 7, cy + 6, 1, CBAT
END SUB

' Draws the tunnel leaving cavern s in direction d, one lattice step at a
' time so that a step crossing the screen edge can be split into the two
' pieces the wrap-around needs.  Each step gets a kink so the tunnel reads
' as twisting rather than ruler-straight.
SUB DrawTunnel(s, d)
  LOCAL c, r, k, steps, ca, ra, cb, rb, xa, ya, xb, yb, mx, my, off
  c = s MOD COLS
  r = s \ COLS
  steps = tlen(s, d)
  FOR k = 0 TO steps - 1
    ca = c : ra = r : cb = c : rb = r
    SELECT CASE d
      CASE DRT
        ca = (c + k) MOD COLS
        cb = (c + k + 1) MOD COLS
      CASE DLF
        ca = (c - k + COLS + COLS) MOD COLS
        cb = (c - k - 1 + COLS + COLS) MOD COLS
      CASE DDN
        ra = (r + k) MOD ROWS
        rb = (r + k + 1) MOD ROWS
      CASE DUP
        ra = (r - k + ROWS + ROWS) MOD ROWS
        rb = (r - k - 1 + ROWS + ROWS) MOD ROWS
    END SELECT
    xa = ca * CELL + CELL \ 2
    ya = ra * CELL + CELL \ 2
    xb = cb * CELL + CELL \ 2
    yb = rb * CELL + CELL \ 2

    IF ABS(xa - xb) > CELL OR ABS(ya - yb) > CELL THEN
      ' this step leaves one edge and returns on the other
      IF xa <> xb THEN
        IF xb < xa THEN
          LINE xa, ya, 319, ya, 2, CBLUE
          LINE 0, yb, xb, yb, 2, CBLUE
        ELSE
          LINE xa, ya, 0, ya, 2, CBLUE
          LINE 319, yb, xb, yb, 2, CBLUE
        ENDIF
      ELSE
        IF yb < ya THEN
          LINE xa, ya, xa, MAPH - 1, 2, CBLUE
          LINE xb, 0, xb, yb, 2, CBLUE
        ELSE
          LINE xa, ya, xa, 0, 2, CBLUE
          LINE xb, MAPH - 1, xb, yb, 2, CBLUE
        ENDIF
      ENDIF
    ELSE
      off = 6
      IF (k MOD 2) = 1 THEN off = -6
      mx = (xa + xb) \ 2
      my = (ya + yb) \ 2
      IF ya = yb THEN
        my = my + off
      ELSE
        mx = mx + off
      ENDIF
      LINE xa, ya, mx, my, 2, CBLUE
      LINE mx, my, xb, yb, 2, CBLUE
    ENDIF
  NEXT k
END SUB

SUB HunterXY
  LOCAL c, r
  IF inTun = 0 THEN
    hx = (pSlot MOD COLS) * CELL + CELL \ 2
    hy = (pSlot \ COLS) * CELL + CELL \ 2
  ELSE
    c = tFrom MOD COLS
    r = tFrom \ COLS
    SELECT CASE tDir
      CASE DRT
        c = (c + tStep) MOD COLS
      CASE DLF
        c = (c - tStep + COLS + COLS) MOD COLS
      CASE DDN
        r = (r + tStep) MOD ROWS
      CASE DUP
        r = (r - tStep + ROWS + ROWS) MOD ROWS
    END SELECT
    hx = c * CELL + CELL \ 2
    hy = r * CELL + CELL \ 2
  ENDIF
END SUB

' The hunter blinks, as it does on the TI.  Redrawing the same strokes in a
' dimmer colour avoids erasing the cavern underneath.
SUB DrawHunter(bright)
  LOCAL x, y, hc
  HunterXY
  x = hx
  y = hy
  IF armed = 1 THEN
    hc = CARM
  ELSE
    hc = CYEL
    IF bright = 0 THEN hc = CYELD
  ENDIF
  CIRCLE x, y - 6, 2, 0, 1, hc, hc
  LINE x, y - 4, x, y + 2, 1, hc
  LINE x - 4, y - 1, x + 4, y - 1, 1, hc
  LINE x, y + 2, x - 3, y + 7, 1, hc
  LINE x, y + 2, x + 3, y + 7, 1, hc
END SUB

SUB DrawStatus
  LOCAL m$
  BOX 0, MAPH, 320, 320 - MAPH, 0, CBLK, CBLK
  LINE 0, MAPH, 319, MAPH, 1, CGRY
  TEXT 4, MAPH + 8, msg$, "LT", 1, 1, CWHT, CBLK
  m$ = MazeName$() + "  " + OptName$()
  TEXT 4, MAPH + 28, m$, "LT", 1, 1, CGRY, CBLK
  IF armed = 1 THEN
    TEXT 4, MAPH + 48, "ARROW READY - pick a tunnel", "LT", 1, 1, CARM, CBLK
  ELSE
    TEXT 4, MAPH + 48, "Arrows move   Q arrow   ESC quit", "LT", 1, 1, CGRY, CBLK
  ENDIF
END SUB

FUNCTION MazeName$()
  SELECT CASE difficulty
    CASE 1
      MazeName$ = "EASY"
    CASE 2
      MazeName$ = "HARD"
    CASE ELSE
      MazeName$ = "PRO"
  END SELECT
END FUNCTION

FUNCTION OptName$()
  SELECT CASE optNum
    CASE 1
      OptName$ = "NORMAL"
    CASE 2
      OptName$ = "BLINDFOLD"
    CASE 3
      OptName$ = "EXPRESS"
    CASE ELSE
      OptName$ = "BLINDFOLD & EXPRESS"
  END SELECT
END FUNCTION

SUB SetMsg(m$)
  msg$ = m$
END SUB

' ============================================================================
'  END OF HUNT
' ============================================================================

SUB ShowOutcome
  IF outcome = OUT_QUIT THEN
    EXIT SUB
  ENDIF
  SELECT CASE outcome
    CASE OUT_WIN
      tallyWin = tallyWin + 1
      CLS CBLK
      TEXT 160, 130, "GOT IT!", "CM", 1, 3, CYEL, CBLK
      TEXT 160, 180, "You got the Wumpus!", "CM", 1, 1, CWHT, CBLK
      Fanfare
    CASE OUT_PIT
      tallyPit = tallyPit + 1
      PitFall
      TEXT 160, 150, "PIT", "CM", 1, 3, CWHT, CGRN
      PitSound
    CASE ELSE
      tallyWump = tallyWump + 1
      CLS CBLK
      TEXT 160, 120, "THE WUMPUS GOT YOU", "CM", 1, 2, CRED, CBLK
      TEXT 160, 170, msg$, "CM", 1, 1, CWHT, CBLK
      FuneralMarch
  END SELECT
  PAUSE 900
END SUB

' The hunter tumbling into the slime, as the TI shows it.
SUB PitFall
  LOCAL y
  FOR y = 60 TO 200 STEP 8
    BOX 0, 0, 320, 320, 0, CGRN, CGRN
    BOX 40, 0, 60, 320, 0, CBLUE, CBLUE
    BOX 220, 0, 60, 320, 0, CBLUE, CBLUE
    BOX 100, 230, 120, 90, 0, CWHT, CWHT
    CIRCLE 160, y, 4, 0, 1, CYEL, CYEL
    LINE 160, y + 4, 160, y + 14, 2, CYEL
    LINE 152, y + 6, 168, y + 6, 2, CYEL
    LINE 160, y + 14, 154, y + 22, 2, CYEL
    LINE 160, y + 14, 166, y + 22, 2, CYEL
    PAUSE 40
  NEXT y
END SUB

FUNCTION ShowTally()
  LOCAL k
  DrawTally
  DrainKeys
  DO
    k = WaitAnyKey()
    IF k = 81 OR k = 113 THEN            ' Q - reveal the map
      revealAll = 1
      DrawMap
      TEXT 4, MAPH + 8, "The maze as it really was.", "LT", 1, 1, CWHT, CBLK
      TEXT 4, MAPH + 28, "Press any key", "LT", 1, 1, CGRY, CBLK
      DrainKeys
      k = WaitAnyKey()
      revealAll = 0
      DrawTally
    ELSEIF k = KUP THEN                  ' play again, same settings
      ShowTally = 3
      EXIT FUNCTION
    ELSEIF k = 66 OR k = 98 THEN         ' B - change options
      ShowTally = 1
      EXIT FUNCTION
    ELSEIF k = KESC THEN
      CLS CBLK
      TEXT 160, 150, "THE HUNT IS OVER", "CM", 1, 2, CYEL, CBLK
      PAUSE 1500
      CLS CBLK
      END
    ENDIF
  LOOP
END FUNCTION

SUB DrawTally
  CLS CBLK
  SELECT CASE outcome
    CASE OUT_WIN
      TEXT 160, 30, "CONGRATULATIONS", "CM", 1, 1, CYEL, CBLK
      TEXT 160, 50, "YOU GOT THE WUMPUS!!", "CM", 1, 1, CYEL, CBLK
    CASE OUT_PIT
      TEXT 160, 30, "NEXT TIME...", "CM", 1, 1, CGRN, CBLK
      TEXT 160, 50, "WATCH OUT FOR SLIME!!", "CM", 1, 1, CGRN, CBLK
    CASE ELSE
      TEXT 160, 30, "THE WUMPUS FEEDS", "CM", 1, 1, CRED, CBLK
      TEXT 160, 50, "BETTER LUCK NEXT HUNT!!", "CM", 1, 1, CRED, CBLK
  END SELECT

  BOX 40, 80, 240, 60, 2, CRED, CBLK
  TEXT 160, 92, "TALLY BOARD", "CM", 1, 1, CWHT, CBLK

  CIRCLE 80, 118, 4, 0, 1, CYEL, CYEL
  TEXT 95, 112, Pad2$(tallyWin), "LT", 1, 1, CWHT, CBLK
  CIRCLE 150, 118, 5, 0, 1, CRED, CRED
  TEXT 165, 112, Pad2$(tallyWump), "LT", 1, 1, CWHT, CBLK
  CIRCLE 220, 118, 5, 0, 1, CGRN, CGRN
  TEXT 235, 112, Pad2$(tallyPit), "LT", 1, 1, CWHT, CBLK

  TEXT 30, 175, "PRESS:        TO:", "LT", 1, 1, CWHT, CBLK
  TEXT 30, 200, "Q             REVEAL THE MAP", "LT", 1, 1, CWHT, CBLK
  TEXT 30, 220, "UP ARROW      PLAY AGAIN, SAME", "LT", 1, 1, CWHT, CBLK
  TEXT 30, 240, "B             CHANGE OPTIONS", "LT", 1, 1, CWHT, CBLK
  TEXT 30, 260, "ESC           END THE HUNT", "LT", 1, 1, CWHT, CBLK
END SUB

FUNCTION Pad2$(n)
  IF n < 10 THEN
    Pad2$ = "0" + STR$(n)
  ELSE
    Pad2$ = STR$(n)
  ENDIF
END FUNCTION

' ============================================================================
'  INPUT AND SOUND
' ============================================================================

SUB DrainKeys
  DO WHILE INKEY$ <> ""
  LOOP
END SUB

FUNCTION WaitAnyKey()
  LOCAL k$
  DO
    k$ = INKEY$
  LOOP WHILE k$ = ""
  WaitAnyKey = ASC(k$)
END FUNCTION

SUB Blip
  PLAY TONE 1600, 1600, 12
END SUB

SUB Bonk
  PLAY TONE 130, 130, 90
END SUB

SUB BatSound
  LOCAL i
  FOR i = 1 TO 6
    PLAY TONE 900 + i * 120, 900 + i * 120, 35
    PAUSE 40
  NEXT i
END SUB

SUB ArrowSound
  LOCAL i
  FOR i = 0 TO 8
    PLAY TONE 2600 - i * 220, 2600 - i * 220, 25
    PAUSE 28
  NEXT i
END SUB

SUB Bugle
  SndNote 523, 160
  SndNote 659, 160
  SndNote 784, 240
  SndNote 659, 120
  SndNote 784, 400
END SUB

SUB Fanfare
  SndNote 784, 130
  SndNote 784, 130
  SndNote 784, 130
  SndNote 1047, 460
  SndNote 880, 160
  SndNote 1047, 520
END SUB

SUB FuneralMarch
  SndNote 220, 420
  SndNote 220, 200
  SndNote 220, 420
  SndNote 262, 420
  SndNote 247, 300
  SndNote 220, 620
END SUB

SUB PitSound
  LOCAL f
  FOR f = 1200 TO 120 STEP -60
    PLAY TONE f, f, 45
    PAUSE 40
  NEXT f
END SUB

SUB SndNote(f, ms)
  PLAY TONE f, f, ms
  PAUSE ms + 20
END SUB
