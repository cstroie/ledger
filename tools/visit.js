'use strict';
/*
 * visit.js: a machine with a disk and a clock we control, to run LEDGER on at chosen times.
 * For tests and for looking at the pool a week on. Needs the DigitalRerun checkout (ROOT,
 * default ../digital-rerun).
 *
 *   const { newDisk, visit } = require('./visit.js');
 *   const disk = await newDisk(folder);                       // B: with LEDGER.COM on it
 *   const v = await visit(disk, Date.UTC(2026, 10, 10, 8));    // a machine whose clock says this
 *   v.start('/100'); v.run(2); v.text(); v.type('Q'); ...
 *
 * The clock is the machine's date and time set at reset (UTC here: the test sets TZ=UTC).
 */
const fs = require('node:fs');
const path = require('node:path');
const ROOT = process.env.ROOT || path.join(__dirname, '..', '..', 'digital-rerun');
const { Machine } = require(path.join(ROOT, 'js/machine.js'));
const { Disk } = require(path.join(ROOT, 'js/devices/fdc.js'));
const { fromFolder } = require(path.join(ROOT, 'js/folderdisk.js'));
const { Terminal } = require(path.join(ROOT, 'js/terminal.js'));

async function newDisk(folder) {
    const items = fs.readdirSync(folder).map(n => ({ path: n, read: async () => new Uint8Array(fs.readFileSync(path.join(folder, n))) }));
    return (await fromFolder(items, 'DEV')).disk;
}

async function visit(disk, when) {
    const m = new Machine();
    m.clock.now = () => when;
    const term = new Terminal();
    m.console.output = b => term.write(b);
    m.fdc.mount(0, Disk.fromImage(new Uint8Array(fs.readFileSync(path.join(ROOT, 'disks/cpm22.dsk')))));
    m.fdc.mount(1, disk);
    m.reset();
    const run = sec => { for (let i = 0; i < sec * 20; i++) m.run(200000); };    // 50 ms a step at 4 MHz
    const settle = () => { for (let i = 0; i < 40000; i++) { m.run(200000); if (m.waiting) return; } };
    settle();
    m.console.paste('B:\r'); settle();
    const v = {
        m, term, run, settle,
        text: () => term.text().split('\n').map(l => l.replace(/\s+$/, '')).join('\n'),
        start: (args = '') => { m.console.paste('LEDGER ' + args + '\r'); },
        type: k => m.console.type(k),
        /** Move the clock on: the machine will see `ms` more of the host's time. */
        later: ms => { m.clock.base += ms; },
    };
    return v;
}

module.exports = { newDisk, visit, ROOT };
