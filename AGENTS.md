# AGENTS.md

Ledger: the lighthouse keeper's logbook, a Z80 game for CP/M 2.2 (80x24, VT100/VT52/ADM-3A).
Standalone project; DigitalRerun only ships the built `LEDGER.COM`. Read `DESIGN.md` first.

- Build: `sh build.sh` (needs `node` and `pasmo`). `words.inc` is generated from `words.txt` by
  `mkwords.js`: edit `words.txt`, never `words.inc`. `LEDGER.COM` is not in git; releases carry it.
- Test: `ROOT=<digital-rerun checkout> node --test test/*.test.js` (build first). Without the
  checkout, or without `LEDGER.COM`, only the text and model tests run.
- `tools/ledger.js` is the world written a second time in JavaScript; the emulator tests compare
  the real program's `LEDGER.LOG` with it, so a change to the rules goes in both places.
- Keep the save versioned (`DESIGN.md`) so an old `LEDGER.SAV` starts a new log rather than breaking.
- Version: `VERSION` and `CHANGELOG.md`; tag releases `vX.Y.Z`. Commits: `feat:`, `fix:`, `docs:`.
