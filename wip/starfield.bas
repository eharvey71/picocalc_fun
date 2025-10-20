' Starfield + Upward-Scrolling Quotes (2-line word wrap + ESC exit)
OPTION DEFAULT INTEGER

' ===== Tunables =====
CONST MAXSTARS = 120
CONST MINSPD   = 3
CONST MAXSPD   = 6
CONST TWINKLEP = 0.03
CONST QUOTE_P  = 0.005
CONST Q_SPEED  = -2
CONST DT_MS    = 12

CONST SHOOT_P   = 0.02   ' spawn chance per frame (~2%)
CONST SHOOT_V   = 10      ' head speed (px/frame)
CONST SHOOT_LEN = 6       ' trail length (points)

' Text/Wrap settings (Font 1 ≈ 8 px/char)
CONST FONT_IDX = 1
CONST CHAR_W   = 8
CONST LINE_SP  = 16        ' vertical spacing between wrapped lines

' ===== State =====
DIM starsX(MAXSTARS), starsY(MAXSTARS)
DIM starsDY(MAXSTARS), starsC(MAXSTARS)
DIM quotes$(10), colors(4)
DIM ssActive, ssx, ssy, sdx, sdy, ssLife
DIM ssTrailX(SHOOT_LEN), ssTrailY(SHOOT_LEN)

frameDelay = DT_MS           ' runtime-adjustable frame pause (ms)

hres = MM.HRES
vres = MM.VRES
RANDOMIZE TIMER

' ---- colors ----
black = RGB(0,0,0)
white = RGB(255,255,255)
colors(1) = white
colors(2) = RGB(200,200,255)
colors(3) = RGB(255,220,180)
colors(4) = RGB(180,255,200)

' ---- quotes ----
RESTORE qdata
FOR i = 1 TO 10
  READ quotes$(i)
NEXT i

' ---- init stars ----
FOR i = 1 TO MAXSTARS
  starsX(i) = INT(RND * hres)
  starsY(i) = INT(RND * vres)
  starsDY(i) = MINSPD + INT(RND * (MAXSPD - MINSPD + 1))
  starsC(i) = colors(1 + INT(RND * 4))
NEXT i

' ---- quote scroller ----
qActive = 0
q$ = ""
q1$ = ""    ' wrapped line 1
q2$ = ""    ' wrapped line 2 (may be empty)
qy = vres + 24
qColor = RGB(255,255,160)
maxChars = INT(hres / CHAR_W)    ' max chars per line at FONT_IDX

CLS
DO
  ' erase stars at old pos
  FOR i = 1 TO MAXSTARS
    PIXEL starsX(i), starsY(i), black
  NEXT i

  ' update/draw stars
  FOR i = 1 TO MAXSTARS
    starsY(i) = starsY(i) + starsDY(i)
    IF starsY(i) > vres THEN
      starsX(i) = INT(RND * hres)
      starsY(i) = 0
      starsDY(i) = MINSPD + INT(RND * (MAXSPD - MINSPD + 1))
      starsC(i) = colors(1 + INT(RND * 4))
    ENDIF
    IF RND < TWINKLEP THEN
      PIXEL starsX(i), starsY(i), white
    ELSE
      PIXEL starsX(i), starsY(i), starsC(i)
    ENDIF
  NEXT i

  ' ==== Shooting star ====

  ' erase old trail/head from last frame
  IF ssActive THEN
    ' erase all trail points
    FOR k = 1 TO SHOOT_LEN
      IF ssTrailX(k) >= 0 THEN PIXEL ssTrailX(k), ssTrailY(k), black
    NEXT k
    ' also erase last head position (in case not in trail yet)
    PIXEL ssx, ssy, black
  ENDIF

  ' maybe spawn a new shooting star
  IF ssActive = 0 THEN
    IF RND < SHOOT_P THEN
      ssActive = 1
      ' start from lower-left or lower-right, heading up-diagonal
      IF RND < 0.5 THEN
        ssx = -10 : ssy = vres - 10 : sdx =  SHOOT_V : sdy = -SHOOT_V
      ELSE
        ssx = hres + 10 : ssy = vres - 10 : sdx = -SHOOT_V : sdy = -SHOOT_V
      ENDIF
      ssLife = SHOOT_LEN + INT(20 + RND * 40)
      FOR k = 1 TO SHOOT_LEN
        ssTrailX(k) = -1 : ssTrailY(k) = -1
      NEXT k
    ENDIF
  ENDIF

  ' update & draw the shooting star
  IF ssActive THEN
    ' shift trail back
    FOR k = SHOOT_LEN TO 2 STEP -1
      ssTrailX(k) = ssTrailX(k-1)
      ssTrailY(k) = ssTrailY(k-1)
    NEXT k
    ' push current head into trail
    ssTrailX(1) = ssx
    ssTrailY(1) = ssy

    ' advance head
    ssx = ssx + sdx
    ssy = ssy + sdy
    ssLife = ssLife - 1

    ' draw head (bright) and trail (fading)
    PIXEL ssx, ssy, white
    FOR k = 1 TO SHOOT_LEN
      IF ssTrailX(k) >= 0 THEN
        ' simple fade using two softer tints
        IF (k AND 1) = 0 THEN
          PIXEL ssTrailX(k), ssTrailY(k), RGB(180,180,255)
        ELSE
          PIXEL ssTrailX(k), ssTrailY(k), RGB(120,120,200)
        ENDIF
      ENDIF
    NEXT k

    ' end if offscreen or life over
    IF ssLife <= 0 OR ssx < -20 OR ssx > hres + 20 OR ssy < -20 OR ssy > vres + 20 THEN
      ' final clean-up erase
      FOR k = 1 TO SHOOT_LEN
        IF ssTrailX(k) >= 0 THEN PIXEL ssTrailX(k), ssTrailY(k), black
      NEXT k
      PIXEL ssx, ssy, black
      ssActive = 0
    ENDIF
  ENDIF
  ' ==== end shooting star ====

  ' --- key polling (robust across keyboards) ---
  ch$ = INKEY$
  DO WHILE ch$ <> ""
    cu$ = UCASE$(ch$)

    ' Q = start a new quote now (if none is active)
    IF cu$ = "Q" THEN
      IF qActive = 0 THEN GOSUB StartQuote
    ENDIF

    ' Z = slower (increase frame delay up to 40ms)
    IF cu$ = "Z" THEN
      frameDelay = frameDelay + 2
      IF frameDelay > 40 THEN frameDelay = 40
    ENDIF

    ' X = faster (decrease frame delay down to 2ms)
    IF cu$ = "X" THEN
      frameDelay = frameDelay - 2
      IF frameDelay < 2 THEN frameDelay = 2
    ENDIF

    ' ESC = quit cleanly
    IF ASC(ch$) = 27 THEN GOTO QuitStarfield

    ch$ = INKEY$
  LOOP
  ' --- end key polling ---

  ' maybe start a new quote
  IF qActive = 0 THEN
    IF RND < QUOTE_P THEN GOSUB StartQuote
  ENDIF


  ' scroll quote upward (erase old, draw new)
  IF qActive = 1 THEN
    ' erase previous in black (both lines)
    COLOR black
    TEXT hres/2, qy, q1$, "CM", FONT_IDX, 1
    IF LEN(q2$) > 0 THEN
      TEXT hres/2, qy + LINE_SP, q2$, "CM", FONT_IDX, 1
    ENDIF

    qy = qy + Q_SPEED

    ' draw new position in color
    COLOR qColor
    TEXT hres/2, qy, q1$, "CM", FONT_IDX, 1
    IF LEN(q2$) > 0 THEN
      TEXT hres/2, qy + LINE_SP, q2$, "CM", FONT_IDX, 1
    ENDIF

    ' when fully off-screen, deactivate
    IF qy < - (LINE_SP + 24) THEN qActive = 0
  ENDIF

  PAUSE frameDelay
LOOP

' === Subroutines ===

' Word-wrap q$ into up to two centered lines: q1$, q2$ (<= maxChars each)
WrapQuote:
  q1$ = ""
  q2$ = ""

  ' if it fits on one line, great
  IF LEN(q$) <= maxChars THEN
    q1$ = q$
    RETURN
  ENDIF

  ' find split point at/under maxChars (prefer last space)
  sp = maxChars
  DO WHILE sp > 1 AND MID$(q$, sp, 1) <> " "
    sp = sp - 1
  LOOP
  IF sp <= 1 THEN sp = maxChars  ' no space found; hard split

  q1$ = LEFT$(q$, sp)
  ' trim possible trailing space
  DO WHILE LEN(q1$) > 0 AND RIGHT$(q1$,1) = " "
    q1$ = LEFT$(q1$, LEN(q1$)-1)
  LOOP

  rest$ = MID$(q$, sp+1)
  ' If remainder is still too long, truncate the second line with ellipsis
  IF LEN(rest$) > maxChars THEN
    q2$ = LEFT$(rest$, maxChars-1) + "…"
  ELSE
    q2$ = rest$
  ENDIF
RETURN

StartQuote:
  qActive = 1
  q$ = quotes$(1 + INT(RND * 10))
  GOSUB WrapQuote
  qy = vres + 24
RETURN

QuitStarfield:
CLS
END

' ---- Data ----
qdata:
DATA "Believe in yourself."
DATA "Keep moving forward."
DATA "Every day is a fresh start."
DATA "You are stronger than you think."
DATA "If the elevator brings you down try and punch a higher floor"
DATA "Stay positive, work hard, make it happen."
DATA "Great things take time."
DATA "Progress, not perfection."
DATA "Your only limit is you."
DATA "Shine like the stars."
