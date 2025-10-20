REM Adventure Player for PicoCalc/PicoMite
REM Converted from MMB4L version
REM Maintains full vocabulary, messages, and response systems
REM Optimized for PicoMite memory constraints

OPTION DEFAULT INTEGER

REM ===== GLOBAL ARRAY DECLARATIONS =====
REM Heavily reduced sizes for PicoCalc heap constraints
DIM rooms$(20, 4)
DIM objects$(10, 5)
DIM inventory$(8)
DIM responses$(30, 4)
REM DIM vocabulary$(1, 2)
DIM messages$(10, 2)
DIM gameFlags$(20)
DIM partthing$(6)

REM ===== GLOBAL VARIABLE DECLARATIONS =====
REM Game state variables
DIM gameTitle$, gameAuthor$, gameVersion$
DIM currentRoom, inventoryCount, gameScore, maxScore, startRoom
DIM numResponses, numVocabulary, numMessages, numFlags
DIM numRooms, numObjects

REM File handling variables
DIM filename$, dataLine$, section$, lineCount

REM Parsing temp variables (reused throughout)
DIM key$, value$, position, id, parts, startPos
DIM trimmed$, temp$, s$, t$

REM Room display variables
DIM exits$, exitNorth$, exitSouth$, exitEast$, exitWest$
DIM exitText$, hasExit

REM Command handling variables
DIM command$, objName$, found, newRoom
DIM originalCommand$, normalizedCommand$

REM Response/condition variables
DIM tempCmd$, tempCondition$, tempAction$, tempKey$, tempFlagName$
DIM result$, conditionResult, hasObj, hasFlag, msg$

REM Action parsing variables
DIM singleAction$, actionStart

REM Movement variables
DIM tempStr$, toPos, destRoom

REM Condition parsing variables
DIM leftCondition$, rightCondition$, leftResult, rightResult
DIM andPos, spacePos

REM Loop counters (reused)
DIM i, j, k

REM ===== INITIALIZE VARIABLES =====
inventoryCount = 0
gameScore = 0
maxScore = 100
currentRoom = 0
startRoom = 1
numResponses = 0
numVocabulary = 0
numMessages = 0
numFlags = 0
numRooms = 0
numObjects = 0

REM ===== MAIN PROGRAM START =====
PRINT "=== PicoCalc Adventure Player ==="
PRINT "Enhanced with vocabulary & responses"
PRINT
PRINT "Adventure file to load: ";
LINE INPUT filename$

IF filename$ = "" THEN
  PRINT "No file specified. Goodbye!"
  END
ENDIF

IF UCASE$(RIGHT$(filename$, 4)) <> ".ADV" THEN
  filename$ = filename$ + ".adv"
ENDIF

GOSUB LoadAdventureFile
GOSUB StartGame
END

REM ===== HELPER FUNCTIONS =====

REM FUNCTION TrimCopy$(s$)
REM  LOCAL result$, i, start, finish
REM  result$ = s$
REM  start = 1
REM  finish = LEN(result$)
REM  
  REM Trim leading spaces
REM  FOR i = 1 TO LEN(result$)
REM   IF MID$(result$, i, 1) <> " " THEN
REM      start = i
REM      EXIT FOR
REM    ENDIF
REM  NEXT i
  
  REM Trim trailing spaces
REM  FOR i = LEN(result$) TO 1 STEP -1
REM    IF MID$(result$, i, 1) <> " " THEN
REM      finish = i
REM      EXIT FOR
REM    ENDIF
REM  NEXT i
  
REM  IF finish >= start THEN
REM    TrimCopy$ = MID$(result$, start, finish - start + 1)
REM  ELSE
REM    TrimCopy$ = ""
REM  ENDIF
REM END FUNCTION

FUNCTION UpperCase$(s$)
  LOCAL result$, i, c$, asc_val
  result$ = ""
  FOR i = 1 TO LEN(s$)
    c$ = MID$(s$, i, 1)
    asc_val = ASC(c$)
    IF asc_val >= 97 AND asc_val <= 122 THEN
      result$ = result$ + CHR$(asc_val - 32)
    ELSE
      result$ = result$ + c$
    ENDIF
  NEXT i
  UpperCase$ = result$
END FUNCTION

FUNCTION NormalizeCommand$(cmd$)
  LOCAL result$
  result$ = UpperCase$(cmd$)
  rem print "result$ in NormalizeCommand$ "; result$
  ' Fast path for single-letter cardinal moves
  IF LEN(result$) = 1 THEN
    IF result$ = "N" THEN NormalizeCommand$ = "NORTH": EXIT FUNCTION
    IF result$ = "S" THEN NormalizeCommand$ = "SOUTH": EXIT FUNCTION
    IF result$ = "E" THEN NormalizeCommand$ = "EAST":  EXIT FUNCTION
    IF result$ = "W" THEN NormalizeCommand$ = "WEST":  EXIT FUNCTION
  END IF
  
  REM Movement synonyms
  IF result$ = "GO NORTH" THEN result$ = "NORTH"
  IF result$ = "GO SOUTH" THEN result$ = "SOUTH"
  IF result$ = "GO EAST" THEN result$ = "EAST"
  IF result$ = "GO WEST" THEN result$ = "WEST"
  
  REM Take synonyms
  IF LEFT$(result$, 4) = "GET " THEN result$ = "TAKE " + MID$(result$, 5)
  IF LEFT$(result$, 8) = "PICK UP " THEN result$ = "TAKE " + MID$(result$, 9)
  IF LEFT$(result$, 5) = "GRAB " THEN result$ = "TAKE " + MID$(result$, 6)
  
  REM Examine synonyms
  IF LEFT$(result$, 8) = "LOOK AT " THEN result$ = "EXAMINE " + MID$(result$, 9)
  IF LEFT$(result$, 2) = "X " THEN result$ = "EXAMINE " + MID$(result$, 3)
  IF LEFT$(result$, 5) = "LOOK " THEN result$ = "EXAMINE " + MID$(result$, 6)
  
  REM Use synonyms
  IF LEFT$(result$, 9) = "ACTIVATE " THEN result$ = "USE " + MID$(result$, 10)
  
  REM Attack synonyms
  IF LEFT$(result$, 5) = "KILL " THEN result$ = "ATTACK " + MID$(result$, 6)
  IF LEFT$(result$, 6) = "FIGHT " THEN result$ = "ATTACK " + MID$(result$, 7)
  IF LEFT$(result$, 5) = "SLAY " THEN result$ = "ATTACK " + MID$(result$, 6)
  
  REM Search synonyms
  IF LEFT$(result$, 12) = "INVESTIGATE " THEN result$ = "SEARCH " + MID$(result$, 13)
  
  REM Repair synonyms
  IF LEFT$(result$, 4) = "FIX " THEN result$ = "REPAIR " + MID$(result$, 5)
  
  REM Read synonyms
  IF LEFT$(result$, 5) = "VIEW " THEN result$ = "READ " + MID$(result$, 6)
  
  NormalizeCommand$ = result$
  rem print "In NormalizeCommand$, NormalizeCommand$ = "; NormalizeCommand$
END FUNCTION

REM ===== FILE LOADING SECTION =====

LoadAdventureFile:
  OPEN filename$ FOR INPUT AS #1
  
  section$ = ""
  lineCount = 0
  
  DO WHILE NOT EOF(#1)
    LINE INPUT #1, dataLine$
    lineCount = lineCount + 1
    
    REM Manual trim
    trimmed$ = dataLine$
    DO WHILE LEFT$(trimmed$, 1) = " " AND LEN(trimmed$) > 0
      trimmed$ = MID$(trimmed$, 2)
    LOOP
    DO WHILE RIGHT$(trimmed$, 1) = " " AND LEN(trimmed$) > 0
      trimmed$ = LEFT$(trimmed$, LEN(trimmed$) - 1)
    LOOP
    dataLine$ = trimmed$
    
    REM Skip comments and blank lines
    IF LEFT$(dataLine$, 1) <> "#" AND dataLine$ <> "" THEN
      IF LEFT$(dataLine$, 1) = "[" AND RIGHT$(dataLine$, 1) = "]" THEN
        section$ = MID$(dataLine$, 2, LEN(dataLine$) - 2)
        PRINT "Loading "; section$; "..."
      ELSE
        IF section$ = "SETTINGS" THEN
          GOSUB ParseSettings
        ENDIF
        IF section$ = "ROOMS" THEN
          GOSUB ParseRooms
        ENDIF
        IF section$ = "OBJECTS" THEN
          GOSUB ParseObjects
        ENDIF
        IF section$ = "RESPONSES" THEN
          GOSUB ParseResponses
        ENDIF
        IF section$ = "MESSAGES" THEN
          GOSUB ParseMessages
        ENDIF
      ENDIF
    ENDIF
  LOOP
  
  CLOSE #1
  
  PRINT "DEBUG: Responses loaded:"
  FOR i = 1 TO numResponses
    PRINT i; ": ["; responses$(i,0); "] cond=["; responses$(i,1); "] msg=["; responses$(i,2); "]"
  NEXT i

  REM Set starting room
  currentRoom = startRoom
  PRINT "Loaded "; STR$(lineCount); " total lines"
  PRINT "Rooms: "; STR$(numRooms)
  PRINT "Objects: "; STR$(numObjects)
  PRINT "Responses: "; STR$(numResponses)
  PRINT "Vocabulary: "; STR$(numVocabulary)
  PRINT "Messages: "; STR$(numMessages)
  PRINT

  ' ==== Free parser temps to reclaim heap ====
  ERASE partthing$
  dataLine$ = "": trimmed$ = "": temp$ = "": s$ = "": t$ = ""
  key$ = "": value$ = "": section$ = "": filename$ = ""    

RETURN

REM ===== PARSING SUBROUTINES =====

ParseSettings:
  position = INSTR(dataLine$, "=")
  IF position > 0 THEN
    key$ = LEFT$(dataLine$, position - 1)
    value$ = MID$(dataLine$, position + 1)
    
    IF key$ = "title" THEN
      gameTitle$ = value$
    ENDIF
    IF key$ = "author" THEN
      gameAuthor$ = value$
    ENDIF
    IF key$ = "version" THEN
      gameVersion$ = value$
    ENDIF
    IF key$ = "startroom" THEN
      startRoom = VAL(value$)
    ENDIF
    IF key$ = "maxscore" THEN
      maxScore = VAL(value$)
    ENDIF
  ENDIF
RETURN

ParseRooms:
  GOSUB SplitLine
  IF parts >= 4 THEN
    id = VAL(partthing$(0))
    IF id > 0 AND id <= 15 THEN
      rooms$(id, 1) = partthing$(1)
      rooms$(id, 2) = partthing$(2)
      rooms$(id, 3) = partthing$(3)
      IF parts > 4 THEN
        rooms$(id, 4) = partthing$(4)
      ENDIF
      IF id > numRooms THEN
        numRooms = id
      ENDIF
    ENDIF
  ENDIF
RETURN

ParseObjects:
  GOSUB SplitLine
  IF parts >= 5 THEN
    numObjects = numObjects + 1
    IF numObjects <= 10 THEN
      objects$(numObjects, 0) = partthing$(0)
      objects$(numObjects, 1) = partthing$(1)
      objects$(numObjects, 2) = partthing$(2)
      objects$(numObjects, 3) = partthing$(3)
      objects$(numObjects, 4) = partthing$(4)
    ENDIF
  ENDIF
RETURN

REM ParseVocabulary:
  REM Format: word=synonym1,synonym2,synonym3
REM  position = INSTR(dataLine$, "=")
REM  IF position > 0 THEN
REM    numVocabulary = numVocabulary + 1
REM    IF numVocabulary <= 20 THEN
REM      vocabulary$(numVocabulary, 0) = LEFT$(dataLine$, position - 1)
REM      vocabulary$(numVocabulary, 1) = MID$(dataLine$, position + 1)
REM    ENDIF
REM  ENDIF
REM RETURN

ParseResponses:
  GOSUB SplitLine
  REM PRINT "Response line parts: "; parts; " - "; dataLine$
  IF parts >= 3 THEN
    numResponses = numResponses + 1
    responses$(numResponses, 1) = partthing$(0)
    responses$(numResponses, 2) = partthing$(1)
    responses$(numResponses, 3) = partthing$(2)
    IF parts >= 4 THEN
      responses$(numResponses, 4) = partthing$(3)
    ELSE
      responses$(numResponses, 4) = ""
    ENDIF
  ELSE
    PRINT "SKIPPED - Not enough parts!"
  ENDIF
RETURN

ParseMessages:
  REM Format: key=message
  position = INSTR(dataLine$, "=")
  IF position > 0 THEN
    numMessages = numMessages + 1
    IF numMessages <= 8 THEN
      messages$(numMessages, 0) = LEFT$(dataLine$, position - 1)
      messages$(numMessages, 1) = MID$(dataLine$, position + 1)
    ENDIF
  ENDIF
RETURN

SplitLine:
  REM Split dataLine$ by | into partthing$(0), partthing$(1), etc
  REM Set parts to number of parts found

  parts = 0
  startPos = 1
  
  REM Clear the array
  FOR i = 0 TO 6
    partthing$(i) = ""
  NEXT i
  
  FOR i = 1 TO LEN(dataLine$)
    IF MID$(dataLine$, i, 1) = "|" THEN
      IF parts <= 6 THEN
        partthing$(parts) = MID$(dataLine$, startPos, i - startPos)
      ENDIF
      parts = parts + 1
      startPos = i + 1
    ENDIF
  NEXT i
  
  REM Get final part
  IF startPos <= LEN(dataLine$) AND parts <= 6 THEN
    partthing$(parts) = MID$(dataLine$, startPos)
    parts = parts + 1
  ENDIF
RETURN

REM ===== GAME DISPLAY SECTION =====

StartGame:
  CLS
  PRINT "==================================="
  PRINT gameTitle$
  IF gameAuthor$ <> "" THEN
    PRINT "by "; gameAuthor$
  ENDIF
  PRINT "==================================="
  PRINT
  GOSUB ShowRoom
  GOSUB GameLoop
RETURN

ShowRoom:
  PRINT
  PRINT "--- "; rooms$(currentRoom, 1); " ---"
  PRINT rooms$(currentRoom, 2)
  PRINT
  
  REM Show objects in room
  found = 0
  FOR i = 1 TO numObjects
    IF VAL(objects$(i, 1)) = currentRoom THEN
      IF found = 0 THEN
        PRINT "You can see:"
        found = 1
      ENDIF
      PRINT "  "; objects$(i, 2)
    ENDIF
  NEXT i
  
  REM Show exits
  exits$ = rooms$(currentRoom, 3)
  GOSUB ParseExits
  
  exitText$ = ""
  IF exitNorth$ <> "0" THEN
    exitText$ = exitText$ + "North "
  ENDIF
  IF exitSouth$ <> "0" THEN
    exitText$ = exitText$ + "South "
  ENDIF
  IF exitEast$ <> "0" THEN
    exitText$ = exitText$ + "East "
  ENDIF
  IF exitWest$ <> "0" THEN
    exitText$ = exitText$ + "West "
  ENDIF
  
  IF exitText$ <> "" THEN
    PRINT
    PRINT "Exits: "; exitText$
  ENDIF
  PRINT
RETURN

ParseExits:
  REM Parse exits format: "N,S,E,W"
  REM Reuse SplitLine logic but for exits
  parts = 0
  startPos = 1
  temp$ = exits$
  
  exitNorth$ = "0"
  exitSouth$ = "0"
  exitEast$ = "0"
  exitWest$ = "0"
  
  FOR i = 1 TO LEN(temp$)
    IF MID$(temp$, i, 1) = "," THEN
      IF parts = 0 THEN
        exitNorth$ = MID$(temp$, startPos, i - startPos)
      ENDIF
      IF parts = 1 THEN
        exitSouth$ = MID$(temp$, startPos, i - startPos)
      ENDIF
      IF parts = 2 THEN
        exitEast$ = MID$(temp$, startPos, i - startPos)
      ENDIF
      parts = parts + 1
      startPos = i + 1
    ENDIF
  NEXT i
  
  REM Get final part (West)
  IF startPos <= LEN(temp$) THEN
    exitWest$ = MID$(temp$, startPos)
  ENDIF
RETURN

ShowInventory:
  IF inventoryCount = 0 THEN
    PRINT "You are not carrying anything."
  ELSE
    PRINT "You are carrying:"
    FOR i = 1 TO inventoryCount
      PRINT "  "; inventory$(i)
    NEXT i
  ENDIF
RETURN

REM ===== GAME LOOP =====

GameLoop:
  DO
    PRINT "> ";
    LINE INPUT command$
    
    IF command$ <> "" THEN
      command$ = NormalizeCommand$(command$)
      
      REM Check custom responses first
      found = 0
      FOR i = 1 TO numResponses
        tempCmd$ = UCASE$(responses$(i, 0))
                
        REM Check if all words in trigger are in command
        IF tempCmd$ = "" THEN
          REM Skip empty triggers
        ELSE
          REM Simple substring match
          IF INSTR(command$, tempCmd$) > 0 THEN
            tempCondition$ = responses$(i, 1)
            GOSUB EvaluateCondition
                        
            IF conditionResult = 1 THEN
              PRINT responses$(i, 2)
              IF responses$(i, 3) <> "" THEN
                tempAction$ = responses$(i, 3)
                GOSUB ExecuteActions
              ENDIF
              found = 1
              EXIT FOR
            ELSE
              REM Trigger matched but condition failed
              REM Mark that we recognized the command
              found = 2
            ENDIF
          ENDIF
        ENDIF
      NEXT i
      
      REM Handle results
      IF found = 1 THEN
        REM Response executed successfully
      ELSEIF found = 2 THEN
        REM Command recognized but conditions not met
        PRINT "You can't do that right now."
      ELSE
        REM No response matched, use default handler
        GOSUB HandleCommand
      ENDIF
    ENDIF
  LOOP
RETURN

REM ===== COMMAND HANDLING =====

HandleCommand:
  REM Command handling with vocabulary normalization
  
  IF command$ = "QUIT" THEN
    PRINT "Thanks for playing!"
    END
  ENDIF
  
  REM LOOK alone should show the room
  IF command$ = "EXAMINE" OR command$ = "L" or command$ = "LOOK" THEN
    GOSUB ShowRoom
    RETURN
  ENDIF
  
  IF command$ = "INVENTORY" OR command$ = "I" THEN
    GOSUB ShowInventory
    RETURN
  ENDIF
  
  IF command$ = "SCORE" THEN
    PRINT "Score: "; gameScore; " out of "; maxScore
    RETURN
  ENDIF
  
  IF command$ = "NORTH" THEN
    GOSUB GoNorth
    RETURN
  ENDIF
  
  IF command$ = "SOUTH" THEN
    GOSUB GoSouth
    RETURN
  ENDIF
  
  IF command$ = "EAST" THEN
    GOSUB GoEast
    RETURN
  ENDIF
  
  IF command$ = "WEST" THEN
    GOSUB GoWest
    RETURN
  ENDIF
  
  REM Check for TAKE/GET commands
  IF LEFT$(command$, 5) = "TAKE " THEN
    GOSUB HandleTake
    RETURN
  ENDIF
  
  IF command$ = "TAKE" OR command$ = "GET" THEN
    PRINT "What do you want to take?"
    RETURN
  ENDIF
  
  REM Check for DROP command
  IF LEFT$(command$, 5) = "DROP " THEN
    GOSUB HandleDrop
    RETURN
  ENDIF
  
  IF command$ = "DROP" THEN
    PRINT "What do you want to drop?"
    RETURN
  ENDIF
  
  REM Check for EXAMINE command with an object
  IF LEFT$(command$, 8) = "EXAMINE " THEN
    GOSUB HandleExamine
    RETURN
  ENDIF
  
  IF command$ = "X" THEN
    GOSUB ShowRoom
    RETURN
  ENDIF
  
  REM Check for USE command (use X on Y, use X with Y, use X Y)
  IF LEFT$(command$, 4) = "USE " THEN
    GOSUB HandleUse
    RETURN
  ENDIF
  
  REM Check for ATTACK command
  IF LEFT$(command$, 7) = "ATTACK " THEN
    GOSUB HandleAttack
    RETURN
  ENDIF

  REM Check for READ command
  IF LEFT$(command$, 5) = "READ " THEN
    GOSUB HandleRead
    RETURN
  ENDIF
  
  IF command$ = "READ" THEN
    PRINT "What do you want to read?"
    RETURN
  ENDIF
  
  REM Check for SEARCH command
  IF LEFT$(command$, 7) = "SEARCH " THEN
    GOSUB HandleSearch
    RETURN
  ENDIF
  
  IF command$ = "SEARCH" THEN
    PRINT "What do you want to search?"
    RETURN
  ENDIF

  REM Check if this is a custom command from responses
  found = 0
  FOR i = 1 TO numResponses
    tempCmd$ = UCASE$(responses$(i, 1))
    IF tempCmd$ <> "" THEN
      IF INSTR(command$, tempCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        IF conditionResult = 1 THEN
          PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          RETURN
        ELSE
          PRINT "You can't do that right now."
          RETURN
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  PRINT "I don't understand that command."
  PRINT "Try: LOOK, INVENTORY, SCORE, TAKE, DROP, EXAMINE, SEARCH, USE, N/S/E/W, QUIT"
RETURN

REM ===== OBJECT INTERACTION =====

HandleTake:
  REM Extract object name from command
  objName$ = ""
  IF LEFT$(command$, 5) = "TAKE " THEN
    objName$ = MID$(command$, 6)
  ENDIF
  IF LEFT$(command$, 4) = "GET " THEN
    objName$ = MID$(command$, 5)
  ENDIF
    
  REM Check inventory limit
  IF inventoryCount >= 8 THEN
    PRINT "You are carrying too much!"
    RETURN
  ENDIF
  
  REM Look for object in current room
  found = 0
  FOR i = 1 TO numObjects
    IF VAL(objects$(i, 1)) = currentRoom THEN
      REM Check if object name matches (fuzzy match)
      IF INSTR(UCASE$(objects$(i, 2)), objName$) > 0 OR INSTR(UCASE$(objects$(i, 0)), objName$) > 0 THEN
        REM Check if object is takeable
        IF INSTR(UCASE$(objects$(i, 4)), "TAKEABLE") > 0 THEN
          REM Add to inventory
          inventoryCount = inventoryCount + 1
          inventory$(inventoryCount) = objects$(i, 2)
          REM Move object to inventory (-1 = in inventory)
          objects$(i, 1) = "-1"
          PRINT "Taken."
          found = 1
          RETURN
        ELSE
          PRINT "You can't take that."
          found = 1
          RETURN
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 0 THEN
    PRINT "You don't see that here."
  ENDIF
RETURN

HandleDrop:
  REM Extract object name from command
  objName$ = MID$(command$, 6)
  
  REM Look for object in inventory
  found = 0
  FOR i = 1 TO inventoryCount
    IF INSTR(UCASE$(inventory$(i)), objName$) > 0 THEN
      REM Find the object in objects array
      FOR j = 1 TO numObjects
        IF objects$(j, 2) = inventory$(i) AND objects$(j, 1) = "-1" THEN
          REM Drop it in current room
          objects$(j, 1) = STR$(currentRoom)
          PRINT "Dropped."
          
          REM Remove from inventory array
          FOR k = i TO inventoryCount - 1
            inventory$(k) = inventory$(k + 1)
          NEXT k
          inventory$(inventoryCount) = ""
          inventoryCount = inventoryCount - 1
          
          found = 1
          RETURN
        ENDIF
      NEXT j
    ENDIF
  NEXT i
  
  IF found = 0 THEN
    PRINT "You don't have that."
  ENDIF
RETURN

HandleExamine:
  REM Extract object name from command
  objName$ = ""
  IF LEFT$(command$, 8) = "EXAMINE " THEN
    objName$ = MID$(command$, 9)
  ENDIF
  IF LEFT$(command$, 5) = "LOOK " THEN
    objName$ = MID$(command$, 6)
  ENDIF
  IF LEFT$(command$, 2) = "X " THEN
    objName$ = MID$(command$, 3)
  ENDIF
  
  REM Check for custom examine responses FIRST
  found = 0
  FOR i = 1 TO numResponses
    tempCmd$ = UCASE$(responses$(i, 1))
    IF tempCmd$ <> "" THEN
      IF INSTR(command$, tempCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        IF conditionResult = 1 THEN
          PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          found = 1
          RETURN
        ELSE
          found = 2
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 2 THEN
    PRINT "You can't do that right now."
    RETURN
  ENDIF
  
  REM Fallback: Look for object in current room or inventory
  found = 0
  FOR i = 1 TO numObjects
    IF VAL(objects$(i, 1)) = currentRoom OR objects$(i, 1) = "-1" THEN
      REM Check if object name matches (fuzzy match)
      IF INSTR(UCASE$(objects$(i, 2)), objName$) > 0 OR INSTR(UCASE$(objects$(i, 0)), objName$) > 0 THEN
        PRINT objects$(i, 3)
        found = 1
        RETURN
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 0 THEN
    PRINT "You don't see that here."
  ENDIF
RETURN

HandleUse:
  REM Handle USE X ON Y, USE X WITH Y, or just USE X
  temp$ = MID$(command$, 5)
  
  REM Check for ON or WITH (two-object use)
  position = INSTR(temp$, " ON ")
  IF position = 0 THEN
    position = INSTR(temp$, " WITH ")
  ENDIF
  
  IF position > 0 THEN
    REM Format: USE X ON/WITH Y
    objName$ = LEFT$(temp$, position - 1)
    temp$ = MID$(temp$, position)
    REM Skip " ON " or " WITH "
    IF LEFT$(temp$, 4) = " ON " THEN
      temp$ = MID$(temp$, 5)
    ELSE
      temp$ = MID$(temp$, 7)
    ENDIF
    s$ = temp$
    
    REM Build normalized command: USE X Y
    command$ = "USE " + objName$ + " " + s$
  ELSE
    REM Single object use: USE X
    REM Command is already "USE MEDKIT", check responses directly
  ENDIF
  
  REM Check responses with current command
  found = 0
  FOR i = 1 TO numResponses
    tempCmd$ = UCASE$(responses$(i, 1))
    
    IF tempCmd$ <> "" THEN
      IF INSTR(command$, tempCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        
        IF conditionResult = 1 THEN
          PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          found = 1
          RETURN
        ELSE
          found = 2
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 2 THEN
    PRINT "You can't do that right now."
  ELSEIF found = 0 THEN
    PRINT "Nothing happens."
  ENDIF
RETURN

HandleAttack:
  REM Extract target from ATTACK/FIGHT/KILL/SLAY (already normalized to ATTACK)
  objName$ = ""
  IF LEFT$(command$, 7) = "ATTACK " THEN
    objName$ = MID$(command$, 8)
  ENDIF

  REM Response table first (mirror of HandleUse), using 1-based columns
  found = 0
  cmdUpper$ = UCASE$(command$)
  FOR i = 1 TO numResponses
    respCmd$ = UCASE$(responses$(i, 1))
    IF respCmd$ <> "" THEN
      REM Substring match so "ATTACK ALIEN WITH WRENCH" hits "ATTACK ALIEN"
      IF INSTR(cmdUpper$, respCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        IF conditionResult = 1 THEN
          IF responses$(i, 3) <> "" THEN PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          found = 1
          RETURN
        ELSE
          found = 2
        ENDIF
      ENDIF
    ENDIF
  NEXT i

  IF found = 2 THEN
    PRINT "You can't do that right now."
    RETURN
  ENDIF

  REM Fallback: check that the target is in the room, then generic message
  REM If a tool is included, ignore it for lookup (e.g., "ALIEN WITH WRENCH" -> "ALIEN")
  position = INSTR(UCASE$(objName$), " WITH ")
  IF position > 0 THEN objName$ = LEFT$(objName$, position - 1)

  found = 0
  FOR i = 1 TO numObjects
    IF VAL(objects$(i, 1)) = currentRoom THEN
      IF INSTR(UCASE$(objects$(i, 2)), UCASE$(objName$)) > 0 OR INSTR(UCASE$(objects$(i, 0)), UCASE$(objName$)) > 0 THEN
        found = 1
        EXIT FOR
      ENDIF
    ENDIF
  NEXT i

  IF found = 1 THEN
    PRINT "You can't attack that."
  ELSE
    PRINT "You don't see that here."
  ENDIF
RETURN

HandleSearch:
  REM Extract object name from SEARCH command
  objName$ = MID$(command$, 8)
  
  REM Check for custom search responses FIRST
  found = 0
  FOR i = 1 TO numResponses
    tempCmd$ = UCASE$(responses$(i, 1))
    IF tempCmd$ <> "" THEN
      IF INSTR(command$, tempCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        IF conditionResult = 1 THEN
          PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          found = 1
          RETURN
        ELSE
          found = 2
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 2 THEN
    PRINT "You can't do that right now."
    RETURN
  ENDIF
  
  REM Fallback: Check if object exists in room
  found = 0
  FOR i = 1 TO numObjects
    IF VAL(objects$(i, 1)) = currentRoom THEN
      IF INSTR(UCASE$(objects$(i, 2)), objName$) > 0 OR INSTR(UCASE$(objects$(i, 0)), objName$) > 0 THEN
        found = 1
        EXIT FOR
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 1 THEN
    PRINT "You find nothing unusual."
  ELSE
    PRINT "You don't see that here."
  ENDIF
RETURN

HandleRead:
  REM Extract object name from READ command
  objName$ = MID$(command$, 6)
  
  REM Try to find matching object in inventory and build proper command
  FOR j = 1 TO numObjects
    IF objects$(j, 1) = "-1" THEN
      REM Object is in inventory
      IF INSTR(UCASE$(objects$(j, 0)), objName$) > 0 OR INSTR(UCASE$(objects$(j, 2)), objName$) > 0 THEN
        REM Found the object - rebuild command with proper name
        command$ = "READ " + UCASE$(objects$(j, 0))
        EXIT FOR
      ENDIF
    ENDIF
  NEXT j
  
  REM Now check responses with the normalized command
  found = 0
  FOR i = 1 TO numResponses
    tempCmd$ = UCASE$(responses$(i, 1))
    IF tempCmd$ <> "" THEN
      IF INSTR(command$, tempCmd$) > 0 THEN
        tempCondition$ = responses$(i, 2)
        GOSUB EvaluateCondition
        IF conditionResult = 1 THEN
          PRINT responses$(i, 3)
          IF responses$(i, 4) <> "" THEN
            tempAction$ = responses$(i, 4)
            GOSUB ExecuteActions
          ENDIF
          found = 1
          RETURN
        ELSE
          found = 2
        ENDIF
      ENDIF
    ENDIF
  NEXT i
  
  IF found = 2 THEN
    PRINT "You can't do that right now."
  ELSE
    PRINT "There's nothing to read on that."
  ENDIF
RETURN

REM ===== MOVEMENT SUBROUTINES =====

GoNorth:
  exits$ = rooms$(currentRoom, 3)
  GOSUB ParseExits
  newRoom = VAL(exitNorth$)
  IF newRoom > 0 THEN
    currentRoom = newRoom
    GOSUB ShowRoom
  ELSE
    PRINT "You can't go that way."
  ENDIF
RETURN

GoSouth:
  exits$ = rooms$(currentRoom, 3)
  GOSUB ParseExits
  newRoom = VAL(exitSouth$)
  IF newRoom > 0 THEN
    currentRoom = newRoom
    GOSUB ShowRoom
  ELSE
    PRINT "You can't go that way."
  ENDIF
RETURN

GoEast:
  exits$ = rooms$(currentRoom, 3)
  GOSUB ParseExits
  newRoom = VAL(exitEast$)
  IF newRoom > 0 THEN
    currentRoom = newRoom
    GOSUB ShowRoom
  ELSE
    PRINT "You can't go that way."
  ENDIF
RETURN

GoWest:
  exits$ = rooms$(currentRoom, 3)
  GOSUB ParseExits
  newRoom = VAL(exitWest$)
  IF newRoom > 0 THEN
    currentRoom = newRoom
    GOSUB ShowRoom
  ELSE
    PRINT "You can't go that way."
  ENDIF
RETURN

REM ===== RESPONSE SYSTEM =====

EvaluateCondition:
  REM Evaluate condition string
  conditionResult = 1
  
  REM Empty condition = always true
  IF tempCondition$ = "" THEN
    RETURN
  ENDIF
  
  REM Check for AND - split and evaluate both sides
  andPos = INSTR(tempCondition$, " AND ")
  IF andPos > 0 THEN
    leftCondition$ = LEFT$(tempCondition$, andPos - 1)
    rightCondition$ = MID$(tempCondition$, andPos + 5)
    
    REM Evaluate left side
    temp$ = tempCondition$
    tempCondition$ = leftCondition$
    GOSUB EvaluateSingleCondition
    leftResult = conditionResult
    
    REM Evaluate right side
    tempCondition$ = rightCondition$
    GOSUB EvaluateSingleCondition
    rightResult = conditionResult
    
    tempCondition$ = temp$
    
    REM Both must be true
    IF leftResult = 1 AND rightResult = 1 THEN
      conditionResult = 1
    ELSE
      conditionResult = 0
    ENDIF
    RETURN
  ENDIF
  
  REM Single condition
  GOSUB EvaluateSingleCondition
RETURN

EvaluateSingleCondition:
  REM Check for NOT prefix
  IF LEFT$(tempCondition$, 4) = "NOT " THEN
    temp$ = tempCondition$
    tempCondition$ = MID$(tempCondition$, 5)
    GOSUB EvaluateSingleCondition
    REM Invert result
    IF conditionResult = 1 THEN
      conditionResult = 0
    ELSE
      conditionResult = 1
    ENDIF
    tempCondition$ = temp$
    RETURN
  ENDIF
  
  REM Check for player.has X
  IF LEFT$(UCASE$(tempCondition$), 11) = "PLAYER.HAS " THEN
    objName$ = MID$(tempCondition$, 12)
    objName$ = UCASE$(objName$)
    GOSUB CheckPlayerHas
    conditionResult = hasObj
    RETURN
  ENDIF
  
  REM Check for room=N
  IF LEFT$(UCASE$(tempCondition$), 5) = "ROOM=" THEN
    roomNum = VAL(MID$(tempCondition$, 6))
    IF currentRoom = roomNum THEN
      conditionResult = 1
    ELSE
      conditionResult = 0
    ENDIF
    RETURN
  ENDIF
  
  REM Check for flag.X
  IF LEFT$(UCASE$(tempCondition$), 5) = "FLAG." THEN
    tempFlagName$ = MID$(tempCondition$, 6)
    GOSUB CheckFlag
    conditionResult = hasFlag
    RETURN
  ENDIF
  
  REM Unknown condition - default to false
  conditionResult = 0
RETURN

CheckPlayerHas:
  REM Check if player has object in inventory
  hasObj = 0
  FOR j = 1 TO numObjects
    IF objects$(j, 1) = "-1" THEN
      REM Object is in inventory
      IF INSTR(UCASE$(objects$(j, 0)), objName$) > 0 OR INSTR(UCASE$(objects$(j, 2)), objName$) > 0 THEN
        hasObj = 1
        RETURN
      ENDIF
    ENDIF
  NEXT j
RETURN

CheckFlag:
  REM Check if flag is set
  hasFlag = 0
  FOR j = 1 TO numFlags
    IF UCASE$(gameFlags$(j)) = UCASE$(tempFlagName$) THEN
      hasFlag = 1
      RETURN
    ENDIF
  NEXT j
RETURN

GetMessage:
  REM Look up message by key (tempKey$)
  msg$ = ""
  FOR j = 1 TO numMessages
    IF UCASE$(messages$(j, 0)) = UCASE$(tempKey$) THEN
      msg$ = messages$(j, 1)
      RETURN
    ENDIF
  NEXT j
RETURN

ExecuteActions:
  REM Execute comma-separated actions  
  REM Split by comma and execute each action
  actionStart = 1
  FOR k = 1 TO LEN(tempAction$)
    IF MID$(tempAction$, k, 1) = "," THEN
      singleAction$ = MID$(tempAction$, actionStart, k - actionStart)
      IF singleAction$ <> "" THEN
        GOSUB ExecuteSingleAction
      ENDIF
      actionStart = k + 1
    ENDIF
  NEXT k
  
  REM Execute final action after last comma
  IF actionStart <= LEN(tempAction$) THEN
    singleAction$ = MID$(tempAction$, actionStart)
    IF singleAction$ <> "" THEN
      GOSUB ExecuteSingleAction
    ENDIF
  ENDIF
  
RETURN

ExecuteSingleAction:
  REM Execute a single action
  singleAction$ = UCASE$(singleAction$)
  
  REM Score action: "score 100"
  IF LEFT$(singleAction$, 6) = "SCORE " THEN
    gameScore = gameScore + VAL(MID$(singleAction$, 7))
    PRINT "[You scored "; MID$(singleAction$, 7); " points!]"
    
    REM Check for win condition
    IF gameScore >= maxScore THEN
      PRINT
      tempKey$ = "win_game"
      GOSUB GetMessage
      IF msg$ <> "" THEN
        PRINT msg$
      ELSE
        PRINT "Congratulations! You have won the game!"
      ENDIF
      PRINT
      PRINT "Final score: "; gameScore; " out of "; maxScore
      PRINT "Thanks for playing!"
      END
    ENDIF
    RETURN
  ENDIF
  
  REM Set flag: "set flag gate_used"
  IF LEFT$(singleAction$, 9) = "SET FLAG " THEN
    tempFlagName$ = MID$(singleAction$, 10)
    REM Add flag if not already set
    GOSUB CheckFlag
    IF hasFlag = 0 THEN
      numFlags = numFlags + 1
      IF numFlags <= 20 THEN
        gameFlags$(numFlags) = tempFlagName$
      ENDIF
    ENDIF
    RETURN
  ENDIF
  
  REM Remove object: "remove shadow beast"
  IF LEFT$(singleAction$, 7) = "REMOVE " THEN
    objName$ = MID$(singleAction$, 8)
    FOR j = 1 TO numObjects
      IF INSTR(UCASE$(objects$(j, 0)), objName$) > 0 OR INSTR(UCASE$(objects$(j, 2)), objName$) > 0 THEN
        REM Move object to room 0 (removed from game)
        objects$(j, 1) = "0"
        RETURN
      ENDIF
    NEXT j
    RETURN
  ENDIF
  
  REM Move object: "move codes to 13"
  IF LEFT$(singleAction$, 5) = "MOVE " AND INSTR(singleAction$, " TO ") > 0 THEN
    tempStr$ = MID$(singleAction$, 6)
    toPos = INSTR(tempStr$, " TO ")
    IF toPos > 0 THEN
      objName$ = LEFT$(tempStr$, toPos - 1)
      temp$ = MID$(tempStr$, toPos + 4)
      REM Find and move the object
      FOR j = 1 TO numObjects
        IF objects$(j, 0) <> "" AND UCASE$(objects$(j, 0)) = objName$ THEN
          objects$(j, 1) = temp$
          RETURN
        ENDIF
      NEXT j
    ENDIF
    RETURN
  ENDIF
  
  REM Unlock exit: "unlock west exit room 2 to 6"
  IF LEFT$(singleAction$, 7) = "UNLOCK " THEN
    GOSUB UnlockExit
    RETURN
  ENDIF
RETURN

UnlockExit:
  REM Parse: "unlock west exit room 2 to 6"
  temp$ = MID$(singleAction$, 8)
  
  REM Find "room X to Y"
  toPos = INSTR(temp$, " TO ")
  IF toPos = 0 THEN
    RETURN
  ENDIF
  
  REM Extract room numbers
  position = INSTR(temp$, "ROOM ")
  IF position > 0 THEN
    temp$ = MID$(temp$, position + 5)
    spacePos = INSTR(temp$, " ")
    IF spacePos > 0 THEN
      id = VAL(LEFT$(temp$, spacePos - 1))
      destRoom = VAL(MID$(temp$, spacePos + 4))
      
      REM Update room exits
      exits$ = rooms$(id, 3)
      GOSUB ParseExits
      
      REM Update the appropriate direction
      IF LEFT$(singleAction$, 12) = "UNLOCK NORTH" THEN
        exitNorth$ = STR$(destRoom)
      ENDIF
      IF LEFT$(singleAction$, 12) = "UNLOCK SOUTH" THEN
        exitSouth$ = STR$(destRoom)
      ENDIF
      IF LEFT$(singleAction$, 11) = "UNLOCK EAST" THEN
        exitEast$ = STR$(destRoom)
      ENDIF
      IF LEFT$(singleAction$, 11) = "UNLOCK WEST" THEN
        exitWest$ = STR$(destRoom)
      ENDIF
      
      REM Rebuild exits string
      rooms$(id, 3) = exitNorth$ + "," + exitSouth$ + "," + exitEast$ + "," + exitWest$
    ENDIF
  ENDIF
RETURN