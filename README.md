# LEDGER

*The lighthouse keeper's logbook.* A Z80 / CP/M 2.2 game for DigitalRerun (80x24, VT100 best), one `LEDGER.COM`, a save file and a diary you can `TYPE`.

You keep a coastal light for a village and never see the sea, only the logbook. Each night (three hours of the machine's clock) you choose how the lamp burns, early, at dark, late or not at all, and the words you write. What passed in the dark is only in the log, and the patterns in the log predict the storms and the ships: a ship that appears on the 3rd, the 10th and the 17th will come again. There is no combat. The tension is whether to light the lamp early or save the oil. Away, a relief hand keeps the lamp and writes plain entries: nothing is lost, nothing is punished.

The player's guide is `docs/PLAYING.txt`; the design is in `DESIGN.md`.

## Build and test

    apt install pasmo
    sh build.sh                    # words.inc (node mkwords.js), then LEDGER.COM
    ROOT=<DigitalRerun checkout> node --test test/

`tools/ledger.js` is the world written a second time in JavaScript; the tests run the real `.COM` in DigitalRerun's emulator and compare its `LEDGER.LOG` with what the model says the sea did, so the two must agree to the bit. `node tools/ledger.js 1234 60` prints sixty nights of the sea numbered 1234. `tools/screen.js` runs a program and prints the screen; `tools/visit.js` is a machine whose clock you set.

MIT licence, Copyright (c) 2026 Costin Stroie.
