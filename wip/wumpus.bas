' Hunt the Wumpus - PicoMite Version

OPTION EXPLICIT
OPTION ANGLE DEGREES

CONST SCREENW = MM.HRES
CONST SCREENH = MM.VRES
CONST ROOM_RADIUS = 40
CONST TEXT_HEIGHT = 12
CONST MAX_MESSAGES = 6
CONST MAPW = 8
CONST MAPH = 6

CONST NUM_BATS = 2
CONST NUM_PITS = 1
CONST SHOW_COORDS = 1

DIM messages$(MAX_MESSAGES)
DIM currentLine = 0

' Player state
DIM INTEGER playerX, playerY
DIM armedArrow

' Wumpus, pits, bats
DIM INTEGER wumpusX, wumpusY
DIM INTEGER pitsX(NUM_PITS), pitsY(NUM_PITS)
DIM INTEGER batsX(NUM_BATS), batsY(NUM_BATS)

' General loop counter
DIM i AS INTEGER
DIM move$ AS STRING
DIM dir$ AS STRING

'==== Initialization ====
CLS
RANDOMIZE TIMER
playerX = 2 : playerY = 2
wumpusX = 5 : wumpusY = 4

FOR i = 1 TO NUM_PITS
  pitsX(i) = INT(RND * MAPW)
  pitsY(i) = INT(RND * MAPH)
NEXT
FOR i = 1 TO NUM_BATS
  batsX(i) = INT(RND * MAPW)
  batsY(i) = INT(RND * MAPH)
NEXT

DrawRoom
LogMessage "Welcome to Hunt the Wumpus!"

DO
  TEXT 0, SCREENH - (TEXT_HEIGHT * (MAX_MESSAGES + 1)), SPACE$(40), "LT", 1, 1, RGB(white), RGB(black)
  TEXT 0, SCREENH - (TEXT_HEIGHT * (MAX_MESSAGES + 1)), "Move (N/S/E/W), ARM, FIRE, Q: ", "LT", 1, 1, RGB(white), RGB(black)
  INPUT move$

  move$ = UCASE$(move$)
  IF move$ = "Q" THEN END

  IF move$ = "ARM" THEN
    armedArrow = 1
    LogMessage "Arrow armed."
  ELSEIF move$ = "FIRE" THEN
    IF armedArrow THEN
      armedArrow = 0
      TEXT 0, SCREENH - (TEXT_HEIGHT * (MAX_MESSAGES + 1)), SPACE$(40), "LT", 1, 1, RGB(white), RGB(black)
      TEXT 0, SCREENH - (TEXT_HEIGHT * (MAX_MESSAGES + 1)), "Direction to fire (N/S/E/W): ", "LT", 1, 1, RGB(white), RGB(black)
      INPUT dir$
      dir$ = UCASE$(dir$)
      SELECT CASE dir$
        CASE "N": IF playerX = wumpusX AND playerY - 1 = wumpusY THEN LogMessage "You hit the Wumpus!": END
        CASE "S": IF playerX = wumpusX AND playerY + 1 = wumpusY THEN LogMessage "You hit the Wumpus!": END
        CASE "E": IF playerY = wumpusY AND playerX + 1 = wumpusX THEN LogMessage "You hit the Wumpus!": END
        CASE "W": IF playerY = wumpusY AND playerX - 1 = wumpusX THEN LogMessage "You hit the Wumpus!": END
      END SELECT
      LogMessage "Missed! The Wumpus eats you."
      END
    ELSE
      LogMessage "You must ARM first!"
    ENDIF
  ELSE
    SELECT CASE move$
      CASE "N": IF playerY > 0 THEN playerY = playerY - 1
      CASE "S": IF playerY < MAPH - 1 THEN playerY = playerY + 1
      CASE "E": IF playerX < MAPW - 1 THEN playerX = playerX + 1
      CASE "W": IF playerX > 0 THEN playerX = playerX - 1
      CASE ELSE
        LogMessage "Invalid move."
    END SELECT
    DrawRoom
  ENDIF
LOOP

' ==== SUBS ====

SUB DrawRoom
  LOCAL cx, cy, r, angle, x1, y1, x2, y2
  cx = SCREENW \ 2
  cy = SCREENH \ 2 - 40
  r = ROOM_RADIUS
  CLS

  FOR i = 1 TO NUM_PITS
    IF ABS(playerX - pitsX(i)) + ABS(playerY - pitsY(i)) = 1 THEN
      CIRCLE cx, cy, r + 6, , , RGB(green)
      LogMessage "You feel a breeze."
    ENDIF
  NEXT
  IF ABS(playerX - wumpusX) + ABS(playerY - wumpusY) = 1 THEN
    CIRCLE cx, cy, r + 10, , , RGB(red)
    LogMessage "You smell something foul."
  ENDIF

  FOR i = 0 TO 11
    angle = i * 30 + RND * 15
    x1 = cx + r * COS(angle)
    y1 = cy + r * SIN(angle)
    angle = (i + 1) * 30 + RND * 15
    x2 = cx + r * COS(angle)
    y2 = cy + r * SIN(angle)
    LINE x1, y1, x2, y2, , RGB(grey)
  NEXT

  IF playerY > 0 THEN TEXT cx - 4, cy - r - 10, "N", "CT", 1, 1, RGB(white), RGB(black)
  IF playerY < MAPH - 1 THEN TEXT cx - 4, cy + r + 2, "S", "CT", 1, 1, RGB(white), RGB(black)
  IF playerX > 0 THEN TEXT cx - r - 12, cy - 4, "W", "LT", 1, 1, RGB(white), RGB(black)
  IF playerX < MAPW - 1 THEN TEXT cx + r + 6, cy - 4, "E", "LT", 1, 1, RGB(white), RGB(black)

  IF SHOW_COORDS THEN
    TEXT cx - 15, cy + r + 20, "(" + STR$(playerX) + "," + STR$(playerY) + ")", "LT", 1, 1, RGB(white), RGB(black)
  ENDIF
END SUB

SUB LogMessage(m$)
  currentLine = (currentLine MOD MAX_MESSAGES) + 1
  messages$(currentLine) = m$
  DrawMessages
END SUB

SUB DrawMessages
  LOCAL j, index
  BOX 0, SCREENH - TEXT_HEIGHT * MAX_MESSAGES, SCREENW, SCREENH, 0, RGB(black), RGB(black)
  FOR j = 0 TO MAX_MESSAGES - 1
    index = (currentLine + j) MOD MAX_MESSAGES + 1
    TEXT 0, SCREENH - TEXT_HEIGHT * (MAX_MESSAGES - j), messages$(index), "LT", 1, 1, RGB(white), RGB(black)
  NEXT
END SUB
