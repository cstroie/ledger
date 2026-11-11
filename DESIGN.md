# LEDGER (LEDGER)

A logbook game on the clock. Z80 assembly, CP/M 2.2, 4 MHz, 80x24, one `.COM`, two files: `LEDGER.SAV` (state) and `LEDGER.LOG` (the diary, text).

## Files

| File | Role |
|------|------|
| `ledger.asm` | start, key dispatch, `sync` (catching up), `poll` (the clock, live), `tonight`, memory map |
| `world.asm` | the sea as a pure function (`hash`, `world`), the lamp and oil (`prenight`), the entry (`mkpend`, `commit`), the ring (`entaddr`, `getent`) |
| `fmt.asm` | an entry as a sentence (`fmtent`, the template tokens), `pwrap`; output to memory (`omode`) |
| `ui.asm` | every screen: the book, the calendar, the panel, the horizon, composing, harbour, welcome |
| `clock.asm` | the clock device, 32-bit `mul32`/`div32`, `div16`, delays |
| `save.asm` | `LEDGER.SAV` (7 records), `genlog` and `LEDGER.LOG` |
| `term.asm` | terminal driver; `putc` can write to memory; scroll region |
| `text.asm`, `words.txt`, `mkwords.js` | the words; the phrases of the log are checked and packed into `words.inc` |
| `tools/ledger.js` | the world again in JavaScript, the tests' oracle |

## Time

DigitalRerun's clock gives `M`, minutes since 1978. A night is 180 minutes: `cn32 = M / 180` (32 bits: it passes 65535 in 2000), `pnow = M mod 180`. Night n is `cn32 - st_start + 1` (`calcn`), 16 bits. `sync` writes every night between `st_last` and now as the relief hand (`unatt`), at most `CAP` = 720. `poll` does the same while the book is open and rings the bell. Without the device every start is the next night.

## The sea

A pure function of `st_wseed` and the night, so a night can be worked out when it is wanted and always comes out the same (and the JS model can check it). `hash(value, salt)` is three rounds of the xorshift that `rnd` uses, over `value xor seed + salt`.

*Weather.* Nights come in windows of six. A window has a front when `hash(window)` is even: four nights, swell, wind, storm, haze, starting on the first, second or third night; one in four veers (the storm is only wind). Any other night: fair 50%, haze 19%, fog 19%, wind 12%. Swell exists only as the first night of a front, which is what the player learns.

*Ships.* Five keep a timetable (period, residue: `n mod period`): the Margit every 7th from the 3rd, the Dunmore Lass every 5th from the 1st, the packet every 9th, the Hester Vane every 11th, the Ostrander every 13th; the lowest number wins a collision. A stranger comes 1 night in 16, or in a storm half the time (a storm keeps the others in port). A ship passes at sundown (0), midnight (1) or in the small hours (2), fixed per ship.

*Lamp.* Early 0, dark 1, late 2, none 3; costs 3 2 1 0, +1 in fog or storm, never more than is in the store. A ship is *seen* if the lamp is lit, `lamp <= slot`, and not (fog and lamp late). The boat brings 24 on every 12th night (cap 30). Nothing here can end the game: with no oil the lamp is cold and the ships go unseen.

## The entry

Six bytes, in a ring of 128 (`entaddr`: `(n-1) & 127`; `getent` checks the night in the slot): night (word); weather | wording << 3 | relief << 6; ship | time << 3 | seen << 5 | wording << 6; lamp | boat << 2 | wording << 3; oil. A wording of 3 is the relief hand's plain version. The player chooses only the wording (0-2) of three sentences, never what happened.

`fmtent` turns an entry into text in `tbuf`: with `omode` = 1 `putc` stores into memory, so `puts`, `pdec` and the template expander build a sentence once and the screen (`pwrap` at 47 columns, four lines) or the diary (`pwrap` at 72, CR LF) print it. A ship phrase is a template with tokens: 1 the ship, 5 the ship capitalised, 2 when she passed.

## Screens

Row 1 title bar, row 2 horizon (the beam of a lit lamp crosses it, `beamstep`), rows 3-20 the book (cols 1-51) and the calendar (cols 54-79), rows 21-24 oil, the night, the keys, a message line.

The calendar folds the nights into rows of `calw` (5-12) with `(n-1) mod calw` as the column, so a period p shows as a column at width p whatever the night: the whole game is looking for it. Layers: weather, ships, lamp. Focus (F) lights one thing in reverse.

VT100 only: scroll region (the page slides four lines at the start of a night: `scrollbook`), line drawing for the box and the oil bar, blink for the open night, reverse for labels and finds, dim for hints and what the oil cannot buy, bell. VT52 and ADM-3A get plain characters.

## Save

`LEDGER.SAV`: 896 bytes straight from `state` (signature `LG`, version 1; a load of anything else starts a new log): seed, last night, start night (32 bits), oil, bell, the harbour counts (lights answered and ships unseen per ship), the ring. `LEDGER.LOG`: header, the entries still in the ring oldest first, the harbour book; padded with ^Z to whole records. Both are written after the screen is redrawn.
