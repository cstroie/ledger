# Ledger (LEDGER)

The lighthouse keeper's logbook. You keep a coastal light for a village and never see the sea, only
the book. Each night (three hours of the real clock) you choose how the lamp burns, early, at dark,
late or not at all, and the words you write. What passed in the dark is only in the log, and the
patterns in the log predict the storms and the ships: a ship that came on the 3rd, the 10th and the
17th will come again. No combat, nothing to lose: the tension is whether to light the lamp early or
save the oil. Away, a relief hand keeps the lamp and writes plain entries. The diary, `LEDGER.LOG`,
is plain text you can `TYPE`.

Z80 assembly, CP/M 2.2, 80x24, VT100 (line drawing, scroll region, dim, bold, blink, reverse) /
VT52 / ADM-3A. Written for [DigitalRerun](https://github.com/cstroie/digital-rerun), where it sits on
the shelf, and where the machine has a clock device on port 20 to read the date and time from.
Player's guide: [docs/PLAYING.txt](docs/PLAYING.txt). Design notes: [DESIGN.md](DESIGN.md).

    sh build.sh        words.inc (node mkwords.js), then LEDGER.COM (pasmo)
    node --test test/  needs a DigitalRerun checkout (ROOT=<dir>, default ../../..)

`tools/ledger.js` is the world written a second time in JavaScript; the tests run the real `.COM` in
DigitalRerun's emulator and compare its `LEDGER.LOG` with what the model says the sea did, so the two
must agree to the bit. `node tools/ledger.js 1234 60` prints sixty nights of the sea numbered 1234.

MIT licence.
