REM Castle Dungeon for PicoCalc - V7
REM Based on Compute's Gazette June 1984

' Game settings - Screen is 320x320
MAZE_WIDTH = 26       ' 26 tiles wide (was 20)
MAZE_HEIGHT = 26      ' 26 tiles tall (was 20)
TILE_SIZE = 12        ' 12 pixels per tile (26*12=312, centered in 320x320)

' Tile types
WALL = 1
FLOOR = 0

' Object types
OBJ_NONE = 0
OBJ_BOMB = 1
OBJ_KEY = 2
OBJ_SWORD = 3
OBJ_BEAST = 4
OBJ_DOOR = 5
OBJ_PIT = 6

' Colors
wall_color = RGB(150, 50, 0)    ' Brownish red
player_color = RGB(0, 255, 0)    ' Bright green
black_color = RGB(0, 0, 0)       ' Black
bomb_color = RGB(255, 0, 0)      ' Red
key_color = RGB(255, 255, 0)     ' Yellow
sword_color = RGB(192, 192, 192) ' Silver
beast_color = RGB(255, 0, 255)   ' Magenta
door_color = RGB(139, 69, 19)    ' Brown
pit_color = RGB(64, 64, 64)      ' Dark gray

' Game state
bombs_found = 0
has_key = 0
has_sword = 0
levitating = 0       ' Levitation spell active for next move
last_levitating = 0  ' Track levitation changes for status update
game_time = 300      ' 5 minutes = 300 seconds
start_time = 0
last_status_sec = -1 ' Track last second we updated status
current_sec = 0      ' Current elapsed seconds

' Arrays - use 1D array with manual indexing
DIM maze(MAZE_WIDTH * MAZE_HEIGHT - 1)
DIM objects(MAZE_WIDTH * MAZE_HEIGHT - 1)  ' What object is at each location
DIM visible(MAZE_WIDTH * MAZE_HEIGHT - 1)  ' What was visible last frame (for fog of war)
DIM px, py, oldPx, oldPy

' Initialize
GameStart:
' Show title screen
CLS
BOX 0, 0, 320, 320, 1, RGB(0, 0, 0), RGB(0, 0, 0)

TEXT 160, 30, "PICO CASTLE DUNGEON", "CM", 1, 2, RGB(255, 0, 0)
TEXT 160, 55, "Inspired by Castle Dungeon", "CM", 1, 1, RGB(150, 150, 150)
TEXT 160, 70, "Compute!'s Gazette, June 1984", "CM", 1, 1, RGB(150, 150, 150)

TEXT 160, 100, "Find 3 bombs in 5 minutes!", "CM", 1, 1, RGB(255, 255, 0)

TEXT 20, 130, "CONTROLS:", "LT", 1, 1, RGB(0, 255, 0)
TEXT 20, 145, "Arrow keys or WASD - Move", "LT", 1, 1, RGB(255, 255, 255)
TEXT 20, 160, "L - Levitation spell", "LT", 1, 1, RGB(255, 255, 255)
TEXT 20, 175, "Q - Quit", "LT", 1, 1, RGB(255, 255, 255)

TEXT 20, 200, "ITEMS:", "LT", 1, 1, RGB(0, 255, 0)
TEXT 20, 215, "Red circles - Bombs (find 3)", "LT", 1, 1, RGB(255, 255, 255)
TEXT 20, 230, "Yellow key - Opens doors", "LT", 1, 1, RGB(255, 255, 255)
TEXT 20, 245, "Silver sword - Defeats beasts", "LT", 1, 1, RGB(255, 255, 255)

TEXT 160, 280, "Press any key to start", "CM", 1, 1, RGB(255, 255, 0)

' Wait for keypress
DO WHILE INKEY$ = ""
  PAUSE 50
LOOP

' Reset game state
bombs_found = 0
has_key = 0
has_sword = 0
levitating = 0
last_levitating = 0
last_status_sec = -1

' Clear visible array for fog of war
FOR idx = 0 TO MAZE_WIDTH * MAZE_HEIGHT - 1
  visible(idx) = 0
NEXT idx

CLS
' Ensure maze area is fully black before rendering
BOX 0, 0, 320, 320, 1, RGB(0, 0, 0), RGB(0, 0, 0)

GOSUB GenerateMaze
GOSUB PlaceObjects
GOSUB PlacePlayer
oldPx = px
oldPy = py
' Use UpdateFogOfWar for initial render to properly track visibility
GOSUB UpdateFogOfWar
start_time = TIMER  ' Start the countdown timer

' Main loop
DO
  ' Check timer - calculate remaining time (TIMER is in milliseconds)
  IF INT(game_time - ((TIMER - start_time) / 1000)) <= 0 THEN
    ' Time's up - show message on black screen
    PLAY TONE 200, 500, 50  ' Low sound for failure
    CLS
    TEXT 160, 120, "TIME'S UP!", "CM", 1, 1, RGB(255, 0, 0)
    TEXT 160, 140, "Castle destroyed!", "CM", 1, 1, RGB(255, 255, 255)
    PAUSE 2000
    
    ' Reveal the maze
    GOSUB RevealMaze
    
    ' Play again prompt at bottom
    TEXT 160, 310, "Play again (Y/N)?", "CM", 1, 1, RGB(255, 255, 255)
    
    ' Wait for input
    DO
      k$ = INKEY$
      IF UCASE$(k$) = "Y" THEN
        GOTO GameStart
      ELSE IF UCASE$(k$) = "N" THEN
        END
      END IF
    LOOP
  END IF
  
  ' Update status display only when second changes OR levitation changes
  current_sec = INT((TIMER - start_time) / 1000)
  IF current_sec <> last_status_sec OR levitating <> last_levitating THEN
    GOSUB DrawStatus
    last_status_sec = current_sec
    last_levitating = levitating
  END IF
  
  k$ = INKEY$
  
  IF k$ <> "" THEN
    ' Check for levitation spell (L key)
    IF UCASE$(k$) = "L" THEN
      levitating = 1
      ' Wait for key release
      PAUSE 150
      DO WHILE INKEY$ <> ""
        PAUSE 20
      LOOP
      GOTO SkipMove
    END IF
    
    newX = px
    newY = py
    
    IF k$ = CHR$(128) OR UCASE$(k$) = "W" THEN newY = py - 1
    IF k$ = CHR$(129) OR UCASE$(k$) = "S" THEN newY = py + 1
    IF k$ = CHR$(130) OR UCASE$(k$) = "A" THEN newX = px - 1
    IF k$ = CHR$(131) OR UCASE$(k$) = "D" THEN newX = px + 1
    IF UCASE$(k$) = "Q" THEN EXIT
    
    IF newX >= 0 AND newX < MAZE_WIDTH AND newY >= 0 AND newY < MAZE_HEIGHT THEN
      IF maze(newY * MAZE_WIDTH + newX) <> WALL THEN
        ' Check for objects at new position
        idx = newY * MAZE_WIDTH + newX
        
        IF objects(idx) = OBJ_DOOR THEN
          ' Check if player has key
          IF has_key = 1 THEN
            ' Open the door (remove it)
            objects(idx) = OBJ_NONE
            PLAY TONE 700, 100, 50  ' Door opening sound
          ELSE
            ' Can't pass through - door is locked
            PLAY TONE 300, 100, 50  ' Locked door sound
            ' Don't move, just exit
            PAUSE 150
            DO WHILE INKEY$ <> ""
              PAUSE 20
            LOOP
            GOTO SkipMove
          END IF
        ELSE IF objects(idx) = OBJ_PIT THEN
          ' Check if player is levitating
          IF levitating = 1 THEN
            ' Levitate over the pit - remove it after crossing
            objects(idx) = OBJ_NONE
            PLAY TONE 900, 150, 50  ' Levitation sound
          ELSE
            ' Fall into pit - show message, reveal maze, play again
            PLAY TONE 200, 500, 50  ' Falling sound
            CLS
            TEXT 160, 120, "GAME OVER!", "CM", 1, 1, RGB(255, 0, 0)
            TEXT 160, 140, "You fell in a pit!", "CM", 1, 1, RGB(255, 255, 255)
            PAUSE 2000
            
            GOSUB RevealMaze
            TEXT 160, 310, "Play again (Y/N)?", "CM", 1, 1, RGB(255, 255, 255)
            
            DO
              k$ = INKEY$
              IF UCASE$(k$) = "Y" THEN
                GOTO GameStart
              ELSE IF UCASE$(k$) = "N" THEN
                END
              END IF
            LOOP
          END IF
        ELSE IF objects(idx) = OBJ_BOMB THEN
          ' Pick up bomb
          objects(idx) = OBJ_NONE
          bombs_found = bombs_found + 1
          PLAY TONE 1000, 100, 50  ' High beep for bomb pickup
        ELSE IF objects(idx) = OBJ_KEY THEN
          ' Pick up key
          objects(idx) = OBJ_NONE
          has_key = 1
          PLAY TONE 800, 100, 50  ' Medium beep for key
        ELSE IF objects(idx) = OBJ_SWORD THEN
          ' Pick up sword
          objects(idx) = OBJ_NONE
          has_sword = 1
          PLAY TONE 600, 150, 50  ' Lower beep for sword
        ELSE IF objects(idx) = OBJ_BEAST THEN
          ' Hit a beast!
          IF has_sword = 1 THEN
            ' Kill the beast
            objects(idx) = OBJ_NONE
            PLAY TONE 400, 200, 50  ' Low sound for beast death
          ELSE
            ' Game over - beast kills player
            PLAY TONE 200, 500, 50  ' Low long sound for death
            CLS
            TEXT 160, 120, "GAME OVER!", "CM", 1, 1, RGB(255, 0, 0)
            TEXT 160, 140, "Beast got you!", "CM", 1, 1, RGB(255, 255, 255)
            PAUSE 2000
            
            GOSUB RevealMaze
            TEXT 160, 310, "Play again (Y/N)?", "CM", 1, 1, RGB(255, 255, 255)
            
            DO
              k$ = INKEY$
              IF UCASE$(k$) = "Y" THEN
                GOTO GameStart
              ELSE IF UCASE$(k$) = "N" THEN
                END
              END IF
            LOOP
          END IF
        END IF
        
        ' Erase old player position
        sx = oldPx * TILE_SIZE
        sy = oldPy * TILE_SIZE + 12
        BOX sx, sy, TILE_SIZE, TILE_SIZE, 1, black_color, black_color
        
        ' Move to new position
        px = newX
        py = newY
        
        ' Clear levitation after move (one-time use)
        levitating = 0
        
        ' Update only changed visible areas (fog of war)
        GOSUB UpdateFogOfWar
        
        ' Save current position for next erase
        oldPx = px
        oldPy = py
        
        ' Check win condition
        IF bombs_found >= 3 THEN
          ' Victory fanfare - ascending tones
          PLAY TONE 500, 100, 50
          PAUSE 100
          PLAY TONE 600, 100, 50
          PAUSE 100
          PLAY TONE 700, 100, 50
          PAUSE 100
          PLAY TONE 800, 200, 50
          
          CLS
          TEXT 160, 120, "YOU WIN!", "CM", 1, 1, RGB(0, 255, 0)
          TEXT 160, 140, "All bombs found!", "CM", 1, 1, RGB(255, 255, 255)
          PAUSE 2000
          
          GOSUB RevealMaze
          TEXT 160, 310, "Play again (Y/N)?", "CM", 1, 1, RGB(255, 255, 255)
          
          DO
            k$ = INKEY$
            IF UCASE$(k$) = "Y" THEN
              GOTO GameStart
            ELSE IF UCASE$(k$) = "N" THEN
              END
            END IF
          LOOP
        END IF
        
        ' Wait for ALL keys to be released
        PAUSE 150
        DO WHILE INKEY$ <> ""
          PAUSE 20
        LOOP
      END IF
    END IF
    
    SkipMove:
  END IF
  
  PAUSE 20
LOOP

END

GenerateMaze:
  LOCAL x, y, cx, cy, nx, ny, dir, done, idx, check_idx
  LOCAL stack_x(100), stack_y(100), stack_top
  LOCAL directions(4), dir_count, i
  
  ' Start with ALL WALLS
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      idx = y * MAZE_WIDTH + x
      maze(idx) = WALL
    NEXT x
  NEXT y
  
  ' Start carving from (1,1)
  cx = 1
  cy = 1
  idx = cy * MAZE_WIDTH + cx
  maze(idx) = FLOOR
  stack_top = 0
  done = 0
  
  DO WHILE done = 0
    ' Find unvisited neighbors (2 cells away in each direction)
    dir_count = 0
    
    ' Check North (y-2)
    IF cy >= 3 THEN
      check_idx = (cy - 2) * MAZE_WIDTH + cx
      IF maze(check_idx) = WALL THEN
        directions(dir_count) = 0
        dir_count = dir_count + 1
      END IF
    END IF
    
    ' Check South (y+2)  
    IF cy <= MAZE_HEIGHT - 4 THEN
      check_idx = (cy + 2) * MAZE_WIDTH + cx
      IF maze(check_idx) = WALL THEN
        directions(dir_count) = 1
        dir_count = dir_count + 1
      END IF
    END IF
    
    ' Check West (x-2)
    IF cx >= 3 THEN
      check_idx = cy * MAZE_WIDTH + (cx - 2)
      IF maze(check_idx) = WALL THEN
        directions(dir_count) = 2
        dir_count = dir_count + 1
      END IF
    END IF
    
    ' Check East (x+2)
    IF cx <= MAZE_WIDTH - 4 THEN
      check_idx = cy * MAZE_WIDTH + (cx + 2)
      IF maze(check_idx) = WALL THEN
        directions(dir_count) = 3
        dir_count = dir_count + 1
      END IF
    END IF
    
    IF dir_count > 0 THEN
      ' Choose random direction
      dir = directions(INT(RND * dir_count))
      
      ' Carve corridor in that direction
      IF dir = 0 THEN ' North
        idx = (cy - 1) * MAZE_WIDTH + cx
        maze(idx) = FLOOR
        idx = (cy - 2) * MAZE_WIDTH + cx
        maze(idx) = FLOOR
        cy = cy - 2
      ELSE IF dir = 1 THEN ' South
        idx = (cy + 1) * MAZE_WIDTH + cx
        maze(idx) = FLOOR
        idx = (cy + 2) * MAZE_WIDTH + cx
        maze(idx) = FLOOR
        cy = cy + 2
      ELSE IF dir = 2 THEN ' West
        idx = cy * MAZE_WIDTH + (cx - 1)
        maze(idx) = FLOOR
        idx = cy * MAZE_WIDTH + (cx - 2)
        maze(idx) = FLOOR
        cx = cx - 2
      ELSE IF dir = 3 THEN ' East
        idx = cy * MAZE_WIDTH + (cx + 1)
        maze(idx) = FLOOR
        idx = cy * MAZE_WIDTH + (cx + 2)
        maze(idx) = FLOOR
        cx = cx + 2
      END IF
      
      ' Push to stack
      stack_x(stack_top) = cx
      stack_y(stack_top) = cy
      stack_top = stack_top + 1
      
      ' Safety check
      IF stack_top >= 95 THEN done = 1
      
    ELSE
      ' Backtrack
      IF stack_top > 0 THEN
        stack_top = stack_top - 1
        cx = stack_x(stack_top)
        cy = stack_y(stack_top)
      ELSE
        done = 1
      END IF
    END IF
  LOOP
  
  ' Post-processing: Create rooms by removing some walls
  ' This makes corridors touch and creates open areas
  LOCAL room_count, rx, ry, rw, rh, wall_remove_count
  
  ' Create 4-6 larger rooms
  FOR room_count = 1 TO INT(RND * 3) + 4
    rx = INT(RND * (MAZE_WIDTH - 8)) + 2
    ry = INT(RND * (MAZE_HEIGHT - 8)) + 2
    rw = INT(RND * 3) + 3  ' 3-5 tiles wide
    rh = INT(RND * 3) + 3  ' 3-5 tiles tall
    
    ' Clear out walls in this area
    FOR y = ry TO ry + rh
      FOR x = rx TO rx + rw
        IF x > 0 AND x < MAZE_WIDTH - 1 AND y > 0 AND y < MAZE_HEIGHT - 1 THEN
          idx = y * MAZE_WIDTH + x
          maze(idx) = FLOOR
        END IF
      NEXT x
    NEXT y
  NEXT room_count
  
  ' Remove random walls to create connections (30-40 walls)
  FOR wall_remove_count = 1 TO INT(RND * 11) + 30
    x = INT(RND * (MAZE_WIDTH - 2)) + 1
    y = INT(RND * (MAZE_HEIGHT - 2)) + 1
    idx = y * MAZE_WIDTH + x
    
    ' Only remove if it's currently a wall
    IF maze(idx) = WALL THEN
      maze(idx) = FLOOR
    END IF
  NEXT wall_remove_count
  
  RETURN

PlaceObjects:
  LOCAL x, y, idx, i, placed
  
  ' Clear all objects
  FOR idx = 0 TO MAZE_WIDTH * MAZE_HEIGHT - 1
    objects(idx) = OBJ_NONE
  NEXT idx
  
  ' Place 3 bombs
  FOR i = 1 TO 3
    placed = 0
    DO WHILE placed = 0
      x = INT(RND * (MAZE_WIDTH - 2)) + 1
      y = INT(RND * (MAZE_HEIGHT - 2)) + 1
      idx = y * MAZE_WIDTH + x
      
      IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
        objects(idx) = OBJ_BOMB
        placed = 1
      END IF
    LOOP
  NEXT i
  
  ' Place 1 key
  placed = 0
  DO WHILE placed = 0
    x = INT(RND * (MAZE_WIDTH - 2)) + 1
    y = INT(RND * (MAZE_HEIGHT - 2)) + 1
    idx = y * MAZE_WIDTH + x
    
    IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
      objects(idx) = OBJ_KEY
      placed = 1
    END IF
  LOOP
  
  ' Place 1 sword
  placed = 0
  DO WHILE placed = 0
    x = INT(RND * (MAZE_WIDTH - 2)) + 1
    y = INT(RND * (MAZE_HEIGHT - 2)) + 1
    idx = y * MAZE_WIDTH + x
    
    IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
      objects(idx) = OBJ_SWORD
      placed = 1
    END IF
  LOOP
  
  ' Place 9 beasts
  FOR i = 1 TO 9
    placed = 0
    DO WHILE placed = 0
      x = INT(RND * (MAZE_WIDTH - 2)) + 1
      y = INT(RND * (MAZE_HEIGHT - 2)) + 1
      idx = y * MAZE_WIDTH + x
      
      IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
        objects(idx) = OBJ_BEAST
        placed = 1
      END IF
    LOOP
  NEXT i
  
  ' Place 3-5 doors
  FOR i = 1 TO INT(RND * 3) + 3
    placed = 0
    DO WHILE placed = 0
      x = INT(RND * (MAZE_WIDTH - 2)) + 1
      y = INT(RND * (MAZE_HEIGHT - 2)) + 1
      idx = y * MAZE_WIDTH + x
      
      IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
        objects(idx) = OBJ_DOOR
        placed = 1
      END IF
    LOOP
  NEXT i
  
  ' Place 3-5 pits
  FOR i = 1 TO INT(RND * 3) + 3
    placed = 0
    DO WHILE placed = 0
      x = INT(RND * (MAZE_WIDTH - 2)) + 1
      y = INT(RND * (MAZE_HEIGHT - 2)) + 1
      idx = y * MAZE_WIDTH + x
      
      IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
        objects(idx) = OBJ_PIT
        placed = 1
      END IF
    LOOP
  NEXT i
  
  RETURN

PlacePlayer:
  LOCAL x, y, placed, idx
  placed = 0
  
  DO WHILE placed = 0
    x = INT(RND * (MAZE_WIDTH - 2)) + 1
    y = INT(RND * (MAZE_HEIGHT - 2)) + 1
    idx = y * MAZE_WIDTH + x
    
    IF maze(idx) = FLOOR AND objects(idx) = OBJ_NONE THEN
      px = x
      py = y
      placed = 1
    END IF
  LOOP
  
  RETURN

DrawMaze:
  LOCAL x, y, sx, sy, idx, cx, cy
  LOCAL y_offset
  y_offset = 12  ' Offset maze down for status bar
  
  CLS
  
  ' Draw black background to fill entire screen (320x320)
  BOX 0, 0, 320, 320, 1, black_color, black_color
  
  ' Draw walls - BOX x, y, width, height, line_width, color, fill_color
  ' Only draw within visibility radius (fog of war)
  LOCAL visibility_radius, dx, dy, dist
  visibility_radius = 3  ' Can see 3 tiles in each direction
  
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      ' Check if this tile is within visibility radius
      dx = ABS(x - px)
      dy = ABS(y - py)
      dist = SQR(dx * dx + dy * dy)
      
      IF dist <= visibility_radius THEN
        idx = y * MAZE_WIDTH + x
        IF maze(idx) = WALL THEN
          sx = x * TILE_SIZE
          sy = y * TILE_SIZE + y_offset
          BOX sx, sy, TILE_SIZE, TILE_SIZE, 1, wall_color, wall_color
        END IF
      END IF
    NEXT x
  NEXT y
  
  ' Draw objects - only within visibility radius
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      ' Check if this tile is within visibility radius
      dx = ABS(x - px)
      dy = ABS(y - py)
      dist = SQR(dx * dx + dy * dy)
      
      IF dist <= visibility_radius THEN
        idx = y * MAZE_WIDTH + x
        IF objects(idx) <> OBJ_NONE THEN
          cx = x * TILE_SIZE + TILE_SIZE \ 2
          cy = y * TILE_SIZE + TILE_SIZE \ 2 + y_offset
        
        IF objects(idx) = OBJ_BOMB THEN
          ' Red circle with fuse (smaller)
          CIRCLE cx, cy, 3, 1, 1, bomb_color, bomb_color
          LINE cx, cy - 3, cx, cy - 5, 1, RGB(255, 255, 0)
        ELSE IF objects(idx) = OBJ_KEY THEN
          ' Yellow key shape (smaller)
          CIRCLE cx - 1, cy, 1, 1, 1, key_color, key_color
          LINE cx, cy, cx + 3, cy, 2, key_color
        ELSE IF objects(idx) = OBJ_SWORD THEN
          ' Silver sword (smaller)
          LINE cx - 3, cy, cx + 3, cy, 2, sword_color
          LINE cx + 3, cy, cx + 4, cy, 1, RGB(150, 100, 0)
        ELSE IF objects(idx) = OBJ_BEAST THEN
          ' Magenta monster blob (smaller)
          CIRCLE cx, cy, 4, 1, 1, beast_color, beast_color
          CIRCLE cx - 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
          CIRCLE cx + 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
        ELSE IF objects(idx) = OBJ_DOOR THEN
          ' Brown door (vertical rectangle)
          BOX cx - 3, cy - 4, 6, 8, 1, door_color, door_color
          ' Door handle (yellow)
          CIRCLE cx + 2, cy, 1, 1, 1, key_color, key_color
        ELSE IF objects(idx) = OBJ_PIT THEN
          ' Dark gray pit (square hole)
          BOX cx - 4, cy - 4, 8, 8, 1, pit_color, pit_color
          ' Inner darker area
          BOX cx - 2, cy - 2, 4, 4, 1, RGB(32, 32, 32), RGB(32, 32, 32)
        END IF
        END IF  ' Close objects(idx) <> OBJ_NONE
      END IF  ' Close visibility check
    NEXT x
  NEXT y
  
  ' Draw player
  GOSUB DrawPlayer
  
  RETURN

DrawPlayer:
  LOCAL sx, sy, cx, cy, y_offset
  y_offset = 12  ' Match maze offset
  
  ' Calculate center of tile
  cx = px * TILE_SIZE + TILE_SIZE \ 2
  cy = py * TILE_SIZE + TILE_SIZE \ 2 + y_offset
  
  ' Draw simple stick figure (green) - scaled for 12px tiles
  ' Head
  CIRCLE cx, cy - 3, 1, 1, 1, player_color, player_color
  
  ' Body (vertical line)
  LINE cx, cy - 2, cx, cy + 3, 1, player_color
  
  ' Arms (horizontal line)
  LINE cx - 2, cy, cx + 2, cy, 1, player_color
  
  ' Legs
  LINE cx, cy + 3, cx - 2, cy + 5, 1, player_color
  LINE cx, cy + 3, cx + 2, cy + 5, 1, player_color
  
  ' Sword (yellow/gold) - held in right hand
  LINE cx + 2, cy, cx + 4, cy - 2, 1, RGB(255, 255, 0)
  
  RETURN

UpdateFogOfWar:
  LOCAL x, y, idx, dx, dy, dist, is_visible, was_visible
  LOCAL sx, sy, cx, cy, y_offset, visibility_radius
  y_offset = 12
  visibility_radius = 3
  
  ' Check each tile
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      idx = y * MAZE_WIDTH + x
      
      ' Calculate if this tile is currently visible
      dx = ABS(x - px)
      dy = ABS(y - py)
      dist = SQR(dx * dx + dy * dy)
      is_visible = (dist <= visibility_radius)
      was_visible = visible(idx)
      
      ' Only update if visibility changed
      IF is_visible <> was_visible THEN
        sx = x * TILE_SIZE
        sy = y * TILE_SIZE + y_offset
        cx = sx + TILE_SIZE \ 2
        cy = sy + TILE_SIZE \ 2
        
        IF is_visible THEN
          ' Tile just became visible - draw it
          IF maze(idx) = WALL THEN
            BOX sx, sy, TILE_SIZE, TILE_SIZE, 1, wall_color, wall_color
          END IF
          
          ' Draw object if present
          IF objects(idx) = OBJ_BOMB THEN
            CIRCLE cx, cy, 3, 1, 1, bomb_color, bomb_color
            LINE cx, cy - 3, cx, cy - 5, 1, RGB(255, 255, 0)
          ELSE IF objects(idx) = OBJ_KEY THEN
            CIRCLE cx - 1, cy, 1, 1, 1, key_color, key_color
            LINE cx, cy, cx + 3, cy, 2, key_color
          ELSE IF objects(idx) = OBJ_SWORD THEN
            LINE cx - 3, cy, cx + 3, cy, 2, sword_color
            LINE cx + 3, cy, cx + 4, cy, 1, RGB(150, 100, 0)
          ELSE IF objects(idx) = OBJ_BEAST THEN
            CIRCLE cx, cy, 4, 1, 1, beast_color, beast_color
            CIRCLE cx - 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
            CIRCLE cx + 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
          ELSE IF objects(idx) = OBJ_DOOR THEN
            BOX cx - 3, cy - 4, 6, 8, 1, door_color, door_color
            CIRCLE cx + 2, cy, 1, 1, 1, key_color, key_color
          ELSE IF objects(idx) = OBJ_PIT THEN
            BOX cx - 4, cy - 4, 8, 8, 1, pit_color, pit_color
            BOX cx - 2, cy - 2, 4, 4, 1, RGB(32, 32, 32), RGB(32, 32, 32)
          END IF
        ELSE
          ' Tile just became hidden - erase it with black
          BOX sx, sy, TILE_SIZE, TILE_SIZE, 1, black_color, black_color
        END IF
        
        ' Update visibility tracking
        visible(idx) = is_visible
      END IF
    NEXT x
  NEXT y
  
  ' Always redraw player on top
  GOSUB DrawPlayer
  
  RETURN

RevealMaze:
  ' Draw entire maze without fog of war
  LOCAL x, y, sx, sy, idx, cx, cy, y_offset
  y_offset = 12
  
  CLS
  BOX 0, 0, 320, 320, 1, black_color, black_color
  
  ' Draw all walls
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      idx = y * MAZE_WIDTH + x
      IF maze(idx) = WALL THEN
        sx = x * TILE_SIZE
        sy = y * TILE_SIZE + y_offset
        BOX sx, sy, TILE_SIZE, TILE_SIZE, 1, wall_color, wall_color
      END IF
    NEXT x
  NEXT y
  
  ' Draw all objects
  FOR y = 0 TO MAZE_HEIGHT - 1
    FOR x = 0 TO MAZE_WIDTH - 1
      idx = y * MAZE_WIDTH + x
      IF objects(idx) <> OBJ_NONE THEN
        cx = x * TILE_SIZE + TILE_SIZE \ 2
        cy = y * TILE_SIZE + TILE_SIZE \ 2 + y_offset
        
        IF objects(idx) = OBJ_BOMB THEN
          CIRCLE cx, cy, 3, 1, 1, bomb_color, bomb_color
          LINE cx, cy - 3, cx, cy - 5, 1, RGB(255, 255, 0)
        ELSE IF objects(idx) = OBJ_KEY THEN
          CIRCLE cx - 1, cy, 1, 1, 1, key_color, key_color
          LINE cx, cy, cx + 3, cy, 2, key_color
        ELSE IF objects(idx) = OBJ_SWORD THEN
          LINE cx - 3, cy, cx + 3, cy, 2, sword_color
          LINE cx + 3, cy, cx + 4, cy, 1, RGB(150, 100, 0)
        ELSE IF objects(idx) = OBJ_BEAST THEN
          CIRCLE cx, cy, 4, 1, 1, beast_color, beast_color
          CIRCLE cx - 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
          CIRCLE cx + 1, cy - 1, 1, 1, 1, RGB(0, 0, 0), RGB(0, 0, 0)
        ELSE IF objects(idx) = OBJ_DOOR THEN
          BOX cx - 3, cy - 4, 6, 8, 1, door_color, door_color
          CIRCLE cx + 2, cy, 1, 1, 1, key_color, key_color
        ELSE IF objects(idx) = OBJ_PIT THEN
          BOX cx - 4, cy - 4, 8, 8, 1, pit_color, pit_color
          BOX cx - 2, cy - 2, 4, 4, 1, RGB(32, 32, 32), RGB(32, 32, 32)
        END IF
      END IF
    NEXT x
  NEXT y
  
  ' Draw player
  GOSUB DrawPlayer
  
  RETURN

DrawStatus:
  LOCAL elapsed, remaining, mins, secs, status_text$
  
  ' Calculate time remaining - TIMER is in milliseconds, divide by 1000
  elapsed = INT((TIMER - start_time) / 1000)
  remaining = game_time - elapsed
  IF remaining < 0 THEN remaining = 0
  
  mins = INT(remaining / 60)
  secs = INT(remaining MOD 60)
  
  ' Draw status bar at top of screen (above maze) - taller to clear descenders
  BOX 0, 0, 320, 12, 1, RGB(0, 0, 0), RGB(0, 0, 0)
  
  ' Format and display main status on the left
  status_text$ = "TIME:" + STR$(mins) + ":" + RIGHT$("0" + STR$(secs), 2)
  status_text$ = status_text$ + " BOMBS:" + STR$(bombs_found) + "/3"
  
  IF has_key = 1 THEN
    status_text$ = status_text$ + " KEY"
  END IF
  
  IF has_sword = 1 THEN
    status_text$ = status_text$ + " SWORD"
  END IF
  
  TEXT 2, 2, status_text$, "LT", 1, 1, RGB(255, 255, 255)
  
  ' Draw levitation indicator on top right
  IF levitating = 1 THEN
    TEXT 280, 2, "*LEV*", "LT", 1, 1, RGB(255, 255, 0)
  END IF
  
  RETURN
