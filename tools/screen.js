'use strict';
/*
 * screen.js: run a CP/M program from a folder in DigitalRerun's emulator and print what the
 * terminal shows. For development and tests; needs the DigitalRerun checkout (ROOT, default ../digital-rerun).
 *
 *   node tools/screen.js <folder> <command line> [step ...]
 *
 * steps:  k:<text>  type keys (\r \e \x1b escapes ok)     w:<seconds>  run that much machine time
 *         s         print the screen                       r:<regex>    fail unless the screen matches
 */
const fs = require('node:fs');
const path = require('node:path');
const ROOT = process.env.ROOT || path.join(__dirname, '..', '..', 'digital-rerun');
const { Machine } = require(path.join(ROOT, 'js/machine.js'));
const { Disk } = require(path.join(ROOT, 'js/devices/fdc.js'));
const { fromFolder } = require(path.join(ROOT, 'js/folderdisk.js'));
const { Terminal } = require(path.join(ROOT, 'js/terminal.js'));

async function boot(folder, opts = {}) {
    const items = fs.readdirSync(folder).map(n => ({ path: n, read: async () => new Uint8Array(fs.readFileSync(path.join(folder, n))) }));
    const { disk } = await fromFolder(items, 'DEV');
    const m = new Machine();
    const term = new Terminal();
    m.console.output = b => term.write(b);
    m.fdc.mount(0, Disk.fromImage(new Uint8Array(fs.readFileSync(path.join(ROOT, 'disks/cpm22.dsk')))));
    m.fdc.mount(1, disk);
    m.reset();
    const run = sec => { for (let i = 0; i < sec * 20; i++) m.run(200000); };    // 50 ms a step at 4 MHz
    const settle = () => { for (let i = 0; i < 40000; i++) { m.run(200000); if (m.waiting) return; } };
    settle();
    m.console.paste('B:\r'); settle();
    return { m, term, run, settle, text: () => term.text().split('\n').map(l => l.replace(/\s+$/, '')).join('\n'), disk };
}

module.exports = { boot };

if (require.main === module) {
    (async () => {
        const [folder, cmd, ...steps] = process.argv.slice(2);
        const s = await boot(folder);
        s.m.console.paste(cmd + '\r');
        let bad = 0;
        for (const st of steps) {
            const [op, ...rest] = st.split(':'); const arg = rest.join(':');
            if (op === 'k') s.m.console.type(arg.replace(/\\r/g, '\r').replace(/\\e/g, '\x1b'));
            else if (op === 'w') s.run(parseFloat(arg));
            else if (op === 's') console.log(s.text() + '\n' + '-'.repeat(80));
            else if (op === 'r') { const ok = new RegExp(arg).test(s.text()); console.log(ok ? 'ok   ' + arg : 'FAIL ' + arg); if (!ok) bad = 1; }
        }
        process.exit(bad);
    })();
}
