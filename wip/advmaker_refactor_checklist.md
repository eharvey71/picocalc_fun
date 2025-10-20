# Refactor Checklist: advplay -> Data-Driven, Pico-Fast

## A. Loader
- Parse [SETTINGS]; clamp to Pico caps; error if exceeded.
- DIM arrays to SETTINGS sizes.
- Parse [ROOMS] streaming; store desc keys; parse exits into 4 small int arrays.
- Parse [OBJECTS] streaming; cache uppercase names: objNameU$(i).
- Parse [VOCABULARY]; tables for verbs/nouns and stopwords.
- Parse [MESSAGES]; arrays key$[], msg$[].
- Parse [RESPONSES]; store compact triggers, conditions, actions, message key.
- Build name→id maps for rooms, objects, flags, messages, verbs, nouns.

## B. Interpreter
- Manual trim; uppercase once.
- Tokenize; drop stopwords; map to canonical verb/noun ids.
- Evaluate [RESPONSES] in order; on first match, execute actions; print message.
- Default to MSG_UNKNOWN if no rule matches.

## C. Actions (engine primitives)
- PRINT msgId | SETFLAG flagId | CLRFLAG flagId
- TAKE objId | DROP objId | KILL objId | SPAWN objId,roomId
- MOVE roomId | OPEN_EXIT roomId,dir | CLOSE_EXIT roomId,dir
- SCORE delta | END

## D. Renderer
- Render room name + message text by key.
- Support [[IF FLAG:NAME]] … [[END]] in messages (resolve NAME→id at load).
- List visible objects; show exits.

## E. Pico performance
- One token array; overwrite, never ERASE.
- Cache uppercase at load; no repeated UCASE$ at runtime.
- Loop bounds from SETTINGS only.
- Prefer integer ids in hot paths.
- Keep long text in [MESSAGES].

## F. Validation (tiny_test.adv)
- TAKE KEY; USE KEY ON GATE; N; ATTACK BEAST.
- Confirm flags/exits/score change and snappy response.
