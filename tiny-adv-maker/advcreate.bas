REM Adventure Creator for PicoMite
REM Creates adventures in .ADV format with random skeleton generator
REM Save as ADVCREATE.BAS

DIM rooms$(50, 6)     ' ID, Name, Desc, Exits, Special, Used
DIM objects$(50, 5)   ' ID, Room, Name, Desc, Properties  
DIM responses$(100, 4) ' Trigger, Condition, Response, Action
DIM settings$(10, 2)  ' Key, Value pairs

DIM numRooms, numObjects, numResponses
DIM theme$, minRooms, maxRooms

' Theme data for generator
DIM themeNames$(5), themeAdj$(5), themeRooms$(5), themeDetails$(5)
DIM themeObjects$(5), themeWeapons$(5), themeTitles$(5)

numRooms = 0
numObjects = 0  
numResponses = 0

' Initialize theme data
GOSUB InitializeThemes

CLS
PRINT "=== PicoMite Adventure Creator ==="
PRINT "Creates interactive text adventures with random generation"
PRINT

MainMenu:
CLS
PRINT "Adventure Creator - Main Menu"
PRINT "Current: "; STR$(numRooms); " rooms, "; STR$(numObjects); " objects"
PRINT
PRINT "1) Edit Settings"
PRINT "2) Create/Edit Rooms" 
PRINT "3) Place Objects"
PRINT "4) Add Custom Responses"
PRINT "5) Generate Random Skeleton"
PRINT "6) Test Adventure"
PRINT "7) Save Adventure"
PRINT "8) Load Adventure" 
PRINT "9) Clear All Data"
PRINT "0) Quit"
PRINT
INPUT "Choice: ", choice

SELECT CASE choice
  CASE 1: GOSUB EditSettings
  CASE 2: GOSUB EditRooms
  CASE 3: GOSUB PlaceObjects
  CASE 4: GOSUB EditResponses
  CASE 5: GOSUB GenerateSkeleton
  CASE 6: GOSUB TestAdventure
  CASE 7: GOSUB SaveAdventure
  CASE 8: GOSUB LoadAdventure
  CASE 9: GOSUB ClearAll
  CASE 0: PRINT "Goodbye!": END
  CASE ELSE: PRINT "Invalid choice"
END SELECT
PAUSE 1000
GOTO MainMenu

EditSettings:
CLS
PRINT "=== Adventure Settings ==="
PRINT
PRINT "Current Title: "; settings$(1, 1)
PRINT "Adventure Title: ";
INPUT title$
IF title$ <> "" THEN settings$(1, 1) = title$

PRINT "Current Author: "; settings$(2, 1)
PRINT "Author Name: ";  
INPUT author$
IF author$ <> "" THEN settings$(2, 1) = author$

PRINT "Current Start Room: "; settings$(3, 1)
PRINT "Starting Room ID (1-50): ";
INPUT startroom$
IF VAL(startroom$) > 0 AND VAL(startroom$) <= 50 THEN settings$(3, 1) = startroom$

PRINT "Settings updated!"
RETURN

EditRooms:
CLS
PRINT "=== Room Editor ==="
PRINT
PRINT "Current rooms: "; STR$(numRooms)
PRINT "Room ID to edit (1-50, 0 to list): ";
INPUT id

IF id = 0 THEN
  GOSUB ListRooms
  RETURN
END IF

IF id < 1 OR id > 50 THEN 
  PRINT "Invalid room ID"
  RETURN
END IF

PRINT "Editing Room "; STR$(id)
PRINT "Current Name: "; rooms$(id, 1)
PRINT "Room Name: ";
INPUT name$
IF name$ <> "" THEN rooms$(id, 1) = name$

PRINT "Current Description: "; rooms$(id, 2)
PRINT "Description: ";
INPUT desc$
IF desc$ <> "" THEN rooms$(id, 2) = desc$

PRINT "Current Exits (N,S,E,W): "; rooms$(id, 3)
PRINT "Exits (North,South,East,West room IDs, 0=none): ";
INPUT exits$
IF exits$ <> "" THEN rooms$(id, 3) = exits$

rooms$(id, 5) = "1"  ' Mark as used
IF numRooms < id THEN numRooms = id
PRINT "Room "; STR$(id); " saved!"
RETURN

ListRooms:
CLS
PRINT "=== Room List ==="
FOR i = 1 TO 50
  IF rooms$(i, 5) = "1" THEN
    PRINT STR$(i); ": "; rooms$(i, 1)
  END IF
NEXT i
PRINT
PRINT "Press any key to continue..."
WHILE INKEY$ = "": WEND
RETURN

PlaceObjects:
CLS
PRINT "=== Object Placement ==="
PRINT
PRINT "Current objects: "; STR$(numObjects)
PRINT "1) Add new object"
PRINT "2) List objects"
PRINT "0) Return to main menu"
INPUT choice

IF choice = 2 THEN
  GOSUB ListObjects
  RETURN
ELSEIF choice <> 1 THEN
  RETURN
END IF

numObjects = numObjects + 1
PRINT "Object "; STR$(numObjects)
PRINT "Object ID/Name: ";
INPUT objects$(numObjects, 0)
PRINT "Starting Room (1-50): ";
INPUT objects$(numObjects, 1)
PRINT "Display Name: ";
INPUT objects$(numObjects, 2)
PRINT "Description: ";
INPUT objects$(numObjects, 3)
PRINT "Properties (takeable,weapon,etc): ";
INPUT objects$(numObjects, 4)
PRINT "Object added!"
RETURN

ListObjects:
CLS
PRINT "=== Object List ==="
FOR i = 1 TO numObjects
  IF objects$(i, 0) <> "" THEN
    PRINT objects$(i, 0); " in room "; objects$(i, 1); ": "; objects$(i, 2)
  END IF
NEXT i
PRINT
PRINT "Press any key to continue..."
WHILE INKEY$ = "": WEND
RETURN

EditResponses:
CLS
PRINT "=== Custom Responses ==="
PRINT
PRINT "This feature allows you to add special responses"
PRINT "to player commands. Advanced feature - see manual."
PRINT
PRINT "Current responses: "; STR$(numResponses)
PRINT "Add response? (Y/N): ";
INPUT add$
IF UCASE$(add$) <> "Y" THEN RETURN

numResponses = numResponses + 1
PRINT "Response "; STR$(numResponses)
PRINT "Trigger (e.g. 'examine door'): ";
INPUT responses$(numResponses, 0)
PRINT "Condition (leave blank for always): ";
INPUT responses$(numResponses, 1)
PRINT "Response text: ";
INPUT responses$(numResponses, 2)
PRINT "Action (leave blank for none): ";
INPUT responses$(numResponses, 3)
PRINT "Response added!"
RETURN

GenerateSkeleton:
CLS
PRINT "=== Adventure Skeleton Generator ==="
PRINT "This will create a basic adventure framework"
PRINT "that you can then customize using other menu options."
PRINT

IF numRooms > 0 THEN
  PRINT "Warning: This will replace your current adventure!"
  PRINT "Continue? (Y/N): ";
  INPUT confirm$
  IF UCASE$(confirm$) <> "Y" THEN RETURN
  GOSUB ClearAll
END IF

PRINT "Choose adventure type:"
PRINT "1) Haunted House (8-12 rooms)"
PRINT "2) Dungeon Crawl (10-15 rooms)"  
PRINT "3) Space Station (6-10 rooms)"
PRINT "4) Medieval Castle (12-20 rooms)"
PRINT "5) Surprise Me! (Random theme)"
INPUT "Type: ", advType

PRINT "Generating skeleton..."
GOSUB CreateSkeletonAdventure

PRINT "Skeleton complete!"
PRINT "Generated "; STR$(numRooms); " rooms with "; STR$(numObjects); " objects."
PRINT "Use menu options 1-4 to customize your adventure."
PRINT "Press any key to continue..."
WHILE INKEY$ = "": WEND
RETURN

CreateSkeletonAdventure:
SELECT CASE advType
  CASE 1: 
    theme$ = "haunted"
    minRooms = 8
    maxRooms = 12
  CASE 2: 
    theme$ = "dungeon"
    minRooms = 10
    maxRooms = 15
  CASE 3: 
    theme$ = "space"
    minRooms = 6
    maxRooms = 10
  CASE 4: 
    theme$ = "castle"
    minRooms = 12
    maxRooms = 20
  CASE 5: 
    advType = INT(RND * 4) + 1
    GOTO CreateSkeletonAdventure
END SELECT

' Generate basic settings
settings$(1, 1) = GenerateTitle$(theme$)
settings$(2, 1) = "Adventure Creator"
settings$(3, 1) = "1"

numRooms = minRooms + INT(RND * (maxRooms - minRooms + 1))
GOSUB GenerateRooms
GOSUB GenerateObjects
GOSUB GenerateBasicResponses
RETURN

GenerateRooms:
FOR i = 1 TO numRooms
  rooms$(i, 1) = GenerateRoomName$(theme$)
  rooms$(i, 2) = GenerateRoomDesc$(rooms$(i, 1), theme$)
  rooms$(i, 5) = "1"  ' Mark as used
  
  ' Connect rooms in a linear path with some branches
  IF i > 1 THEN
    rooms$(i, 3) = STR$(i-1) + ",0,0,0"  ' Connect north to previous
    ' Update previous room to connect south
    exits$ = rooms$(i-1, 3)
    IF exits$ = "" THEN exits$ = "0,0,0,0"
    rooms$(i-1, 3) = LEFT$(exits$, 2) + STR$(i) + MID$(exits$, 3)
  ELSE
    rooms$(i, 3) = "0,0,0,0"  ' First room
  END IF
  
  ' Add some random side connections
  IF RND > 0.7 AND i > 2 THEN
    ' Random connection to earlier room
    target = INT(RND * (i - 2)) + 1
    IF RND > 0.5 THEN
      ' East/West connection
      exits$ = rooms$(i, 3)
      rooms$(i, 3) = LEFT$(exits$, 4) + STR$(target) + ",0"
    END IF
  END IF
NEXT i
RETURN

GenerateObjects:
' Place 3-5 random objects
objCount = 3 + INT(RND * 3)
FOR i = 1 TO objCount
  numObjects = numObjects + 1
  room = INT(RND * numRooms) + 1
  
  IF i = 1 THEN
    ' Always place a weapon early
    obj$ = PickRandom$(themeWeapons$(GetThemeIndex(theme$)))
  ELSE
    obj$ = PickRandom$(themeObjects$(GetThemeIndex(theme$)))
  END IF
  
  objects$(numObjects, 0) = obj$
  objects$(numObjects, 1) = STR$(room)
  objects$(numObjects, 2) = obj$
  objects$(numObjects, 3) = "A " + obj$ + " lies here."
  objects$(numObjects, 4) = "takeable"
NEXT i
RETURN

GenerateBasicResponses:
' Add some basic responses
numResponses = 1
responses$(1, 0) = "help"
responses$(1, 1) = ""
responses$(1, 2) = "Try: NORTH, SOUTH, EAST, WEST, LOOK, TAKE, EXAMINE, INVENTORY"
responses$(1, 3) = ""
RETURN

FUNCTION GenerateTitle$(theme$)
  themeIndex = GetThemeIndex(theme$)
  GenerateTitle$ = PickRandom$(themeTitles$(themeIndex))
END FUNCTION

FUNCTION GenerateRoomName$(theme$)
  themeIndex = GetThemeIndex(theme$)
  adj$ = PickRandom$(themeAdj$(themeIndex))
  room$ = PickRandom$(themeRooms$(themeIndex))
  GenerateRoomName$ = adj$ + " " + room$
END FUNCTION

FUNCTION GenerateRoomDesc$(roomName$, theme$)
  themeIndex = GetThemeIndex(theme$)
  detail$ = PickRandom$(themeDetails$(themeIndex))
  GenerateRoomDesc$ = "You are in a " + LCASE$(roomName$) + ". " + detail$ + "."
END FUNCTION

FUNCTION GetThemeIndex(theme$)
  FOR i = 1 TO 5
    IF themeNames$(i) = theme$ THEN
      GetThemeIndex = i
      EXIT FUNCTION
    END IF
  NEXT i
  GetThemeIndex = 1
END FUNCTION

FUNCTION PickRandom$(list$)
  items = 1
  FOR i = 1 TO LEN(list$)
    IF MID$(list$, i, 1) = "," THEN items = items + 1
  NEXT i
  
  choice = INT(RND * items) + 1
  current = 1
  start = 1
  
  FOR i = 1 TO LEN(list$)
    IF MID$(list$, i, 1) = "," THEN
      IF current = choice THEN
        PickRandom$ = MID$(list$, start, i - start)
        EXIT FUNCTION
      END IF
      current = current + 1
      start = i + 1
    END IF
  NEXT i
  
  ' Return last item if we didn't find a comma
  PickRandom$ = MID$(list$, start)
END FUNCTION

InitializeThemes:
' Theme 1: Haunted
themeNames$(1) = "haunted"
themeAdj$(1) = "Dark,Creepy,Musty,Abandoned,Eerie,Cold,Shadowy"
themeRooms$(1) = "Hallway,Bedroom,Kitchen,Basement,Attic,Library,Parlor,Study"
themeDetails$(1) = "Strange noises echo here,Dust motes dance in pale light,An odd chill fills the air,Cobwebs hang from the corners"
themeObjects$(1) = "candle,book,portrait,mirror,chair,chest"
themeWeapons$(1) = "rusty sword,wooden stake,holy water,silver cross"
themeTitles$(1) = "The Haunted Manor,Ghost House Mystery,Spirits of Ravenwood,The Cursed Estate"

' Theme 2: Dungeon  
themeNames$(2) = "dungeon"
themeAdj$(2) = "Damp,Stone,Ancient,Narrow,Dark,Torch-lit"
themeRooms$(2) = "Corridor,Chamber,Cell,Armory,Shrine,Vault,Tunnel"
themeDetails$(2) = "Water drips from the ceiling,Moss grows on the walls,Strange symbols are carved here,Chains rattle in the distance"
themeObjects$(2) = "torch,rope,coins,gems,scroll,bones"
themeWeapons$(2) = "sword,dagger,magic wand,shield,mace"
themeTitles$(2) = "Depths of Despair,The Lost Catacombs,Dragon's Lair,The Forgotten Dungeon"

' Theme 3: Space
themeNames$(3) = "space"
themeAdj$(3) = "Sterile,Metallic,Humming,Bright,Curved,Silent"
themeRooms$(3) = "Bridge,Quarters,Engine Room,Airlock,Lab,Cargo Bay"
themeDetails$(3) = "Lights blink on control panels,Computers chirp softly,Air recyclers hum,Warning lights flash"
themeObjects$(3) = "datapad,energy cell,circuit,scanner,tool"
themeWeapons$(3) = "laser pistol,plasma rifle,force shield,stun baton"
themeTitles$(3) = "Station Alpha Crisis,Lost in Space,The Derelict Ship,Cosmic Emergency"

' Theme 4: Castle
themeNames$(4) = "castle"
themeAdj$(4) = "Grand,Stone,Noble,Ancient,Majestic,Royal"
themeRooms$(4) = "Throne Room,Courtyard,Tower,Dungeon,Hall,Chapel,Armory"
themeDetails$(4) = "Banners hang from the walls,Sunlight streams through windows,Guards patrol nearby,Servants bustle about"
themeObjects$(4) = "crown,scepter,tapestry,chalice,armor,scroll"
themeWeapons$(4) = "royal sword,knight's shield,crossbow,battle axe"
themeTitles$(4) = "The Royal Quest,Castle of Secrets,The King's Challenge,Medieval Mystery"

' Theme 5: (duplicate for random selection)
themeNames$(5) = "mystery"
themeAdj$(5) = "Mysterious,Hidden,Secret,Strange,Unusual,Puzzling"
themeRooms$(5) = "Room,Chamber,Hall,Study,Vault,Sanctum"
themeDetails$(5) = "Something feels different here,You sense hidden secrets,The air tingles with magic,Ancient powers linger"
themeObjects$(5) = "artifact,crystal,rune,tome,amulet,orb"
themeWeapons$(5) = "enchanted blade,magic staff,crystal sword,power gem"
themeTitles$(5) = "The Mystery Adventure,Secrets Revealed,The Hidden Truth,Ancient Mysteries"
RETURN

TestAdventure:
CLS
PRINT "=== Test Adventure ==="
PRINT "Feature not implemented in this version."
PRINT "Save your adventure and use ADVPLAY.BAS to test it."
PRINT
PRINT "Press any key to continue..."
WHILE INKEY$ = "": WEND
RETURN

SaveAdventure:
CLS
PRINT "=== Save Adventure ==="
PRINT "Filename (without .ADV extension): ";
INPUT filename$
IF filename$ = "" THEN 
  PRINT "Save cancelled"
  RETURN
END IF

filename$ = filename$ + ".ADV"

OPEN filename$ FOR OUTPUT AS #1

' Write header
PRINT #1, "# Generated by PicoMite Adventure Creator"
PRINT #1, "# " + DATE$ + " " + TIME$
PRINT #1, ""

' Write settings
PRINT #1, "[SETTINGS]"
PRINT #1, "title=" + settings$(1, 1)
PRINT #1, "author=" + settings$(2, 1)  
PRINT #1, "startroom=" + settings$(3, 1)
PRINT #1, ""

' Write rooms
PRINT #1, "[ROOMS]"
FOR i = 1 TO 50
  IF rooms$(i, 5) = "1" THEN
    PRINT #1, STR$(i) + "|" + rooms$(i, 1) + "|" + rooms$(i, 2) + "|" + rooms$(i, 3) + "|" + rooms$(i, 4)
  END IF
NEXT i
PRINT #1, ""

' Write objects  
PRINT #1, "[OBJECTS]"
FOR i = 1 TO numObjects
  IF objects$(i, 0) <> "" THEN
    PRINT #1, objects$(i, 0) + "|" + objects$(i, 1) + "|" + objects$(i, 2) + "|" + objects$(i, 3) + "|" + objects$(i, 4)
  END IF
NEXT i
PRINT #1, ""

' Write responses
IF numResponses > 0 THEN
  PRINT #1, "[RESPONSES]"
  FOR i = 1 TO numResponses
    IF responses$(i, 0) <> "" THEN
      PRINT #1, responses$(i, 0) + "|" + responses$(i, 1) + "|" + responses$(i, 2) + "|" + responses$(i, 3)
    END IF
  NEXT i
  PRINT #1, ""
END IF

CLOSE #1
PRINT "Adventure saved as "; filename$
RETURN

LoadAdventure:
CLS
PRINT "=== Load Adventure ==="
PRINT "Adventure file to load: ";
INPUT filename$
IF filename$ = "" THEN 
  PRINT "Load cancelled"
  RETURN
END IF

IF RIGHT$(filename$, 4) <> ".ADV" THEN filename$ = filename$ + ".ADV"

GOSUB ClearAll

ON ERROR GOTO LoadError
OPEN filename$ FOR INPUT AS #1

section$ = ""
DO WHILE NOT EOF(#1)
  LINE INPUT #1, line$
  line$ = TRIM$(line$)
  
  ' Skip comments and blank lines
  IF LEFT$(line$, 1) = "#" OR line$ = "" THEN CONTINUE
  
  ' Check for section headers
  IF LEFT$(line$, 1) = "[" AND RIGHT$(line$, 1) = "]" THEN
    section$ = MID$(line$, 2, LEN(line$) - 2)
    CONTINUE
  END IF
  
  ' Parse based on current section
  SELECT CASE section$
    CASE "SETTINGS": GOSUB ParseSettings
    CASE "ROOMS": GOSUB ParseRooms  
    CASE "OBJECTS": GOSUB ParseObjects
    CASE "RESPONSES": GOSUB ParseResponses
  END SELECT
LOOP
CLOSE #1

PRINT "Adventure loaded successfully!"
PRINT "Loaded "; STR$(numRooms); " rooms and "; STR$(numObjects); " objects"
ON ERROR CLEAR
RETURN

LoadError:
CLOSE #1
PRINT "Error loading file: "; filename$
ON ERROR CLEAR
RETURN

ParseSettings:
pos = INSTR(line$, "=")
IF pos > 0 THEN
  key$ = LEFT$(line$, pos - 1)
  value$ = MID$(line$, pos + 1)
  
  SELECT CASE key$
    CASE "title": settings$(1, 1) = value$
    CASE "author": settings$(2, 1) = value$
    CASE "startroom": settings$(3, 1) = value$
  END SELECT
END IF
RETURN

ParseRooms:
GOSUB SplitLine
IF parts >= 4 THEN
  id = VAL(part$(0))
  IF id > 0 AND id <= 50 THEN
    rooms$(id, 1) = part$(1)  ' Name
    rooms$(id, 2) = part$(2)  ' Description  
    rooms$(id, 3) = part$(3)  ' Exits
    rooms$(id, 5) = "1"       ' Used flag
    IF parts > 4 THEN rooms$(id, 4) = part$(4)  ' Special
    IF id > numRooms THEN numRooms = id
  END IF
END IF
RETURN

ParseObjects:
GOSUB SplitLine
IF parts >= 5 THEN
  numObjects = numObjects + 1
  objects$(numObjects, 0) = part$(0)  ' ID
  objects$(numObjects, 1) = part$(1)  ' Room
  objects$(numObjects, 2) = part$(2)  ' Name
  objects$(numObjects, 3) = part$(3)  ' Description
  objects$(numObjects, 4) = part$(4)  ' Properties
END IF
RETURN

ParseResponses:
GOSUB SplitLine
IF parts >= 4 THEN
  numResponses = numResponses + 1
  responses$(numResponses, 0) = part$(0)  ' Trigger
  responses$(numResponses, 1) = part$(1)  ' Condition
  responses$(numResponses, 2) = part$(2)  ' Response
  responses$(numResponses, 3) = part$(3)  ' Action
END IF
RETURN

SplitLine:
' Split line$ by | into part$(0), part$(1), etc
' Set parts to number of parts found
DIM part$(10)
parts = 0
start = 1
FOR i = 1 TO LEN(line$)
  IF MID$(line$, i, 1) = "|" THEN
    part$(parts) = MID$(line$, start, i - start)
    parts = parts + 1
    start = i + 1
  END IF
NEXT i
' Get final part
IF start <= LEN(line$) THEN
  part$(parts) = MID$(line$, start)
  parts = parts + 1
END IF
RETURN

ClearAll:
' Clear all adventure data
FOR i = 1 TO 50
  FOR j = 1 TO 6
    rooms$(i, j) = ""
  NEXT j
NEXT i

FOR i = 1 TO 50
  FOR j = 0 TO 5
    objects$(i, j) = ""
  NEXT j
NEXT i

FOR i = 1 TO 100
  FOR j = 0 TO 4
    responses$(i, j) = ""
  NEXT j
NEXT i

FOR i = 1 TO 10
  FOR j = 1 TO 2
    settings$(i, j) = ""
  NEXT j
NEXT i

numRooms = 0
numObjects = 0
numResponses = 0
RETURN