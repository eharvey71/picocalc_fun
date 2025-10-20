REM Enhanced Adventure Player for MMB4L
REM Handles advanced features: responses, vocabulary, messages, scoring

DIM rooms$(50, 6)
DIM objects$(50, 5) 
DIM inventory$(20)
DIM responses$(100, 4)  ' Trigger, Condition, Response, Action
DIM vocabulary$(50, 2)   ' Word, Synonym list
DIM messages$(20, 2)     ' Key, Message
DIM gameFlags$(50)       ' Game state flags (unlocked doors, etc.)

DIM gameTitle$, gameAuthor$, gameVersion$
DIM currentRoom, inventoryCount, gameScore, maxScore, startRoom
DIM numResponses, numVocabulary, numMessages, numFlags

DIM section$, dataLine$, key$, value$
DIM partthing$(10)
DIM lineCount, trimmed$, position, id, parts, startPos
DIM exits$, exitNorth$, exitSouth$, exitEast$, exitWest$
DIM rest$, exitText$, hasExit
DIM command$, objName$, found, newRoom
DIM originalCommand$, normalizedCommand$
DIM tempCmd$, tempCondition$, tempAction$, tempKey$, tempFlagName$
DIM result$, conditionResult, hasObj, hasFlag, msg$
DIM singleAction$, actionStart
DIM tempStr$, toPos, destRoom
DIM leftCondition$, rightCondition$, leftResult, rightResult, andPos, spacePos

' Initialize
inventoryCount = 0
gameScore = 0
maxScore = 100
currentRoom = 0
startRoom = 1
numResponses = 0
numVocabulary = 0
numMessages = 0
numFlags = 0

PRINT "=== Enhanced MMB4L Adventure Player ==="
PRINT "Now with custom responses, vocabulary, and advanced features!"
PRINT
PRINT "Adventure file to load: ";
INPUT filename$
IF filename$ = "" THEN 
  PRINT "No file specified. Goodbye!"
  END
END IF

IF UCASE$(RIGHT$(filename$, 4)) <> ".ADV" THEN filename$ = filename$ + ".adv"

GOSUB LoadAdventureFile
GOSUB StartGame

LoadAdventureFile:
OPEN filename$ FOR INPUT AS #1

section$ = ""
lineCount = 0
DO WHILE NOT EOF(#1)
  LINE INPUT #1, dataLine$
  lineCount = lineCount + 1
  
  ' Manual trim
  trimmed$ = dataLine$
  DO WHILE LEFT$(trimmed$, 1) = " " AND LEN(trimmed$) > 0
    trimmed$ = MID$(trimmed$, 2)
  LOOP
  DO WHILE RIGHT$(trimmed$, 1) = " " AND LEN(trimmed$) > 0
    trimmed$ = LEFT$(trimmed$, LEN(trimmed$) - 1)
  LOOP
  dataLine$ = trimmed$
  
  ' Skip comments and blank lines
  IF LEFT$(dataLine$, 1) <> "#" AND dataLine$ <> "" THEN
    IF LEFT$(dataLine$, 1) = "[" AND RIGHT$(dataLine$, 1) = "]" THEN
      section$ = MID$(dataLine$, 2, LEN(dataLine$) - 2)
      PRINT "Loading "; section$; "..."
    ELSE
      SELECT CASE section$
        CASE "SETTINGS": GOSUB ParseSettings
        CASE "ROOMS": GOSUB ParseRooms  
        CASE "OBJECTS": GOSUB ParseObjects
        CASE "VOCABULARY": GOSUB ParseVocabulary
        CASE "RESPONSES": GOSUB ParseResponses
        CASE "MESSAGES": GOSUB ParseMessages
      END SELECT
    END IF
  END IF
LOOP
CLOSE #1

' Set starting room
currentRoom = startRoom
PRINT "Loaded "; STR$(lineCount); " total lines"
PRINT "Custom responses: "; STR$(numResponses)
PRINT "Vocabulary entries: "; STR$(numVocabulary)
PRINT "Custom messages: "; STR$(numMessages)
RETURN

ParseSettings:
position = INSTR(dataLine$, "=")
IF position > 0 THEN
  key$ = LEFT$(dataLine$, position - 1)
  value$ = MID$(dataLine$, position + 1)
  
  SELECT CASE key$
    CASE "title": gameTitle$ = value$
    CASE "author": gameAuthor$ = value$
    CASE "version": gameVersion$ = value$
    CASE "startroom": startRoom = VAL(value$)
    CASE "maxscore": maxScore = VAL(value$)
  END SELECT
END IF
RETURN

ParseRooms:
GOSUB SplitLine
IF parts >= 4 THEN
  id = VAL(partthing$(0))
  IF id > 0 AND id <= 50 THEN
    rooms$(id, 1) = partthing$(1)  ' Name
    rooms$(id, 2) = partthing$(2)  ' Description  
    rooms$(id, 3) = partthing$(3)  ' Exits
    IF parts > 4 THEN rooms$(id, 4) = partthing$(4)  ' Special
  END IF
END IF
RETURN

ParseObjects:
GOSUB SplitLine
IF parts >= 5 THEN
  FOR i = 1 TO 50
    IF objects$(i, 0) = "" THEN
      objects$(i, 0) = partthing$(0)  ' Object ID
      objects$(i, 1) = partthing$(1)  ' Starting room
      objects$(i, 2) = partthing$(2)  ' Name
      objects$(i, 3) = partthing$(3)  ' Description
      objects$(i, 4) = partthing$(4)  ' Properties
      EXIT FOR
    END IF
  NEXT i
END IF
RETURN

ParseVocabulary:
' Format: word=synonym1,synonym2,synonym3
position = INSTR(dataLine$, "=")
IF position > 0 THEN
  numVocabulary = numVocabulary + 1
  vocabulary$(numVocabulary, 1) = LEFT$(dataLine$, position - 1)      ' Main word
  vocabulary$(numVocabulary, 2) = MID$(dataLine$, position + 1)       ' Synonyms
END IF
RETURN

ParseResponses:
' Format: trigger|condition|response|action
GOSUB SplitLine
IF parts >= 4 THEN
  numResponses = numResponses + 1
  responses$(numResponses, 1) = partthing$(0)  ' Trigger
  responses$(numResponses, 2) = partthing$(1)  ' Condition
  responses$(numResponses, 3) = partthing$(2)  ' Response text
  responses$(numResponses, 4) = partthing$(3)  ' Action
END IF
RETURN

ParseMessages:
' Format: key=message
position = INSTR(dataLine$, "=")
IF position > 0 THEN
  numMessages = numMessages + 1
  messages$(numMessages, 1) = LEFT$(dataLine$, position - 1)      ' Key
  messages$(numMessages, 2) = MID$(dataLine$, position + 1)       ' Message
END IF
RETURN

SplitLine:
parts = 0
startPos = 1
FOR i = 1 TO LEN(dataLine$)
  IF MID$(dataLine$, i, 1) = "|" THEN
    partthing$(parts) = MID$(dataLine$, startPos, i - startPos)
    parts = parts + 1
    startPos = i + 1
  END IF
NEXT i
IF startPos <= LEN(dataLine$) THEN
  partthing$(parts) = MID$(dataLine$, startPos)
  parts = parts + 1
END IF
RETURN

StartGame:
PRINT
PRINT "======================================="
PRINT gameTitle$
IF gameAuthor$ <> "" THEN PRINT "by "; gameAuthor$
IF gameVersion$ <> "" THEN PRINT "Version "; gameVersion$
PRINT "======================================="
PRINT
PRINT "Type HELP for commands, QUIT to exit"
IF maxScore > 0 THEN PRINT "Maximum score: "; STR$(maxScore)
PRINT

GameLoop:
GOSUB ShowRoom
PRINT
INPUT "> ", command$
originalCommand$ = command$
command$ = UCASE$(command$)

IF command$ = "" THEN GOTO GameLoop

' First check for custom responses
GOSUB CheckCustomResponses
IF found THEN GOTO GameLoop

' Then handle built-in commands
GOSUB ParseCommand
GOTO GameLoop

CheckCustomResponses:
found = 0
tempCmd$ = originalCommand$
GOSUB NormalizeCommand
normalizedCommand$ = result$

FOR i = 1 TO numResponses
  IF responses$(i, 1) <> "" THEN
    ' More flexible matching - check if the command contains the trigger
    triggerCmd$ = UCASE$(responses$(i, 1))
    IF INSTR(normalizedCommand$, triggerCmd$) > 0 OR triggerCmd$ = normalizedCommand$ THEN
      ' Check conditions
      tempCondition$ = responses$(i, 2)
      GOSUB EvaluateCondition
      IF conditionResult = 1 THEN
        PRINT responses$(i, 3)
        IF responses$(i, 4) <> "" THEN 
          tempAction$ = responses$(i, 4)
          GOSUB ExecuteAction
        END IF
        found = 1
        EXIT FOR
      END IF
    END IF
  END IF
NEXT i
RETURN

NormalizeCommand:
' Convert synonyms to standard words
result$ = UCASE$(tempCmd$)
FOR i = 1 TO numVocabulary
  synonyms$ = vocabulary$(i, 2)
  mainWord$ = UCASE$(vocabulary$(i, 1))
  
  ' Split synonyms and check each
  startPos = 1
  FOR j = 1 TO LEN(synonyms$)
    IF MID$(synonyms$, j, 1) = "," THEN
      synonym$ = UCASE$(MID$(synonyms$, startPos, j - startPos))
      IF INSTR(result$, synonym$) > 0 THEN
        ' Replace synonym with main word
        result$ = LEFT$(result$, INSTR(result$, synonym$) - 1) + mainWord$ + MID$(result$, INSTR(result$, synonym$) + LEN(synonym$))
      END IF
      startPos = j + 1
    END IF
  NEXT j
  
  ' Handle last synonym
  IF startPos <= LEN(synonyms$) THEN
    synonym$ = UCASE$(MID$(synonyms$, startPos))
    IF INSTR(result$, synonym$) > 0 THEN
      result$ = LEFT$(result$, INSTR(result$, synonym$) - 1) + mainWord$ + MID$(result$, INSTR(result$, synonym$) + LEN(synonym$))
    END IF
  END IF
NEXT i
RETURN

EvaluateCondition:
' Enhanced condition evaluation with AND support
condition$ = tempCondition$
conditionResult = 1
IF condition$ = "" THEN RETURN

' Check if this is a compound condition with AND
IF INSTR(condition$, " AND ") > 0 THEN
  ' Split by AND and evaluate each part
  andPos = INSTR(condition$, " AND ")
  leftCondition$ = LEFT$(condition$, andPos - 1)
  rightCondition$ = MID$(condition$, andPos + 5)
  
  ' Trim spaces
  DO WHILE LEFT$(leftCondition$, 1) = " " AND LEN(leftCondition$) > 0
    leftCondition$ = MID$(leftCondition$, 2)
  LOOP
  DO WHILE RIGHT$(leftCondition$, 1) = " " AND LEN(leftCondition$) > 0
    leftCondition$ = LEFT$(leftCondition$, LEN(leftCondition$) - 1)
  LOOP
  DO WHILE LEFT$(rightCondition$, 1) = " " AND LEN(rightCondition$) > 0
    rightCondition$ = MID$(rightCondition$, 2)
  LOOP
  DO WHILE RIGHT$(rightCondition$, 1) = " " AND LEN(rightCondition$) > 0
    rightCondition$ = LEFT$(rightCondition$, LEN(rightCondition$) - 1)
  LOOP
  
  ' Evaluate left condition
  tempCondition$ = leftCondition$
  GOSUB EvaluateSingleCondition
  leftResult = conditionResult
  
  ' Evaluate right condition
  tempCondition$ = rightCondition$
  GOSUB EvaluateSingleCondition
  rightResult = conditionResult
  
  ' Both must be true for AND
  IF leftResult = 1 AND rightResult = 1 THEN
    conditionResult = 1
  ELSE
    conditionResult = 0
  END IF
  RETURN
END IF

' Single condition - fall through to single condition evaluator
GOSUB EvaluateSingleCondition
RETURN

EvaluateSingleCondition:
' Evaluate a single condition (no AND)
condition$ = tempCondition$
conditionResult = 1
IF condition$ = "" THEN RETURN

' Handle basic conditions like "room=2", "player.has key"
IF INSTR(condition$, "room=") > 0 THEN
  roomNum = VAL(MID$(condition$, INSTR(condition$, "room=") + 5))
  conditionResult = 0
  IF currentRoom = roomNum THEN conditionResult = 1
ELSEIF INSTR(condition$, "player.has ") > 0 THEN
  objName$ = MID$(condition$, INSTR(condition$, "player.has ") + 11)
  ' Trim any trailing spaces or conditions
  spacePos = INSTR(objName$, " ")
  IF spacePos > 0 THEN objName$ = LEFT$(objName$, spacePos - 1)
  GOSUB PlayerHasObject
  conditionResult = hasObj
ELSEIF INSTR(condition$, "NOT player.has ") > 0 THEN
  objName$ = MID$(condition$, INSTR(condition$, "NOT player.has ") + 15)
  ' Trim any trailing spaces or conditions
  spacePos = INSTR(objName$, " ")
  IF spacePos > 0 THEN objName$ = LEFT$(objName$, spacePos - 1)
  GOSUB PlayerHasObject
  conditionResult = 0
  IF hasObj = 0 THEN conditionResult = 1
ELSEIF INSTR(condition$, "flag.") > 0 THEN
  flagName$ = MID$(condition$, INSTR(condition$, "flag.") + 5)
  ' Trim any trailing spaces or conditions
  spacePos = INSTR(flagName$, " ")
  IF spacePos > 0 THEN flagName$ = LEFT$(flagName$, spacePos - 1)
  GOSUB CheckFlag
  conditionResult = hasFlag
ELSEIF INSTR(condition$, "NOT flag.") > 0 THEN
  flagName$ = MID$(condition$, INSTR(condition$, "NOT flag.") + 9)
  ' Trim any trailing spaces or conditions
  spacePos = INSTR(flagName$, " ")
  IF spacePos > 0 THEN flagName$ = LEFT$(flagName$, spacePos - 1)
  GOSUB CheckFlag
  conditionResult = 0
  IF hasFlag = 0 THEN conditionResult = 1
ELSE
  conditionResult = 1  ' Default true
END IF
RETURN

PlayerHasObject:
hasObj = 0
FOR j = 1 TO inventoryCount
  ' More flexible matching - check if the inventory item contains the object name
  IF INSTR(UCASE$(inventory$(j)), UCASE$(objName$)) > 0 THEN
    hasObj = 1
    EXIT FOR
  END IF
NEXT j
RETURN

CheckFlag:
hasFlag = 0
FOR j = 1 TO numFlags
  IF gameFlags$(j) = flagName$ THEN
    hasFlag = 1
    EXIT FOR
  END IF
NEXT j
RETURN

ExecuteAction:
action$ = tempAction$
' Handle multiple actions separated by commas
IF INSTR(action$, ",") > 0 THEN
  ' Split actions by comma and execute each
  actionStart = 1
  FOR k = 1 TO LEN(action$)
    IF MID$(action$, k, 1) = "," OR k = LEN(action$) THEN
      IF k = LEN(action$) THEN
        singleAction$ = MID$(action$, actionStart)
      ELSE
        singleAction$ = MID$(action$, actionStart, k - actionStart)
      END IF
      
      ' Trim the single action
      DO WHILE LEFT$(singleAction$, 1) = " " AND LEN(singleAction$) > 0
        singleAction$ = MID$(singleAction$, 2)
      LOOP
      DO WHILE RIGHT$(singleAction$, 1) = " " AND LEN(singleAction$) > 0
        singleAction$ = LEFT$(singleAction$, LEN(singleAction$) - 1)
      LOOP
      
      ' Execute this single action
      GOSUB ExecuteSingleAction
      actionStart = k + 1
    END IF
  NEXT k
ELSE
  ' Single action
  singleAction$ = action$
  GOSUB ExecuteSingleAction
END IF
RETURN

ExecuteSingleAction:
' Handle basic actions - check specific unlock directions FIRST before generic unlock
IF INSTR(singleAction$, "unlock north exit room ") > 0 THEN
  ' Parse: "unlock north exit room X to Y"
  tempStr$ = MID$(singleAction$, 24)  ' Get "X to Y"
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = STR$(destRoom) + "," + exitSouth$ + "," + exitEast$ + "," + exitWest$
        PRINT "The way north is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock south exit room ") > 0 THEN
  ' Parse: "unlock south exit room X to Y"
  tempStr$ = MID$(singleAction$, 24)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + STR$(destRoom) + "," + exitEast$ + "," + exitWest$
        PRINT "The way south is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock east exit room ") > 0 THEN
  ' Parse: "unlock east exit room X to Y"
  tempStr$ = MID$(singleAction$, 23)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + exitSouth$ + "," + STR$(destRoom) + "," + exitWest$
        PRINT "The way east is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock west exit room ") > 0 THEN
  ' Parse: "unlock west exit room X to Y"
  tempStr$ = MID$(singleAction$, 23)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + exitSouth$ + "," + exitEast$ + "," + STR$(destRoom)
        PRINT "The way west is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock ") > 0 THEN
  ' Generic unlock for objects (not exits)
  objName$ = MID$(singleAction$, 8)
  PRINT "The "; objName$; " is now unlocked!"
  tempFlagName$ = "unlocked_" + objName$
  GOSUB SetFlag
ELSEIF INSTR(singleAction$, "move player to ") > 0 THEN
  newRoom = VAL(MID$(singleAction$, 16))
  IF newRoom > 0 AND newRoom <= 50 AND rooms$(newRoom, 1) <> "" THEN
    currentRoom = newRoom
    PRINT "You are moved to a new location."
  END IF
ELSEIF INSTR(singleAction$, "score ") > 0 THEN
  points = VAL(MID$(singleAction$, 7))
  ' Cap score at maximum
  newScore = gameScore + points
  IF newScore > maxScore THEN newScore = maxScore
  gameScore = newScore
  PRINT "Score: "; STR$(gameScore); "/"; STR$(maxScore)
  ' Check for winning condition
  IF gameScore >= maxScore THEN
    PRINT
    tempKey$ = "win_game"
    GOSUB GetMessage
    IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "Congratulations! You have achieved maximum score!"
  END IF
ELSEIF INSTR(singleAction$, "set flag ") > 0 THEN
  flagName$ = MID$(singleAction$, 10)
  GOSUB SetGameFlag
ELSEIF INSTR(singleAction$, "remove ") > 0 THEN
  objName$ = MID$(singleAction$, 8)
  ' Remove object from current room
  FOR i = 1 TO 50
    IF objects$(i, 0) <> "" AND UCASE$(objects$(i, 2)) = UCASE$(objName$) THEN
      IF VAL(objects$(i, 1)) = currentRoom THEN
        objects$(i, 1) = "-2"  ' Mark as removed
        EXIT FOR
      END IF
    END IF
  NEXT i
ELSEIF INSTR(singleAction$, "unlock north exit room ") > 0 THEN
  ' Parse: "unlock north exit room X to Y"
  tempStr$ = MID$(singleAction$, 24)  ' Get "X to Y"
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = STR$(destRoom) + "," + exitSouth$ + "," + exitEast$ + "," + exitWest$
        PRINT "The way north is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock south exit room ") > 0 THEN
  ' Parse: "unlock south exit room X to Y"
  tempStr$ = MID$(singleAction$, 24)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + STR$(destRoom) + "," + exitEast$ + "," + exitWest$
        PRINT "The way south is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock east exit room ") > 0 THEN
  ' Parse: "unlock east exit room X to Y"
  tempStr$ = MID$(singleAction$, 23)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + exitSouth$ + "," + STR$(destRoom) + "," + exitWest$
        PRINT "The way east is now open!"
      END IF
    END IF
  END IF
ELSEIF INSTR(singleAction$, "unlock west exit room ") > 0 THEN
  ' Parse: "unlock west exit room X to Y"
  tempStr$ = MID$(singleAction$, 23)
  toPos = INSTR(tempStr$, " to ")
  IF toPos > 0 THEN
    roomNum = VAL(LEFT$(tempStr$, toPos - 1))
    destRoom = VAL(MID$(tempStr$, toPos + 4))
    IF roomNum = currentRoom THEN
      exits$ = rooms$(roomNum, 3)
      IF exits$ <> "" THEN
        GOSUB SplitExits
        rooms$(roomNum, 3) = exitNorth$ + "," + exitSouth$ + "," + exitEast$ + "," + STR$(destRoom)
        PRINT "The way west is now open!"
      END IF
    END IF
  END IF
END IF
RETURN

SetFlag:
flagName$ = tempFlagName$
GOSUB SetGameFlag
RETURN

SetGameFlag:
' Add flag if it doesn't already exist
FOR j = 1 TO 50
  IF gameFlags$(j) = flagName$ THEN RETURN  ' Already set
  IF gameFlags$(j) = "" THEN
    gameFlags$(j) = flagName$
    numFlags = numFlags + 1
    RETURN
  END IF
NEXT j
RETURN

GetMessage:
' Get custom message by key
msg$ = ""
FOR i = 1 TO numMessages
  IF messages$(i, 1) = tempKey$ THEN
    msg$ = messages$(i, 2)
    EXIT FOR
  END IF
NEXT i
RETURN

ShowRoom:
IF currentRoom < 1 OR currentRoom > 50 OR rooms$(currentRoom, 1) = "" THEN
  PRINT "ERROR: Invalid room "; STR$(currentRoom)
  currentRoom = startRoom
  RETURN
END IF

PRINT rooms$(currentRoom, 1)
PRINT rooms$(currentRoom, 2)

' Show special room properties
IF rooms$(currentRoom, 4) <> "" THEN
  special$ = rooms$(currentRoom, 4)
  IF special$ = "dark" THEN PRINT "(This room is dark and foreboding.)"
END IF

' Show objects in room
FOR i = 1 TO 50
  IF objects$(i, 0) <> "" AND objects$(i, 1) <> "" THEN
    IF VAL(objects$(i, 1)) = currentRoom THEN
      ' Skip removed objects
      IF objects$(i, 1) = "-2" THEN CONTINUE
      
      IF INSTR(objects$(i, 4), "takeable") > 0 THEN
        PRINT "You see a "; objects$(i, 2); " here."
      ELSEIF INSTR(objects$(i, 4), "fixed") > 0 OR INSTR(objects$(i, 4), "monster") > 0 THEN
        PRINT "There is a "; objects$(i, 2); " here."
      END IF
    END IF
  END IF
NEXT i

GOSUB ShowExits
RETURN

ShowExits:
IF rooms$(currentRoom, 3) = "" THEN RETURN

GOSUB SplitExits
hasExit = 0
exitText$ = "Exits: "

IF VAL(exitNorth$) > 0 THEN exitText$ = exitText$ + "north ": hasExit = 1
IF VAL(exitSouth$) > 0 THEN exitText$ = exitText$ + "south ": hasExit = 1
IF VAL(exitEast$) > 0 THEN exitText$ = exitText$ + "east ": hasExit = 1
IF VAL(exitWest$) > 0 THEN exitText$ = exitText$ + "west ": hasExit = 1

IF hasExit THEN PRINT exitText$
RETURN

SplitExits:
exits$ = rooms$(currentRoom, 3)
exitNorth$ = "0": exitSouth$ = "0": exitEast$ = "0": exitWest$ = "0"

IF exits$ <> "" THEN
  pos1 = INSTR(exits$, ",")
  IF pos1 > 0 THEN
    exitNorth$ = LEFT$(exits$, pos1 - 1)
    rest$ = MID$(exits$, pos1 + 1)
    
    pos2 = INSTR(rest$, ",")
    IF pos2 > 0 THEN
      exitSouth$ = LEFT$(rest$, pos2 - 1)
      rest$ = MID$(rest$, pos2 + 1)
      
      pos3 = INSTR(rest$, ",")
      IF pos3 > 0 THEN
        exitEast$ = LEFT$(rest$, pos3 - 1)
        exitWest$ = MID$(rest$, pos3 + 1)
      ELSE
        exitEast$ = rest$
      END IF
    ELSE
      exitSouth$ = rest$
    END IF
  ELSE
    exitNorth$ = exits$
  END IF
END IF
RETURN

ParseCommand:
SELECT CASE command$
  CASE "N", "NORTH": GOSUB GoNorth
  CASE "S", "SOUTH": GOSUB GoSouth
  CASE "E", "EAST": GOSUB GoEast
  CASE "W", "WEST": GOSUB GoWest
  CASE "L", "LOOK": found = 1  ' Don't redisplay room
  CASE "I", "INVENTORY": GOSUB ShowInventory
  CASE "H", "HELP": GOSUB ShowHelp
  CASE "Q", "QUIT": GOSUB QuitGame
  CASE "SCORE": GOSUB ShowScore
  CASE ELSE:
    IF LEFT$(command$, 4) = "TAKE" OR LEFT$(command$, 3) = "GET" THEN
      GOSUB TakeObject
    ELSEIF LEFT$(command$, 7) = "EXAMINE" OR LEFT$(command$, 1) = "X" THEN
      GOSUB ExamineObject
    ELSEIF LEFT$(command$, 3) = "USE" THEN
      GOSUB UseObject
    ELSEIF LEFT$(command$, 6) = "SEARCH" THEN
      GOSUB SearchCommand
    ELSEIF LEFT$(command$, 6) = "ATTACK" OR LEFT$(command$, 5) = "FIGHT" OR LEFT$(command$, 4) = "KILL" THEN
      GOSUB AttackCommand
    ELSE
      ' Try to get custom "don't understand" message
      tempKey$ = "dont_understand"
      GOSUB GetMessage
      IF msg$ <> "" THEN 
        PRINT msg$
      ELSE
        PRINT "I don't understand that. Type HELP for commands."
      END IF
    END IF
END SELECT
RETURN

UseObject:
' Handle USE command for object interactions
IF LEN(command$) <= 4 THEN
  PRINT "Use what?"
  RETURN
END IF

' Extract object names from various formats: "USE key gate", "USE key WITH gate", "USE key ON gate"
useCommand$ = MID$(command$, 5)  ' Remove "USE "

' Handle "USE obj WITH target" or "USE obj ON target"
IF INSTR(useCommand$, " WITH ") > 0 THEN
  spacePos = INSTR(useCommand$, " WITH ")
  obj1$ = LEFT$(useCommand$, spacePos - 1)
  obj2$ = MID$(useCommand$, spacePos + 6)  ' Skip " WITH "
ELSEIF INSTR(useCommand$, " ON ") > 0 THEN
  spacePos = INSTR(useCommand$, " ON ")
  obj1$ = LEFT$(useCommand$, spacePos - 1)
  obj2$ = MID$(useCommand$, spacePos + 4)   ' Skip " ON "
ELSE
  ' Handle "USE obj target" (space-separated)
  spacePos = INSTR(useCommand$, " ")
  IF spacePos > 0 THEN
    obj1$ = LEFT$(useCommand$, spacePos - 1)
    obj2$ = MID$(useCommand$, spacePos + 1)
  ELSE
    PRINT "Use what with what?"
    RETURN
  END IF
END IF

' Trim any extra spaces
DO WHILE LEFT$(obj1$, 1) = " " AND LEN(obj1$) > 0
  obj1$ = MID$(obj1$, 2)
LOOP
DO WHILE RIGHT$(obj1$, 1) = " " AND LEN(obj1$) > 0
  obj1$ = LEFT$(obj1$, LEN(obj1$) - 1)
LOOP
DO WHILE LEFT$(obj2$, 1) = " " AND LEN(obj2$) > 0
  obj2$ = MID$(obj2$, 2)
LOOP
DO WHILE RIGHT$(obj2$, 1) = " " AND LEN(obj2$) > 0
  obj2$ = LEFT$(obj2$, LEN(obj2$) - 1)
LOOP

obj1$ = UCASE$(obj1$)
obj2$ = UCASE$(obj2$)

' Check if player has first object (more flexible matching)
hasObj1 = 0
FOR i = 1 TO inventoryCount
  IF INSTR(UCASE$(inventory$(i)), obj1$) > 0 THEN hasObj1 = 1: EXIT FOR
NEXT i

IF hasObj1 THEN
  ' Try custom response for "use obj1 obj2"
  customCmd$ = "USE " + obj1$ + " " + obj2$
  FOR i = 1 TO numResponses
    IF UCASE$(responses$(i, 1)) = customCmd$ THEN
      tempCondition$ = responses$(i, 2)
      GOSUB EvaluateCondition
      IF conditionResult = 1 THEN
        PRINT responses$(i, 3)
        IF responses$(i, 4) <> "" THEN 
          tempAction$ = responses$(i, 4)
          GOSUB ExecuteAction
        END IF
        RETURN
      END IF
    END IF
  NEXT i
  PRINT "You can't use the "; obj1$; " with the "; obj2$; "."
ELSE
  PRINT "You don't have a "; obj1$; "."
END IF
RETURN

GoNorth:
GOSUB SplitExits
newRoom = VAL(exitNorth$)
IF newRoom > 0 THEN
  currentRoom = newRoom
ELSE
  tempKey$ = "cant_go"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "You can't go that way."
END IF
RETURN

GoSouth:
GOSUB SplitExits
newRoom = VAL(exitSouth$)
IF newRoom > 0 THEN
  currentRoom = newRoom
ELSE
  tempKey$ = "cant_go"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "You can't go that way."
END IF
RETURN

GoEast:
GOSUB SplitExits
newRoom = VAL(exitEast$)
IF newRoom > 0 THEN
  currentRoom = newRoom
ELSE
  tempKey$ = "cant_go"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "You can't go that way."
END IF
RETURN

GoWest:
GOSUB SplitExits
newRoom = VAL(exitWest$)
IF newRoom > 0 THEN
  currentRoom = newRoom
ELSE
  tempKey$ = "cant_go"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "You can't go that way."
END IF
RETURN

ShowInventory:
IF inventoryCount = 0 THEN
  tempKey$ = "inventory_empty"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "You aren't carrying anything."
ELSE
  PRINT "You are carrying:"
  FOR i = 1 TO inventoryCount
    PRINT "  "; inventory$(i)
  NEXT i
END IF
RETURN

ShowScore:
PRINT "Score: "; STR$(gameScore); " out of "; STR$(maxScore); " points"
RETURN

ShowHelp:
PRINT "Available commands:"
PRINT "NORTH, SOUTH, EAST, WEST (or N, S, E, W) - Move around"
PRINT "LOOK (or L) - Look around the current room"
PRINT "TAKE <object> (or GET) - Pick up an object"
PRINT "EXAMINE <object> (or X) - Look at something closely"
PRINT "USE <object1> <object2> - Use objects together"
PRINT "SEARCH <object> - Search an object for hidden things"
PRINT "ATTACK <target> (or FIGHT) - Attack an enemy"
PRINT "INVENTORY (or I) - Show what you're carrying"
PRINT "SCORE - Show current score"
PRINT "HELP (or H) - Show this help"
PRINT "QUIT (or Q) - Quit the game"
RETURN

QuitGame:
PRINT "Thanks for playing!"
IF gameScore > 0 THEN PRINT "Final score: "; STR$(gameScore); "/"; STR$(maxScore)
END

TakeObject:
cmdLen = LEN(command$)
IF (LEFT$(command$, 4) = "TAKE" AND cmdLen <= 5) OR (LEFT$(command$, 3) = "GET" AND cmdLen <= 4) THEN
  PRINT "Take what?"
  RETURN
END IF

IF LEFT$(command$, 4) = "TAKE" THEN
  objName$ = MID$(command$, 6)
ELSE
  objName$ = MID$(command$, 5)  ' GET command
END IF

found = 0

FOR i = 1 TO 50
  IF objects$(i, 0) <> "" AND objects$(i, 1) <> "" THEN
    IF VAL(objects$(i, 1)) = currentRoom THEN
      IF UCASE$(objects$(i, 2)) = objName$ OR INSTR(UCASE$(objects$(i, 2)), objName$) > 0 THEN
        IF INSTR(objects$(i, 4), "takeable") > 0 THEN
          IF inventoryCount >= 20 THEN
            PRINT "You can't carry any more."
            RETURN
          END IF
          
          inventoryCount = inventoryCount + 1
          inventory$(inventoryCount) = objects$(i, 2)
          objects$(i, 1) = "-1"  ' Remove from room
          
          ' Check for custom take response
          customTake$ = "TAKE " + UCASE$(objects$(i, 2))
          FOR j = 1 TO numResponses
            IF UCASE$(responses$(j, 1)) = customTake$ THEN
              PRINT responses$(j, 3)
              IF responses$(j, 4) <> "" THEN 
                tempAction$ = responses$(j, 4)
                GOSUB ExecuteAction
              END IF
              found = 1
              RETURN
            END IF
          NEXT j
          
          PRINT "Taken."
          found = 1
          EXIT FOR
        ELSE
          PRINT "You can't take that."
          found = 1
          EXIT FOR
        END IF
      END IF
    END IF
  END IF
NEXT i

IF NOT found THEN 
  tempKey$ = "not_here"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "I don't see that here."
END IF
RETURN

SearchCommand:
' Handle SEARCH command
IF LEN(command$) <= 7 THEN
  PRINT "Search what?"
  RETURN
END IF

objName$ = MID$(command$, 8)
found = 0

' Check for custom search responses first
customSearch$ = "SEARCH " + UCASE$(objName$)
FOR i = 1 TO numResponses
  IF UCASE$(responses$(i, 1)) = customSearch$ THEN
    tempCondition$ = responses$(i, 2)
    GOSUB EvaluateCondition
    IF conditionResult = 1 THEN
      PRINT responses$(i, 3)
      IF responses$(i, 4) <> "" THEN 
        tempAction$ = responses$(i, 4)
        GOSUB ExecuteAction
      END IF
      found = 1
      RETURN
    END IF
  END IF
NEXT i

IF NOT found THEN PRINT "You search but find nothing of interest."
RETURN

AttackCommand:
' Handle ATTACK/FIGHT commands
IF LEN(command$) <= 7 THEN
  PRINT "Attack what?"
  RETURN
END IF

' Extract target name
IF LEFT$(command$, 6) = "ATTACK" THEN
  objName$ = MID$(command$, 8)
ELSEIF LEFT$(command$, 5) = "FIGHT" THEN
  objName$ = MID$(command$, 7)
ELSE
  objName$ = MID$(command$, 6)  ' KILL
END IF

found = 0

' Check for custom attack responses first
customAttack$ = "ATTACK " + UCASE$(objName$)
FOR i = 1 TO numResponses
  IF UCASE$(responses$(i, 1)) = customAttack$ OR INSTR(UCASE$(responses$(i, 1)), "ATTACK") > 0 THEN
    tempCondition$ = responses$(i, 2)
    GOSUB EvaluateCondition
    IF conditionResult = 1 THEN
      PRINT responses$(i, 3)
      IF responses$(i, 4) <> "" THEN 
        tempAction$ = responses$(i, 4)
        GOSUB ExecuteAction
      END IF
      found = 1
      RETURN
    END IF
  END IF
NEXT i

' Also check for FIGHT responses
customFight$ = "FIGHT " + UCASE$(objName$)
FOR i = 1 TO numResponses
  IF UCASE$(responses$(i, 1)) = customFight$ THEN
    tempCondition$ = responses$(i, 2)
    GOSUB EvaluateCondition
    IF conditionResult = 1 THEN
      PRINT responses$(i, 3)
      IF responses$(i, 4) <> "" THEN 
        tempAction$ = responses$(i, 4)
        GOSUB ExecuteAction
      END IF
      found = 1
      RETURN
    END IF
  END IF
NEXT i

IF NOT found THEN PRINT "You can't attack that!"
RETURN

ExamineObject:
IF (LEFT$(command$, 7) = "EXAMINE" AND LEN(command$) <= 8) OR (LEFT$(command$, 1) = "X" AND LEN(command$) <= 2) THEN
  PRINT "Examine what?"
  RETURN
END IF

IF LEFT$(command$, 1) = "X" THEN
  objName$ = MID$(command$, 3)
ELSE
  objName$ = MID$(command$, 9)
END IF

found = 0

' Check for custom examine responses first
customExamine$ = "EXAMINE " + UCASE$(objName$)
FOR i = 1 TO numResponses
  IF UCASE$(responses$(i, 1)) = customExamine$ THEN
    tempCondition$ = responses$(i, 2)
    GOSUB EvaluateCondition
    IF conditionResult = 1 THEN
      PRINT responses$(i, 3)
      IF responses$(i, 4) <> "" THEN 
        tempAction$ = responses$(i, 4)
        GOSUB ExecuteAction
      END IF
      found = 1
      RETURN
    END IF
  END IF
NEXT i

' Default object examination
FOR i = 1 TO 50
  IF objects$(i, 0) <> "" AND objects$(i, 1) <> "" THEN
    IF VAL(objects$(i, 1)) = currentRoom OR objects$(i, 1) = "-1" THEN
      IF UCASE$(objects$(i, 2)) = objName$ OR INSTR(UCASE$(objects$(i, 2)), objName$) > 0 THEN
        PRINT objects$(i, 3)
        found = 1
        EXIT FOR
      END IF
    END IF
  END IF
NEXT i

IF NOT found THEN 
  tempKey$ = "not_here"
  GOSUB GetMessage
  IF msg$ <> "" THEN PRINT msg$ ELSE PRINT "I don't see that here."
END IF
RETURN