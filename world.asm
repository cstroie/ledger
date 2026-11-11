; world.asm: what the sea does, as a pure function of the log's seed and the night number, so
; a night can be worked out whenever it is wanted and always comes out the same. Then the
; lamp, the oil and the entry that records it.
;
; Weather. The nights fall into windows of six. A window has a front when hash(window) is even:
; four nights, swell, wind, storm, haze, starting on the first, second or third night of the
; window. One front in four veers away and the storm is only wind. Any other night is fair, hazy,
; foggy or windy by chance; swell is only ever the first night of a front.
; Ships. Five keep a timetable (a period in nights and which night of it), one passes by chance,
; and a storm keeps the timetable ships in port. A ship passes in the evening, at midnight or
; in the small hours; the lamp, lit early, at dark or late, shows it only a ship that passes
; no earlier than the lamp was lit, and fog hides a lamp lit late.

SALT1   equ     0a5c3h
SALT2   equ     03e91h
SALT3   equ     07b17h

BOATN   equ     12
BOATOIL equ     24
CAPOIL  equ     30

; hash: HL = value, DE = salt -> HL (three rounds of the generator over value xor seed + salt)
hash:   push    de
        ld      de,(st_wseed)
        ld      a,h
        xor     d
        ld      h,a
        ld      a,l
        xor     e
        ld      l,a
        pop     de
        add     hl,de
        ld      a,h
        or      l
        jr      nz,hs1
        inc     l
hs1:    call    hmix
        call    hmix
hmix:   ld      a,h
        rra
        ld      a,l
        rra
        xor     h
        ld      h,a
        ld      a,l
        rra
        ld      a,h
        rra
        xor     l
        ld      l,a
        xor     h
        ld      h,a
        ret

; world: HL = night -> wx (0 fair 1 haze 2 fog 3 wind 4 swell 5 storm), shp (0-4 timetable, 5
; a stranger, 7 none) and slt (0 evening, 1 midnight, 2 small hours)
world:  ld      (wn),hl
        ld      e,6
        call    div16
        ld      (woff),a
        ld      de,SALT1
        call    hash
        ld      (hw),hl
        ld      a,l
        and     1
        jr      nz,wbase
        ld      a,l             ; where in the window the front starts
        rrca
        rrca
        rrca
        rrca
        and     3
        cp      3
        jr      nz,wfa
        ld      a,2
wfa:    ld      b,a
        ld      a,(woff)
        sub     b
        jr      c,wbase
        cp      4
        jr      nc,wbase
        ld      e,a
        ld      d,0
        ld      hl,fronttab
        add     hl,de
        ld      c,(hl)
        cp      2               ; the third night is the storm, unless it veers
        jr      nz,wfb
        ld      a,(hw+1)
        and     3
        jr      nz,wfb
        ld      c,3
wfb:    ld      a,c
        jr      wset
wbase:  ld      hl,(wn)
        ld      de,SALT2
        call    hash
        ld      a,l
        and     15
        ld      b,0
        cp      8
        jr      c,wset0
        ld      b,1
        cp      11
        jr      c,wset0
        ld      b,2
        cp      14
        jr      c,wset0
        ld      b,3
wset0:  ld      a,b
wset:   ld      (wx),a
        ; ships
        ld      a,7
        ld      (shp),a
        ld      a,(wx)
        cp      5
        jr      z,wstorm
        ld      b,0
wsh1:   ld      hl,(wn)
        push    bc
        ld      c,b
        ld      b,0
        ld      hl,shipper
        add     hl,bc
        ld      e,(hl)
        pop     bc
        ld      hl,(wn)
        push    bc
        call    div16
        pop     bc
        push    bc
        ld      c,b
        ld      b,0
        ld      hl,shipres
        add     hl,bc
        cp      (hl)
        jr      nz,wsh2
        ld      hl,shipslt
        add     hl,bc
        ld      a,(hl)
        ld      (slt),a
        ld      a,c
        ld      (shp),a
        pop     bc
        ret
wsh2:   pop     bc
        inc     b
        ld      a,b
        cp      5
        jr      c,wsh1
        ld      hl,(wn)         ; nothing on the timetable: a stranger now and then
        ld      de,SALT3
        call    hash
        ld      a,l
        and     15
        ret     nz
        jr      wstr
wstorm: ld      hl,(wn)         ; in a storm only a stranger is out, half the time
        ld      de,SALT3
        call    hash
        ld      a,l
        and     1
        ret     nz
wstr:   ld      a,5
        ld      (shp),a
        ld      a,l
        rrca
        rrca
        rrca
        rrca
        and     15
ws3:    cp      3
        jr      c,ws4
        sub     3
        jr      ws3
ws4:    ld      (slt),a
        ret

fronttab: db    4,3,5,1
shipper: db     7,5,9,11,13
shipres: db     3,1,4,6,9
shipslt: db     1,0,2,1,2
costtab: db     3,2,1,0

; oilnow: A = the oil the open night starts with (the boat has come if it is a boat night)
oilnow: ld      a,(st_oil)
        ld      b,a
        ld      a,(phase)
        or      a
        jr      nz,on1
        ld      hl,(nownt)
        ld      e,BOATN
        push    bc
        call    div16
        pop     bc
        or      a
        jr      nz,on1
        ld      a,b
        add     a,BOATOIL
        cp      CAPOIL+1
        jr      c,on2
        ld      a,CAPOIL
on2:    ld      b,a
on1:    ld      a,b
        ret

; prenight: the night (cn) with the lamp (lamp) and whether the keeper is away (unf): works out
; the weather, the ship, the oil and whether she was seen. Changes nothing that is kept.
prenight: ld    hl,(cn)
        call    world
        xor     a
        ld      (boatf),a
        ld      (pvar),a
        ld      (pvar+1),a
        ld      (pvar+2),a
        ld      hl,(cn)
        ld      e,BOATN
        call    div16
        or      a
        jr      nz,pn1
        ld      a,1
        ld      (boatf),a
pn1:    ld      a,(st_oil)
        ld      b,a
        ld      a,(boatf)
        or      a
        jr      z,pn2
        ld      a,b
        add     a,BOATOIL
        cp      CAPOIL+1
        jr      c,pn1b
        ld      a,CAPOIL
pn1b:   ld      b,a
pn2:    ld      a,(lamp)
        ld      e,a
        ld      d,0
        ld      hl,costtab
        add     hl,de
        ld      c,(hl)
        ld      a,(lamp)
        cp      3
        jr      nc,pn4
        ld      a,(wx)
        cp      5
        jr      z,pn3
        cp      2
        jr      nz,pn4
pn3:    inc     c               ; storm and fog burn more
pn4:    ld      a,b
        cp      c
        jr      nc,pn5
        ld      c,b
pn5:    ld      a,b
        sub     c
        ld      (newoil),a
        xor     a
        ld      (seen),a
        ld      a,(shp)
        cp      7
        ret     z
        ld      a,(lamp)
        cp      3
        ret     nc
        ld      b,a
        ld      a,(slt)
        cp      b
        ret     c               ; she passed before the lamp was lit
        ld      a,(wx)
        cp      2
        jr      nz,pn7
        ld      a,b
        cp      2
        ret     nc              ; fog hides a lamp lit late
pn7:    ld      a,1
        ld      (seen),a
        ret

; mkpend: the entry, as bytes, in pent, from the night's facts and the words chosen (pvar: weather,
; lamp, ship variants 0-3)
mkpend: ld      ix,pent
        ld      hl,(cn)
        ld      (ix+0),l
        ld      (ix+1),h
        ld      a,(pvar)
        add     a,a
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(wx)
        or      b
        ld      b,a
        ld      a,(unf)
        rrca
        rrca
        or      b
        ld      (ix+2),a
        ld      a,(pvar+2)
        rrca
        rrca
        ld      b,a
        ld      a,(seen)
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        or      b
        ld      b,a
        ld      a,(slt)
        add     a,a
        add     a,a
        add     a,a
        or      b
        ld      b,a
        ld      a,(shp)
        or      b
        ld      (ix+3),a
        ld      a,(pvar+1)
        add     a,a
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(boatf)
        add     a,a
        add     a,a
        or      b
        ld      b,a
        ld      a,(lamp)
        or      b
        ld      (ix+4),a
        ld      a,(newoil)
        ld      (ix+5),a
        ret

; commit: keep the night: the entry, the oil, the last night, the harbour book; and the counts
; of what the relief hand did, if the keeper was away
commit: ld      a,(unf)
        or      a
        jr      z,cm0
        ld      a,3
        ld      (pvar),a
        ld      (pvar+1),a
        ld      (pvar+2),a
cm0:    call    mkpend
        ld      hl,(cn)
        call    entaddr
        ld      hl,pent
        push    ix
        pop     de
        ld      bc,ESZ
        ldir
        ld      a,(newoil)
        ld      (st_oil),a
        ld      hl,(cn)
        ld      (st_last),hl
        ld      a,(lamp)
        ld      (lastlamp),a
        xor     a
        ld      (letterf),a
        ld      a,(shp)
        cp      7
        jr      z,cm3
        ld      e,a
        ld      d,0
        ld      a,(seen)
        or      a
        ld      hl,st_mis
        jr      z,cm1
        ld      hl,st_ans
cm1:    add     hl,de
        inc     (hl)
        jr      nz,cm1b
        dec     (hl)            ; stays at 255
cm1b:   ld      a,(seen)
        or      a
        jr      z,cm3
        ld      a,(hl)          ; the letter comes with the third answer (the second for a stranger)
        ld      b,3
        ld      a,e
        cp      5
        jr      nz,cm2
        ld      b,2
cm2:    ld      a,(hl)
        cp      b
        jr      nz,cm3
        ld      a,e
        inc     a
        ld      (letterf),a
cm3:    ld      a,(unf)
        or      a
        ret     z
        ld      hl,ac_n
        call    incw
        ld      a,(lamp)
        cp      3
        jr      nc,cm4
        ld      hl,ac_lit
        call    incw
cm4:    ld      a,(shp)
        cp      7
        jr      z,cm6
        ld      hl,ac_seen
        ld      a,(seen)
        or      a
        jr      nz,cm5
        ld      hl,ac_miss
cm5:    call    incw
cm6:    ld      a,(wx)
        cp      5
        ret     nz
        ld      hl,ac_storm
incw:   inc     (hl)
        ret     nz
        inc     hl
        inc     (hl)
        ret

; entaddr: HL = night -> IX = its place in the ring of 128 entries
entaddr: dec    hl
        ld      a,l
        and     127
        ld      l,a
        ld      h,0
        ld      d,h
        ld      e,l
        add     hl,hl
        add     hl,de
        add     hl,hl
        ld      de,ents
        add     hl,de
        push    hl
        pop     ix
        ret

; getent: HL = night -> IX = its entry; carry if the log still has it
getent: ld      a,h
        or      l
        jr      z,ge_no
        push    hl
        call    entaddr
        pop     hl
        ld      a,(ix+0)
        cp      l
        jr      nz,ge_no
        ld      a,(ix+1)
        cp      h
        jr      nz,ge_no
        scf
        ret
ge_no:  or      a
        ret
