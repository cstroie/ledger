'use strict';
/*
 * ledger.js: the world of LEDGER, written a second time in JavaScript. The Z80 program and this
 * file must agree to the bit: the tests run the game in the emulator and compare its log with
 * what this model says the sea did. It is also the quickest way to look at a world (a seed) before
 * playing it:   node tools/ledger.js 1234 60
 */
const fs = require('node:fs');
const path = require('node:path');
const { parse, expandShip, BOAT } = require('../mkwords.js');

const SALT = [0xa5c3, 0x3e91, 0x7b17];
const PERIOD = [7, 5, 9, 11, 13], RESIDUE = [3, 1, 4, 6, 9], SLOT = [1, 0, 2, 1, 2];
const COST = [3, 2, 1, 0];
const BOATN = 12, BOATOIL = 24, CAPOIL = 30;
const WX = ['fair', 'haze', 'fog', 'wind', 'swell', 'storm'];

function hmix(x) {
    let h = x >> 8, l = x & 255;
    h = (h ^ (((h & 1) << 7) | (l >> 1))) & 255;
    l = (l ^ (((l & 1) << 7) | (h >> 1))) & 255;
    h = (l ^ h) & 255;
    return (h << 8) | l;
}
function hash(seed, n, salt) {
    let x = ((n ^ seed) + salt) & 0xffff;
    if (x === 0) x = 1;
    return hmix(hmix(hmix(x)));
}

/** What the sea did on night n: weather class, ship (0-4 timetable, 5 stranger, 7 none) and when (0-2). */
function world(seed, n) {
    const win = Math.floor(n / 6), off = n % 6;
    const hw = hash(seed, win, SALT[0]);
    let wx = null;
    if ((hw & 1) === 0) {
        let s = (hw >> 4) & 3; if (s === 3) s = 2;
        const k = off - s;
        if (k >= 0 && k < 4) {
            wx = [4, 3, 5, 1][k];
            if (k === 2 && ((hw >> 8) & 3) === 0) wx = 3;
        }
    }
    if (wx === null) { const b = hash(seed, n, SALT[1]) & 15; wx = b < 8 ? 0 : b < 11 ? 1 : b < 14 ? 2 : 3; }
    let shp = 7, slt = 0;
    const hs = hash(seed, n, SALT[2]);
    const stranger = () => { shp = 5; slt = ((hs >> 4) & 15) % 3; };
    if (wx === 5) { if ((hs & 1) === 0) stranger(); }
    else {
        for (let i = 0; i < 5 && shp === 7; i++) if (n % PERIOD[i] === RESIDUE[i]) { shp = i; slt = SLOT[i]; }
        if (shp === 7 && (hs & 15) === 0) stranger();
    }
    return { wx, shp, slt };
}

/** One night's entry from the state (oil) and the lamp (0-3); variants are the words chosen. */
function night(seed, n, oil, lamp, relief, variants = [0, 0, 0]) {
    const w = world(seed, n);
    const boat = n % BOATN === 0;
    if (boat) oil = Math.min(CAPOIL, oil + BOATOIL);
    let cost = COST[lamp];
    if (lamp < 3 && (w.wx === 5 || w.wx === 2)) cost++;
    cost = Math.min(cost, oil);
    const seen = w.shp !== 7 && lamp < 3 && lamp <= w.slt && !(w.wx === 2 && lamp >= 2);
    const v = relief ? [3, 3, 3] : variants;
    return { n, wx: w.wx, shp: w.shp, slt: w.slt, seen, lamp, boat, oil: oil - cost, relief, v };
}

/** The relief hand's lamp for the oil in hand. */
const reliefLamp = oil => oil < 4 ? 3 : oil < 10 ? 2 : 1;

function text(words, e) {
    const wxs = words.wx[e.wx * 4 + e.v[0]];
    const lm = words.lamp[e.lamp * 4 + e.v[1]];
    const kind = e.shp === 7 ? 2 : e.seen ? 0 : 1;
    const sh = e.shp === 7 ? words.ship[8 + e.v[2]] : expandShip(words, words.ship[kind * 4 + e.v[2]], e.shp, e.slt);
    return `Night ${e.n}${e.relief ? ' (relief hand)' : ''}. ${wxs} ${lm} ${sh}${e.boat ? ' ' + BOAT : ''}`;
}

/** The same break the program makes: at the last space within the width. */
function wrap(s, w) {
    const out = [];
    let i = 0;
    while (i < s.length) {
        let c = 0, ls = -1, e = null;
        for (; c < w; c++) {
            if (i + c >= s.length) { e = c; break; }
            if (s[i + c] === ' ') ls = c;
        }
        if (e === null) {
            const nx = s[i + w];
            e = (nx === undefined || nx === ' ' || ls < 0) ? w : ls;
        }
        out.push(s.slice(i, i + e));
        i += e;
        while (s[i] === ' ') i++;
    }
    return out;
}

const HEAD = 'THE LOG OF THE SISTERS LIGHT\r\nA night is three hours. A lamp shows a ship that passes after it was lit.\r\n\r\n';

/** LEDGER.LOG as the program writes it, for entries (the last 128) and the harbour counts. */
function logfile(words, entries, ans, mis) {
    let s = HEAD;
    for (const e of entries.slice(-128)) s += wrap(text(words, e), 72).join('\r\n') + '\r\n';
    s += '\r\nThe harbour book\r\n';
    words.name.forEach((nm, i) => { s += `${nm[0].toUpperCase()}${nm.slice(1)}: ${ans[i]} answered, ${mis[i]} unseen\r\n`; });
    return s;
}

/** Nights 1..last under the relief hand alone (or with `plan(n, oil)` giving the lamp): entries, counts. */
function run(seed, last, plan) {
    const entries = [], ans = [0, 0, 0, 0, 0, 0], mis = [0, 0, 0, 0, 0, 0];
    let oil = CAPOIL;
    for (let n = 1; n <= last; n++) {
        const relief = !plan;
        const lamp = plan ? plan(n, oil) : reliefLamp(oil);
        const e = night(seed, n, oil, lamp, relief);
        oil = e.oil;
        if (e.shp !== 7) (e.seen ? ans : mis)[e.shp]++;
        entries.push(e);
    }
    return { entries, ans, mis, oil };
}

function words() { return parse(fs.readFileSync(path.join(__dirname, '..', 'words.txt'), 'utf8')); }

module.exports = { world, night, run, text, wrap, logfile, words, hash, WX, reliefLamp };

if (require.main === module) {
    const seed = +(process.argv[2] || 1234), last = +(process.argv[3] || 60);
    const w = words();
    const r = run(seed, last);
    for (const e of r.entries) console.log(String(e.n).padStart(3), WX[e.wx].padEnd(6), e.shp === 7 ? '-' : 'MDPHO?'[e.shp] + (e.seen ? '*' : ' '), 'oil', e.oil);
    console.log(r.ans, r.mis);
    void w;
}
