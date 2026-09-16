' ============================================================================
'  Draw3D FEASIBILITY PROBE  --  PicoCalc / PicoMite MMBasic
'
'  Answers one question before any Elite work starts: how many wireframe ships
'  can the firmware's 3D engine transform and draw per second on this device?
'
'  It draws a ship-shaped hull as 1, 2, 4 and 8 objects, times 30 frames of
'  rotate-and-show at each count, and prints the frame rate.
'
'  NOTE the command is Draw3D, not 3D. The 3D user manual writes every example
'  with a bare "3D" prefix but no such token exists - AllCommands.h registers
'  only "Draw3D" and "DRAW3D(".
'
'  The hull keeps the exact face topology and winding of the manual's cube
'  example, with the vertices pulled into a wedge. Reusing known-good winding
'  means the surface normals stay correct, so hidden-face removal works without
'  having to get it right blind.
'
'  Never run off-device.
' ============================================================================

OPTION EXPLICIT

DIM vertex(7, 2) AS FLOAT
DIM facecount(5) AS INTEGER
DIM faces(23) AS INTEGER
DIM colours(1) AS INTEGER
DIM linecolour(5) AS INTEGER
DIM quat(4) AS FLOAT

DIM i AS INTEGER, n AS INTEGER, ships AS INTEGER, frame AS INTEGER
DIM t0 AS INTEGER, el AS INTEGER
DIM angle AS FLOAT, ax AS FLOAT, ay AS FLOAT
DIM px AS INTEGER, py AS INTEGER, pz AS INTEGER
DIM fps AS FLOAT
DIM row AS INTEGER

' A wedge: the cube's 8 corners with the nose drawn in and the tail flared.
' Same 6 faces, same winding, so the normals stay valid.
DATA -30,-10, 30,   30,-10, 30,   14,  8, 30,  -14,  8, 30
DATA  -8, -6,-45,    8, -6,-45,    5,  4,-45,   -5,  4,-45

RESTORE
FOR i = 0 TO 7
  READ vertex(i, 0), vertex(i, 1), vertex(i, 2)
NEXT i

FOR i = 0 TO 5
  facecount(i) = 4
NEXT i

' identical to the manual's cube faces - counter-clockwise seen from outside
DATA 0,1,2,3, 5,4,7,6, 0,4,5,1, 2,6,7,3, 0,3,7,4, 1,5,6,2
FOR i = 0 TO 23
  READ faces(i)
NEXT i

colours(0) = RGB(CYAN)
colours(1) = RGB(WHITE)
FOR i = 0 TO 5
  linecolour(i) = 0
NEXT i

CLS RGB(BLACK)
TEXT 160, 10, "Draw3D PROBE", "CT", 1, 2, RGB(YELLOW), RGB(BLACK)
Draw3D CAMERA 1, 400

row = 250
FOR ships = 1 TO 8
  IF ships = 1 OR ships = 2 OR ships = 4 OR ships = 8 THEN

    ' fillcolour() is left off, so faces draw as outlines only - wireframe.
    ' Pass a fillcolour array as a 10th argument to get solid faces instead.
    FOR n = 1 TO ships
      Draw3D CREATE n, 8, 6, 1, vertex(), facecount(), faces(), colours(), linecolour()
    NEXT n

    angle = 0
    t0 = TIMER
    FOR frame = 1 TO 30
      ax = RAD(angle * 0.7)
      ay = RAD(angle)
      quat(0) = COS(ax / 2) * COS(ay / 2)
      quat(1) = SIN(ax / 2) * COS(ay / 2)
      quat(2) = COS(ax / 2) * SIN(ay / 2)
      quat(3) = SIN(ax / 2) * SIN(ay / 2)
      quat(4) = 1
      FOR n = 1 TO ships
        Draw3D RESET n
        Draw3D ROTATE quat(), n
        px = -90 + ((n - 1) MOD 3) * 90
        py = -60 + ((n - 1) \ 3) * 70
        pz = 260
        Draw3D SHOW n, px, py, pz
      NEXT n
      angle = angle + 6
      IF angle >= 360 THEN angle = 0
    NEXT frame
    el = TIMER - t0

    Draw3D CLOSE ALL

    IF el < 1 THEN el = 1
    fps = 30000.0 / el
    BOX 0, row, 320, 16, 0, RGB(BLACK), RGB(BLACK)
    TEXT 6, row, STR$(ships) + " ship(s): " + STR$(fps, 0, 1) + " fps  (" + STR$(el) + "ms/30)", "LT", 1, 1, RGB(WHITE), RGB(BLACK)
    row = row + 16
  ENDIF
NEXT ships

TEXT 160, 310, "any key to exit", "CB", 1, 1, RGB(GREEN), RGB(BLACK)
DO
LOOP WHILE INKEY$ = ""
END
