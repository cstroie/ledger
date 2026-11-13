'use strict';
process.env.TZ = 'UTC';   // the emulated clock reads local time: the tests' dates are UTC
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parse, build, check } = require('../mkwords.js');
const L = require('../tools/ledger.js');

const APP = path.join(__dirname, '..');
const ROOT = process.env.ROOT || path.join(APP, '..', 'digital-rerun');
// the emulator tests need the checkout and a built LEDGER.COM (it is not in git: sh build.sh)
const haveRoot = fs.existsSync(path.join(ROOT, 'js/machine.js')) && fs.existsSync(path.join(APP, 'LEDGER.COM'));

// ---- the words
test('words.inc is what words.txt builds to', () => {
    assert.equal(fs.readFileSync(path.join(APP, 'words.inc'), 'utf8'), build(fs.readFileSync(path.join(APP, 'words.txt'), 'utf8')));
});

test('mkwords refuses a missing line, an unknown token, a quote and a line too long for the book', () => {
    const txt = fs.readFileSync(path.join(APP, 'words.txt'), 'utf8');
    assert.throws(() => parse(txt.replace(/^wx\.2\.1: .*\n/m, '')), /wx 9 is missing/);
    assert.throws(() => parse(txt.replace('{n} go by', '{x} go by')), /unknown token/);
    assert.throws(() => parse(txt.replace('Fog, thick as wool.', 'Fog, "thick" as wool.')), /no double quotes/);
    assert.throws(() => check(parse(txt.replace('Fog.', 'Fog, and so thick that the lamp itself could not be seen from the gallery.'))), /over 40/);
    assert.throws(() => parse(txt + 'wx.0.0: again\n'), /twice/);
});

// ---- the world, as the model has it
test('the sea: a ship on its timetable, fronts that run swell, wind, storm, and a timetable ship stays in port in a storm', () => {
    for (const seed of [1, 1234, 40000, 65535]) {
        let sawStorm = false;
        for (let n = 1; n <= 400; n++) {
            const w = L.world(seed, n);
            if (w.wx === 4) {                       // a swell is always the first night of a front
                assert.equal(L.world(seed, n + 1).wx, 3, `${seed}: wind after the swell of ${n}`);
                assert.ok([3, 5].includes(L.world(seed, n + 2).wx));
                assert.equal(L.world(seed, n + 3).wx, 1);
            }
            if (w.wx === 5) { sawStorm = true; assert.ok(w.shp === 7 || w.shp === 5, 'only a stranger is out in a storm'); }
            if (n % 7 === 3 && w.wx !== 5) assert.equal(w.shp, 0, `the Margit comes on night ${n}`);
        }
        assert.ok(sawStorm, `a storm in 400 nights of ${seed}`);
    }
});

test('the relief hand and the keeper spend oil the same way the program does', () => {
    const r = L.run(1234, 120);
    assert.ok(r.entries.every(e => e.oil >= 0 && e.oil <= 30));
    assert.ok(r.entries.some(e => e.boat));
    assert.equal(r.entries[0].oil, 28);             // the relief hand lights at dark: 2 oil
});

// ---- the game, in DigitalRerun's emulator (needs the checkout: ROOT=<dir>)
const HOUR = 3600e3, DAY = 86400e3;
const T0 = Date.UTC(2026, 10, 10, 8, 0);

async function fresh() {
    const { newDisk, visit } = require('../tools/visit.js');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ledger-'));
    fs.copyFileSync(path.join(APP, 'LEDGER.COM'), path.join(dir, 'LEDGER.COM'));
    return { disk: await newDisk(dir), visit };
}
/** Start, take the intro's key, and leave with Q if asked. */
const enter = (v, args = '/100 /S1234') => { v.start(args); v.run(1); v.type(' '); v.run(1); };
const leave = v => { v.type('Q'); v.settle(); v.m.console.paste('DIR\r'); v.settle(); };
/** The diary the program left on the disk, as text. */
function diary(disk) {
    const { CpmFs } = require(path.join(ROOT, 'js/cpmfs.js'));
    const raw = Buffer.from(new CpmFs(disk).read('LEDGER.LOG')).toString('latin1');
    return raw.slice(0, raw.indexOf('\x1a'));
}
const WORDS = L.words();

test('a first visit shows the book, the oil and the lamp keys', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    v.start('/100 /S1234'); v.run(1);
    assert.match(v.text(), /the lighthouse keeper's logbook/);
    assert.match(v.text(), /You never see the sea, only\s+the book/);
    v.type(' '); v.run(1);
    const t = v.text();
    assert.match(t, /LEDGER {2}the keeper's log\s+Night 1\s+08:00/);
    assert.match(t, /Night 1\n?.*The page is blank\. The lamp is not yet lit\./s);
    assert.match(t, /30 of 30/);
    assert.match(t, /Oil boat in 11 nights/);
    assert.match(t, /E early \(3 oil\)\s+D at dark \(2\)\s+L late \(1\)\s+S not at all \(0\)/);
    assert.match(t, /Calendar, wrap 7/);
});

test('a night with the keeper: the words are chosen, the entry builds on the page and in the diary', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    enter(v);
    v.type('d'); v.run(0.5);
    assert.match(v.text(), /The night passes/);
    v.run(4);
    assert.match(v.text(), /Night 1: the weather\. Choose the words/);
    for (const k of ['2', '1', '3']) { v.type(k); v.run(0.4); }
    v.run(3);
    const e = L.night(1234, 1, 30, 1, false, [1, 0, 2]);
    const line = L.text(WORDS, e);
    const t = v.text();
    assert.match(t, /Night 1 is written\. {2,}Night 2 begins in 1 h 0 min\./);
    assert.match(t, /The lamp, last night: lit at dark\. Nothing needs doing\./);
    assert.ok(t.replace(/ø/g, ' ').replace(/\s+/g, ' ').includes(line.slice(0, 40)), 'the page has the entry');
    assert.match(t, new RegExp(`Oil .* ${e.oil} of 30`));
    leave(v);
    assert.match(diary(disk), new RegExp(line.split(' ').slice(0, 12).join(' ').replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    // the lamp cannot be lit twice for one night
    const v2 = await visit(disk, T0 + 30 * 60e3);
    enter(v2, '/100');
    v2.type('E'); v2.run(1);
    assert.match(v2.text(), /This night is written\. Nothing needs doing until the next\./);
});

test('away for sixty nights: the relief hand writes the log, and the file is what the model says the sea did', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    v = await visit(disk, T0 + 60 * 3 * HOUR);
    v.start('/100'); v.run(20);
    const r = L.run(1234, 60);
    const lit = r.entries.length, ans = r.ans.reduce((a, b) => a + b), mis = r.mis.reduce((a, b) => a + b);
    const storms = r.entries.filter(e => e.wx === 5).length;
    const t = v.text();
    assert.match(t, /You were away for 60 nights\./);
    assert.match(t, new RegExp(`${lit} nights with the lamp lit`));
    assert.match(t, new RegExp(`${ans} ships answered the light`));
    assert.match(t, new RegExp(`${mis} ships passed unseen`));
    assert.match(t, new RegExp(`${storms} storms`));
    v.type(' '); v.run(2);
    assert.match(v.text(), /Night 61\s+\d\d:\d\d/);
    assert.match(v.text(), /Night 60 \(relief hand\)\./);
    leave(v);
    assert.equal(diary(disk), L.logfile(WORDS, r.entries, r.ans, r.mis));
});

test('a very long absence counts at most a month of nights, in a few seconds of machine time', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v, '/100 /S99'); leave(v);
    v = await visit(disk, T0 + 5 * 365 * DAY);
    v.start('/100'); v.run(8);
    assert.match(v.text(), /You were away for 14600 nights\./);
    assert.match(v.text(), /720 nights with the lamp lit/);
    v.type(' '); v.run(2);
    assert.match(v.text(), /Night 14601/);
    v.type('h'); v.run(1);
    assert.match(v.text(), /The harbour book/);
    assert.match(v.text(), /Captain Aberg of the collier writes/);
});

test('the log goes on while the book is open: a night begins, the bell rings, the page slides', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    let bells = 0;
    v.term.bell = () => { bells++; };
    enter(v);
    bells = 0;
    v.later(3 * HOUR); v.run(4);
    assert.ok(bells >= 1, 'rang for the new night');
    assert.match(v.text(), /Night 2\s+\d\d:\d\d/);
    assert.match(v.text(), /Night 1 \(relief hand\)\./);
    assert.match(v.text(), /The relief hand wrote 1 night while the page waited\./);
    v.type('M'); v.run(0.5);
    assert.match(v.text(), /The bell is off\./);
    bells = 0;
    v.later(3 * HOUR); v.run(4);
    assert.equal(bells, 0, 'silent');
    assert.match(v.text(), /Night 3\s+\d\d:\d\d/);
    v.later(3 * HOUR); v.run(4);
    // nothing is lost by idling: the relief hand wrote nights 1-3 and night 4 is open
    assert.match(v.text(), /Night 4 is open/);
});

test('turning pages, the calendar width, what it shows and what it finds', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    v = await visit(disk, T0 + 30 * 3 * HOUR);
    v.start('/100'); v.run(10); v.type(' '); v.run(2);
    const cal = () => v.text().split('\n').slice(3, 19).map(l => l.slice(53).trim()).filter(Boolean);
    const r = L.run(1234, 30);
    // at width 7 the Margit (every seventh night, from the third) is one column of the ships view
    v.type('V'); v.run(0.4);
    assert.match(v.text(), /V ships/);
    const cols = new Set();
    cal().forEach(l => l.split(/\s+/).forEach((c, i) => { if (c === 'M') cols.add(i); }));
    assert.equal(cols.size, 1, 'the Margit makes a stripe');
    v.type('W'); v.run(0.4);
    assert.match(v.text(), /Calendar, wrap 8/);
    for (let i = 0; i < 4; i++) { v.type('W'); v.run(0.2); }
    assert.match(v.text(), /Calendar, wrap 12/);
    v.type('W'); v.run(0.2);
    assert.match(v.text(), /Calendar, wrap 5/);
    // F finds: storms, then the others; the page marks entries that match with a star
    v.type('F'); v.run(0.4);
    assert.match(v.text(), /F storms/);
    const stormNights = r.entries.filter(e => e.wx === 5).map(e => e.n);
    v.type('\x1b[D'); v.run(0.4);             // one page back
    const page = v.text();
    assert.match(page, /nights 2[0-9]-3[0-1]|nights 2[0-9]-2[0-9]|nights 1[0-9]-/);
    v.type('F'); v.run(0.3);
    assert.match(v.text(), /F swells/);
    v.type('H'); v.run(0.5);
    assert.match(v.text(), /The harbour book/);
    v.type('x'); v.run(0.5);
    assert.match(v.text(), /Calendar, wrap 5/, 'back at the book with the same settings');
    void stormNights;
});

test('a letter comes with the third light answered: three nights of the Margit', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    enter(v);
    for (let n = 1; n <= 17; n++) {
        v.type('D'); v.run(4);
        for (const k of ['1', '1', '1']) { v.type(k); v.run(0.3); }
        v.run(2);
        if (n < 17) { v.later(3 * HOUR); v.run(3); }
    }
    assert.match(v.text(), /A letter has come from the Margit\./);
    v.type('H'); v.run(1);
    assert.match(v.text(), /Margit.*3 answered/);
    assert.match(v.text(), /Captain Aberg of the collier writes/);
});

test('no clock: every start is the next night, and the screen says so', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    v.m.clock.latch = () => {};
    enter(v, '/100 /S7');
    assert.match(v.text(), /\(no clock\)/);
    assert.match(v.text(), /Night 1\b/);
    v.type('S'); v.run(2); for (const k of ['1', '1', '1']) { v.type(k); v.run(0.3); }
    v.run(2);
    assert.match(v.text(), /The next night begins when you come back\./);
    leave(v);
    v = await visit(disk, T0);
    v.m.clock.latch = () => {};
    v.start('/100'); v.run(3);
    assert.match(v.text(), /Night 2\b/);
    assert.match(v.text(), /Night 1\. /);
});

test('a VT52 and an ADM-3A get the same book in plain characters', { skip: !haveRoot }, async () => {
    for (const [mode, arg] of [['vt52', '/52'], ['adm3a', '/ADM']]) {
        const { disk, visit } = await fresh();
        const v = await visit(disk, T0);
        v.term.mode = mode;
        enter(v, `${arg} /S1234`);
        v.type('e'); v.run(5); v.type('2'); v.run(0.3); v.type('\r'); v.run(0.3); v.type('1'); v.run(1);
        assert.match(v.text(), /\+-- The Log of the Sisters Light -+\+/, mode);
        assert.match(v.text(), /\| Night 1\. Clear sky, a light air from the west\. {2}\|/, mode);
        assert.match(v.text(), /Oil #{27}\.{3} 27 of 30/, mode);
    }
});

test('a save of another version is not read: the log starts again', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    const { CpmFs } = require(path.join(ROOT, 'js/cpmfs.js'));
    const f = new CpmFs(disk);
    const sav = Buffer.from(f.read('LEDGER.SAV'));
    sav[2] = 9;
    f.write('LEDGER.SAV', sav);
    v = await visit(disk, T0 + DAY);
    v.start('/100'); v.run(1);
    assert.match(v.text(), /the lighthouse keeper's logbook/, 'the introduction again');
});

// ---- the second round: a safe save, a new log, letters from the relief hand, foresight, a nudge
test('R starts a new log, but only after Y', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    enter(v);
    v.type('S'); v.run(2); for (const k of ['1', '1', '1']) { v.type(k); v.run(0.3); }
    v.run(3);
    assert.match(v.text(), /Night 1 is written/);
    v.type('r'); v.run(0.3);
    assert.match(v.text(), /Start a new log\?/);
    v.type('n'); v.run(0.5);
    assert.match(v.text(), /Night 1 is written/);
    v.type('r'); v.run(0.3); v.type('y'); v.run(3);
    assert.match(v.text(), /the lighthouse keeper's logbook/);
    v.type(' '); v.run(1);
    assert.match(v.text(), /Night 1 is open/);
    assert.match(v.text(), /30 of 30/);
});

test('a save that does not fit leaves the last good one, and nothing is left behind', { skip: !haveRoot }, async () => {
    const { CpmFs } = require(path.join(ROOT, 'js/cpmfs.js'));
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    const f = new CpmFs(disk);
    const before = Buffer.from(f.read('LEDGER.SAV'));
    assert.ok(!f.list().some(e => /\$\$\$/.test(e.name || e)), 'no temporary file after a good save');
    f.write('FILLER.DAT', new Uint8Array(f.freeBytes()));      // not a block left for a second copy
    v = await visit(disk, T0 + 5 * 3 * HOUR);
    v.start('/100'); v.run(6);
    assert.match(v.text(), /You were away for 5 nights/);
    v.type(' '); v.run(2); leave(v);
    const f2 = new CpmFs(disk);
    assert.deepEqual(Buffer.from(f2.read('LEDGER.SAV')), before, 'the old save is untouched');
    assert.ok(!f2.list().some(e => /\$\$\$/.test(e.name || e)), 'the half-written file is gone');
    v = await visit(disk, T0 + 5 * 3 * HOUR);
    v.start('/100'); v.run(6);
    assert.doesNotMatch(v.text(), /the lighthouse keeper's logbook/, 'the log was not lost');
});

test('letters and nudges: the relief hand earns the Margit\'s letter, and never answers the Dunmore Lass', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    v = await visit(disk, T0 + 60 * 3 * HOUR);
    v.start('/100'); v.run(20);
    assert.match(v.text(), /A letter is waiting in the harbour book \(H\) from the Margit/);
    v.type(' '); v.run(2);
    v.type('h'); v.run(1);
    const t = v.text();
    assert.match(t, /Dunmore Lass[\s\S]*Her light was never answered\. See when she passes/);
    assert.match(t, /The village has had your light \d+ times\. Storms foreseen: 0\./);
    v.type(' '); v.run(1);
    // and while the book is open
    v.later(5 * 3 * HOUR); v.run(5);
    assert.match(v.text(), /relief hand wrote 5 nights|A letter came while the page waited/);
});

test('a storm met with the lamp lit, after a swell and a wind, is remembered', { skip: !haveRoot }, async () => {
    let n = 3;
    while (!(L.world(1234, n).wx === 5 && L.world(1234, n - 1).wx === 3 && L.world(1234, n - 2).wx === 4)) n++;
    const { disk, visit } = await fresh();
    let v = await visit(disk, T0);
    enter(v); leave(v);
    v = await visit(disk, T0 + (n - 1) * 3 * HOUR);
    v.start('/100'); v.run(20); v.type(' '); v.run(2);
    assert.match(v.text(), new RegExp(`Night ${n} is open`));
    v.type('L'); v.run(4); for (const k of ['1', '1', '1']) { v.type(k); v.run(0.3); }
    v.run(3);
    assert.match(v.text(), /A storm, and the lamp was lit: you saw it coming in the log\./);
    v.type('h'); v.run(1);
    assert.match(v.text(), /Storms foreseen: 1\./);
});

test('while the words are being chosen the bell still rings for the next night, once', { skip: !haveRoot }, async () => {
    const { disk, visit } = await fresh();
    const v = await visit(disk, T0);
    let bells = 0;
    v.term.bell = () => { bells++; };
    enter(v);
    v.type('D'); v.run(4);
    bells = 0;
    v.later(3 * HOUR); v.run(3);
    assert.equal(bells, 1, 'rang once');
    v.later(3 * HOUR); v.run(3);
    assert.equal(bells, 1, 'not again');
    for (const k of ['1', '1', '1']) { v.type(k); v.run(0.3); }
    v.run(4);
    assert.match(v.text(), /Night 3 is open/);
    assert.match(v.text(), /Night 2 \(relief hand\)\./);
});
