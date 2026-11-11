; LEDGER: the lighthouse keeper's logbook
;
;   A>LEDGER            asks for the terminal the first time
;   A>LEDGER /100       VT100      /52  VT52      /ADM  ADM-3A
;
; You keep a coastal light for a village and never see the sea, only the logbook. Each night
; (three hours of the machine's clock) you choose how the lamp burns, early, at dark, late or
; not at all, and the words you write. The sea does what it does; what it did is only in the
; log, and the patterns in the log predict the storms and the ships. There is nothing to lose:
; while you are away a relief hand lights the lamp frugally and writes plain entries. Z80, CP/M
; 2.2, 80x24. Assemble with pasmo:
;     pasmo ledger.asm LEDGER.COM          (words.inc: node mkwords.js; build.sh does both)
;
; Copyright (c) 2026 Costin Stroie, MIT licence.

BDOS    equ     0005h
TAIL    equ     0080h
ESC     equ     27
CR      equ     13
LF      equ     10

T_VT100 equ     0
T_VT52  equ     1
T_ADM   equ     2

ESZ     equ     6               ; bytes of an entry
CAP     equ     720             ; nights a long absence is worth at most (a month)

        org     100h

start:  ld      (oldsp),sp
        ld      sp,stack
        call    load
        ld      (loaded),a
        or      a
        jr      nz,s0
        call    blank
s0:     ld      a,(term)
        cp      3
        jr      c,s1
        cp      0ffh
        jr      z,s1
        ld      a,0ffh
        ld      (term),a
s1:     call    parse
        ld      a,(term)
        cp      0ffh
        call    z,askterm
        call    seed
        call    curoff
        call    cls
        call    gettime
        call    zeroac
        ld      hl,0
        ld      (nmiss),hl
        ld      a,(loaded)
        or      a
        jr      nz,s2
        call    initgame
        call    intro
s2:     call    sync
        call    setbeam
        ld      a,(loaded)
        or      a
        jr      z,s3
        ld      hl,(nmiss)
        ld      a,h
        or      l
        call    nz,welcome
s3:     call    savegame
        ld      a,7
        ld      (calw),a
        xor     a
        ld      (layer),a
        ld      (focus),a
        ld      (tick),a
        call    toend
        ld      hl,(mdnow)
        ld      (lastmd),hl
        call    drawall

; ---------------------------------------------------------------- the main loop
main:   call    poll
        call    key
        or      a
        jr      nz,mk
        call    idle
        call    delay
        jp      main
mk:     call    upcase
        push    af
        call    drawhints
        pop     af
        cp      'Q'
        jp      z,quit
        cp      'E'
        ld      b,0
        jp      z,m_lamp
        cp      'D'
        ld      b,1
        jp      z,m_lamp
        cp      'L'
        ld      b,2
        jp      z,m_lamp
        cp      'S'
        ld      b,3
        jp      z,m_lamp
        cp      19              ; left: older pages
        jp      z,m_left
        cp      ','
        jp      z,m_left
        cp      '<'
        jp      z,m_left
        cp      4               ; right: newer pages
        jp      z,m_right
        cp      '.'
        jp      z,m_right
        cp      '>'
        jp      z,m_right
        cp      'W'
        jp      z,m_wrap
        cp      'V'
        jp      z,m_view
        cp      'F'
        jp      z,m_find
        cp      'H'
        jp      z,m_harb
        cp      'R'
        jp      z,m_reset
        cp      'M'
        jp      z,m_bell
        cp      '?'
        jp      z,m_help
        jp      main

m_lamp: ld      a,(phase)
        or      a
        jr      z,ml1
        ld      hl,t_already
        call    msg
        jp      main
ml1:    ld      a,b
        call    tonight
        jp      main

m_left: ld      hl,(vanchor)
        ld      de,4
        or      a
        sbc     hl,de
        push    hl
        inc     hl
        inc     hl
        inc     hl
        bit     7,h
        jr      nz,rej
        ld      a,h
        or      l
        jr      z,rej
        push    hl
        ld      hl,(st_last)
        ld      de,128
        or      a
        sbc     hl,de
        jr      c,ml2
        inc     hl
        jr      ml3
ml2:    ld      hl,1
ml3:    ex      de,hl           ; DE = the oldest night the log still holds
        pop     hl
        or      a
        sbc     hl,de
        jr      c,rej
        pop     hl
        ld      (vanchor),hl
        call    drawbook
        jp      main
rej:    pop     hl
        jp      main

m_right: ld     hl,(vanchor)
        ld      de,4
        add     hl,de
        ex      de,hl
        ld      hl,(nownt)
        dec     hl
        dec     hl
        dec     hl
        or      a
        sbc     hl,de
        bit     7,h
        jr      z,mr1
        add     hl,de           ; past the end: the latest page
        ex      de,hl
mr1:    ld      (vanchor),de
        call    drawbook
        jp      main

m_wrap: ld      a,(calw)
        inc     a
        cp      13
        jr      c,mw1
        ld      a,5
mw1:    ld      (calw),a
        call    drawcal
        jp      main
m_view: ld      a,(layer)
        inc     a
        cp      3
        jr      c,mv1
        xor     a
mv1:    ld      (layer),a
        call    drawcal
        jp      main
m_find: ld      a,(focus)
        inc     a
        cp      11
        jr      c,mf1
        xor     a
mf1:    ld      (focus),a
        call    drawcal
        call    drawbook
        jp      main
m_reset: ld     hl,t_resetq
        call    msg
        call    getkey
        call    upcase
        cp      'Y'
        jr      z,rs1
        call    drawhints
        jp      main
rs1:    ld      a,(term)
        push    af
        ld      a,(st_mute)
        push    af
        call    blank
        pop     af
        ld      (st_mute),a
        pop     af
        ld      (term),a
        ld      hl,0
        ld      (argseed),hl
        call    seed
        call    gettime
        call    initgame
        call    zeroac
        call    sync
        call    setbeam
        call    savegame
        ld      a,7
        ld      (calw),a
        xor     a
        ld      (layer),a
        ld      (focus),a
        call    toend
        call    intro
        jp      m_back
m_harb: call    harbour
        jp      m_back
m_help: call    intro
m_back: call    drawall
        jp      main
m_bell: ld      a,(st_mute)
        xor     1
        ld      (st_mute),a
        ld      hl,t_bellon
        or      a
        jr      z,mb1
        ld      hl,t_belloff
mb1:    call    msg
        call    bell
        jp      main

; ---------------------------------------------------------------- a night with the keeper at hand
; tonight: B = the lamp (0 early, 1 at dark, 2 late, 3 not at all)
tonight: ld     a,b
        ld      (lamp),a
        ld      e,a
        ld      d,0
        ld      hl,costtab
        add     hl,de
        ld      b,(hl)
        call    oilnow
        cp      b
        jr      nc,tn1
        ld      hl,t_noil
        jp      msg
tn1:    xor     a
        ld      (unf),a
        ld      hl,(nownt)
        ld      (cn),hl
        call    prenight
        call    toend
        call    drawbook
        call    nightpass
        call    compose
        call    commit
        ld      a,1
        ld      (phase),a
        call    setbeam
        call    drawbook
        call    drawcal
        call    drawpanel
        call    drawhints
        ld      a,(letterf)
        or      a
        jr      nz,tn_let
        ld      a,(foref)
        or      a
        jp      z,savegame
        ld      hl,t_fore
        call    msg
        jp      savegame
tn_let: dec     a
        push    af
        call    msgbeg
        ld      hl,t_letter1
        call    puts
        pop     af
        ld      hl,nametab
        call    tabget
        call    puts
        ld      hl,t_letter2
        call    puts
        call    msgend
        call    bell
        jp      savegame

; toend: the page at the latest night
toend:  ld      hl,(nownt)
        dec     hl
        dec     hl
        dec     hl
        ld      (vanchor),hl
        ret

; ---------------------------------------------------------------- the nights the relief hand keeps
; calcn: HL = the night it is now (never before the last one written)
calcn:  ld      a,(hasclk)
        or      a
        jr      z,cn_no
        ld      hl,(cn32)
        ld      de,(st_start)
        or      a
        sbc     hl,de
        inc     hl
        ld      de,(st_last)
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        ret     nc
        ex      de,hl
        ret
cn_no:  ld      hl,(st_last)
        inc     hl
        ret

; sync: bring the log up to the clock: write every night that went by (the relief hand does),
; leave the present one open if nothing is written for it
sync:   call    calcn
        ld      (nownt),hl
        ld      hl,0
        ld      (nmiss),hl
        ld      hl,(nownt)
        dec     hl
        ld      de,(st_last)
        or      a
        sbc     hl,de
        jr      c,sy_done
        jr      z,sy_done
        ld      (nmiss),hl
        ld      de,CAP
        or      a
        sbc     hl,de
        jr      c,sy_loop
        jr      z,sy_loop
        ld      de,(st_last)    ; more than CAP nights: the oldest pages are left blank
        add     hl,de
        ld      (st_last),hl
sy_loop: ld     hl,(nownt)
        dec     hl
        ld      de,(st_last)
        or      a
        sbc     hl,de
        jr      c,sy_done
        jr      z,sy_done
        ld      hl,(st_last)
        inc     hl
        call    unatt
        jr      sy_loop
sy_done: ld     hl,(st_last)
        ld      de,(nownt)
        or      a
        sbc     hl,de
        ld      a,0
        jr      nz,sy2
        ld      a,1
sy2:    ld      (phase),a
        ret

; unatt: HL = a night nobody was there for: the relief hand lights the lamp at dark if the oil
; is plentiful, late if it is not, and not at all when it is low
unatt:  ld      (cn),hl
        ld      a,(st_oil)
        ld      b,3
        cp      4
        jr      c,ua2
        ld      b,2
        cp      10
        jr      c,ua2
        ld      b,1
ua2:    ld      a,b
        ld      (lamp),a
        ld      a,1
        ld      (unf),a
        call    prenight
        call    commit
        xor     a
        ld      (unf),a
        ret

zeroac: ld      hl,ac_n
        ld      de,ac_n+1
        ld      bc,9
        ld      (hl),0
        ldir
        xor     a
        ld      (ac_let),a
        ret

; setbeam: the lamp burns (the beam crosses the horizon) while the written night had it lit
setbeam: xor    a
        ld      (beamon),a
        ld      a,(phase)
        or      a
        ret     z
        ld      hl,(st_last)
        call    getent
        ret     nc
        ld      a,(ix+4)
        and     3
        ld      (lastlamp),a
        cp      3
        ret     nc
        ld      a,1
        ld      (beamon),a
        ld      a,(bx)
        or      a
        ret     nz
        ld      a,1
        ld      (bx),a
        ret

; ---------------------------------------------------------------- the clock, live
poll:   ld      a,(hasclk)
        or      a
        ret     z
        call    gettime
        call    calcn
        ld      de,(nownt)
        or      a
        sbc     hl,de
        jr      z,pl1
        jr      c,pl1
        call    newnight
pl1:    ld      hl,(mdnow)
        ld      de,(lastmd)
        or      a
        sbc     hl,de
        ret     z
        ld      hl,(mdnow)
        ld      (lastmd),hl
        call    drawhead
        jp      drawwhen

; newnight: a night began while the book was open
newnight: call  zeroac
        xor     a
        ld      (beamon),a
        call    drawwaves
        call    sync
        call    setbeam
        call    scrollbook
        call    toend
        call    drawhead
        call    drawbook
        call    drawcal
        call    drawpanel
        call    drawhints
        ld      a,(ac_let)
        or      a
        ld      hl,t_letterw
        jr      nz,nn1
        ld      hl,(ac_n)
        ld      a,h
        or      l
        ld      hl,t_newn
        jr      z,nn1
        call    msgbeg
        ld      hl,t_relw
        call    puts
        ld      hl,(ac_n)
        call    pdec
        ld      hl,t_nights
        ld      de,(ac_n)
        ld      a,d
        or      a
        jr      nz,nn2
        ld      a,e
        cp      1
        jr      nz,nn2
        ld      hl,t_night1
nn2:    call    puts
        ld      hl,t_relw2
        call    puts
        call    msgend
        jr      nn3
nn1:    call    msg
nn3:    ld      a,(cbell)
        or      a
        call    z,bell
        xor     a
        ld      (cbell),a
        jp      savegame

; idle: the beam of a lit lamp travels the horizon while nothing else happens
idle:   ld      a,(beamon)
        or      a
        ret     z
        ld      hl,tick
        inc     (hl)
        ld      a,(hl)
        and     1
        ret     nz
        jp      beamstep

; ---------------------------------------------------------------- starting and leaving
; blank: a new state; initgame: a new log
blank:  ld      hl,state
        ld      de,state+1
        ld      bc,STATESZ-1
        ld      (hl),0
        ldir
        ld      a,'L'
        ld      (state),a
        ld      a,'G'
        ld      (state+1),a
        ld      a,1
        ld      (state+2),a
        ld      a,0ffh
        ld      (term),a
        ld      hl,0e5a1h
        ld      (rseed),hl
        ret

initgame: ld    hl,(argseed)
        ld      a,h
        or      l
        jr      nz,ig1
        ld      hl,(rseed)
        ld      de,(mnow)
        add     hl,de
        ld      a,h
        or      l
        jr      nz,ig1
        inc     l
ig1:    ld      (st_wseed),hl
        ld      a,CAPOIL
        ld      (st_oil),a
        ld      hl,(cn32)
        ld      (st_start),hl
        ld      hl,(cn32+2)
        ld      (st_start+2),hl
        ret

quit:   call    savegame
        call    cls
        ld      b,10
        ld      c,3
        call    gotoxy
        ld      hl,t_bye
        call    puts
        ld      b,12
        ld      c,3
        call    gotoxy
        ld      a,(hasclk)
        or      a
        jr      z,q1
        ld      a,(phase)
        or      a
        jr      z,q1
        ld      hl,t_begins
        call    puts
        ld      hl,(nownt)
        inc     hl
        call    pdec
        ld      hl,t_in
        call    puts
        ld      hl,NIGHT
        ld      de,(pnow)
        or      a
        sbc     hl,de
        call    pdur
        ld      a,'.'
        call    putc
q1:     ld      b,15
        ld      c,1
        call    gotoxy
        call    curon
        ld      sp,(oldsp)
        ret

        include "world.asm"
        include "fmt.asm"
        include "clock.asm"
        include "ui.asm"
        include "save.asm"
        include "term.asm"
        include "text.asm"
        include "words.inc"

progend:
; ---------------------------------------------------------------- memory, after the program
state   equ     progend         ; what LEDGER.SAV holds: 896 bytes
term    equ     state+3
st_wseed equ    state+4
st_last equ     state+6
rseed   equ     state+8
st_start equ    state+10        ; 4 bytes
st_oil  equ     state+14
st_mute equ     state+15
st_ans  equ     state+16        ; 6 bytes: lights answered, per ship
st_mis  equ     state+22        ; 6 bytes: ships that passed unseen
st_fore equ     state+34        ; storms met with the lamp lit after swell and wind
ents    equ     state+64        ; the ring of 128 entries of 6 bytes

v0      equ     state+STATESZ
oldsp   equ     v0+0
loaded  equ     v0+2
hasclk  equ     v0+3
clkbuf  equ     v0+4            ; 16
mnow    equ     v0+20           ; 4
cn32    equ     v0+24           ; 4
pnow    equ     v0+28
mdnow   equ     v0+30
m32     equ     v0+32           ; 4
mA      equ     v0+36           ; 4
nownt   equ     v0+40
phase   equ     v0+42           ; 0 the night is open, 1 it is written
vanchor equ     v0+43
calw    equ     v0+45
layer   equ     v0+46
focus   equ     v0+47
lastlamp equ    v0+48
beamon  equ     v0+49
bx      equ     v0+50
tick    equ     v0+51
lastmd  equ     v0+52
cn      equ     v0+54
lamp    equ     v0+56
unf     equ     v0+57
wn      equ     v0+58
woff    equ     v0+60
hw      equ     v0+61
wx      equ     v0+63
shp     equ     v0+64
slt     equ     v0+65
boatf   equ     v0+66
newoil  equ     v0+67
seen    equ     v0+68
pvar    equ     v0+69           ; 3: the words chosen for weather, lamp, ships
pent      equ     v0+72           ; 6: the entry being written
letterf equ     v0+78
ac_n    equ     v0+79           ; what the relief hand did: nights, lit, seen, unseen, storms
ac_lit  equ     v0+81
ac_seen equ     v0+83
ac_miss equ     v0+85
ac_storm equ    v0+87
nmiss   equ     v0+89
argseed equ     v0+91
omode   equ     v0+93
tptr    equ     v0+94
lptr    equ     v0+96
gl_n    equ     v0+98
tmp1    equ     v0+100
bk_r    equ     v0+101
bk_i    equ     v0+102
bk_n    equ     v0+103
bk_row  equ     v0+105
cs_n    equ     v0+106
ds_row  equ     v0+107
dp_n    equ     v0+108
dc_row  equ     v0+110
dc_n    equ     v0+111
dc_c    equ     v0+113
oilv    equ     v0+114
cslot   equ     v0+115
mn_v    equ     v0+116
ts_row  equ     v0+117
hb_i    equ     v0+118
hb_row  equ     v0+119
pw_rows equ     v0+120
pw_w    equ     v0+121
pw_row  equ     v0+122
pw_col  equ     v0+123
pw_first equ    v0+124
pw_ls   equ     v0+125
wf_fcb  equ     v0+126
wf_p    equ     v0+128
wf_n    equ     v0+130
lrecs   equ     v0+131
ac_let  equ     v0+132          ; bit per ship: a letter came while away
wf_err  equ     v0+133
fcb_ren equ     v0+134          ; 36 bytes
foref   equ     v0+170
cbell   equ     v0+171
tbuf    equ     v0+176          ; 256
lbuf    equ     tbuf+256        ; 27000: the diary as text
stackb  equ     lbuf+27000
stack   equ     stackb+256
