; ui.asm: every screen. 80x24:
;   row 1      the title bar: night, clock
;   row 2      the horizon: waves, and the beam of the lamp when it is lit
;   rows 3-20  the book (cols 1-51): four entries of four lines; the calendar (cols 54-79)
;   rows 21-24 the oil, the night, the keys and a message line (never the 80th column)

; ---------------------------------------------------------------- everything
drawall: call   cls
        call    drawhead
        call    drawwaves
        call    drawbook
        call    drawcal
        call    drawpanel
        jp      drawhints

drawhead: ld    b,1
        ld      c,1
        call    gotoxy
        ld      a,A_REV
        call    setattr
        call    eol
        ld      b,1
        ld      c,1
        call    gotoxy
        ld      hl,t_title
        call    puts
        ld      b,1
        ld      c,58
        call    gotoxy
        ld      hl,t_night
        call    puts
        ld      hl,(nownt)
        call    pdec
        ld      a,(hasclk)
        or      a
        ld      b,1
        ld      c,70
        jr      z,dh1
        ld      c,73
        call    gotoxy
        ld      hl,(mdnow)
        call    ptime
        jr      dh2
dh1:    call    gotoxy
        ld      hl,t_noclk
        call    puts
dh2:    xor     a
        jp      setattr

; ptime: HL = minute of the day -> hh:mm
ptime:  ld      e,60
        call    div16
        push    af
        ld      a,l
        call    dec2
        ld      a,':'
        call    putc
        pop     af
        jp      dec2

; pdur: HL minutes -> "2 h 14 min"
pdur:   ld      e,60
        call    div16
        push    af
        ld      a,h
        or      l
        jr      z,pdu1
        call    pdec
        ld      hl,t_h
        call    puts
pdu1:   pop     af
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_min
        jp      puts

; ---------------------------------------------------------------- the horizon
; wavech: C = column (0-78) -> A = the wave there
wavech: ld      a,c
        ld      d,a
        add     a,a
        add     a,a
        add     a,d
        and     15
        cp      2
        ld      a,'~'
        ret     c
        ld      a,' '
        ret

drawwaves: ld   b,2
        ld      c,1
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      c,0
dw1:    push    bc
        call    wavech
        call    putc
        pop     bc
        inc     c
        ld      a,c
        cp      79
        jr      c,dw1
        xor     a
        jp      setattr

; beamstep: the beam of the lamp moves one column along the horizon (bx, 1-based, three wide)
beamstep: ld    a,(bx)
        ld      c,a
        ld      b,2
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      a,(bx)
        dec     a
        ld      c,a
        ld      b,3
bs1:    push    bc
        call    wavech
        call    putc
        pop     bc
        inc     c
        djnz    bs1
        ld      a,(bx)
        inc     a
        cp      77
        jr      c,bs2
        ld      a,1
bs2:    ld      (bx),a
        ld      c,a
        ld      b,2
        call    gotoxy
        ld      a,A_REV+A_BOLD
        call    setattr
        ld      b,3
        call    spaces
        xor     a
        jp      setattr

; ---------------------------------------------------------------- the book
drawbox: call   gfxon
        ld      b,3
        ld      c,1
        call    gotoxy
        ld      a,'l'
        call    gc
        ld      b,49
db1:    ld      a,'q'
        call    gc
        djnz    db1
        ld      a,'k'
        call    gc
        ld      b,20
        ld      c,1
        call    gotoxy
        ld      a,'m'
        call    gc
        ld      b,49
db2:    ld      a,'q'
        call    gc
        djnz    db2
        ld      a,'j'
        call    gc
        ld      a,4
        ld      (bk_r),a
db3:    ld      a,(bk_r)
        ld      b,a
        ld      c,1
        call    gotoxy
        ld      a,'x'
        call    gc
        ld      a,(bk_r)
        ld      b,a
        ld      c,51
        call    gotoxy
        ld      a,'x'
        call    gc
        ld      hl,bk_r
        inc     (hl)
        ld      a,(hl)
        cp      20
        jr      c,db3
        call    gfxoff
        ld      b,3
        ld      c,4
        call    gotoxy
        ld      hl,t_booktitle
        call    puts
        ld      b,20
        ld      c,4
        call    gotoxy
        ld      hl,t_pg
        call    puts
        ld      hl,(vanchor)    ; first and last night on the page
        ld      a,h
        or      l
        jr      z,db4
        bit     7,h
        jr      z,db5
db4:    ld      hl,1
db5:    call    pdec
        ld      a,'-'
        call    putc
        ld      hl,(vanchor)
        inc     hl
        inc     hl
        inc     hl
        ld      de,(nownt)
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        jr      c,db6
        ld      hl,(nownt)
db6:    call    pdec
        ld      a,' '
        jp      putc

drawbook: call  drawbox
        xor     a
        ld      (bk_i),a
        ld      hl,(vanchor)
        ld      (bk_n),hl
bk1:    ld      a,(bk_i)
        add     a,a
        add     a,a
        add     a,4
        ld      (bk_row),a
        ld      hl,(bk_n)
        ld      a,h
        or      l
        jr      z,bk_blank
        bit     7,h
        jr      nz,bk_blank
        call    getent
        jr      nc,bk_nox
        ld      a,(bk_row)
        ld      b,a
        call    drawslot
        jr      bk_next
bk_nox: ld      hl,(bk_n)
        ld      de,(nownt)
        or      a
        sbc     hl,de
        jr      nz,bk_blank
        ld      a,(phase)
        or      a
        jr      nz,bk_blank
        ld      a,(bk_row)
        ld      b,a
        ld      hl,(bk_n)
        call    drawpend
        jr      bk_next
bk_blank: ld    a,(bk_row)
        ld      b,a
        call    clrslot
bk_next: ld     hl,(bk_n)
        inc     hl
        ld      (bk_n),hl
        ld      hl,bk_i
        inc     (hl)
        ld      a,(hl)
        cp      4
        jr      c,bk1
        ret

; clrslot: B = top row: four rows of the book blank
clrslot: ld     a,4
        ld      (cs_n),a
cs1:    push    bc
        ld      c,2
        call    gotoxy
        ld      b,49
        call    spaces
        pop     bc
        inc     b
        ld      hl,cs_n
        dec     (hl)
        jr      nz,cs1
        ret

; drawslot: IX = an entry, B = top row
drawslot: ld    a,b
        ld      (ds_row),a
        call    fmtent
        ld      a,(ds_row)
        ld      b,a
        call    clrslot
        ld      a,(ds_row)
        ld      b,a
        ld      c,3
        ld      d,47
        ld      e,4
        ld      hl,tbuf
        call    pwrap
        ld      a,(ds_row)
        ld      b,a
        ld      c,3
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_night
        call    puts
        ld      l,(ix+0)
        ld      h,(ix+1)
        call    pdec
        xor     a
        call    setattr
        call    matchf
        ret     nc
        ld      a,(ds_row)
        ld      b,a
        ld      c,2
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      a,'*'
        call    putc
        xor     a
        jp      setattr

; drawpend: B = top row, HL = the night that is still blank
drawpend: ld    (dp_n),hl
        ld      a,b
        ld      (ds_row),a
        call    clrslot
        ld      a,(ds_row)
        ld      b,a
        ld      c,3
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_night
        call    puts
        ld      hl,(dp_n)
        call    pdec
        xor     a
        call    setattr
        ld      a,(ds_row)
        ld      b,a
        ld      c,3
        ld      d,47
        ld      e,3
        inc     b
        ld      hl,t_blank
        jp      pwrap

; matchf: IX = entry; carry if it is what the focus (F) is on
matchf: ld      a,(focus)
        or      a
        ret     z
        cp      5
        jr      nc,mf2
        dec     a
        ld      e,a
        ld      d,0
        ld      hl,fwtab
        add     hl,de
        ld      b,(hl)
        ld      a,(ix+2)
        and     7
        cp      b
        jr      z,mf_y
        or      a
        ret
mf2:    sub     5
        ld      b,a
        ld      a,(ix+3)
        and     7
        cp      b
        jr      z,mf_y
        or      a
        ret
mf_y:   scf
        ret
fwtab:  db      5,4,3,2

; ---------------------------------------------------------------- the calendar
; the nights in rows of `calw`, the same column for the same place in the cycle: a ship that
; comes every seventh night is a stripe at width 7
drawcal: ld     b,3
        ld      c,54
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_cal
        call    puts
        ld      a,(calw)
        ld      l,a
        ld      h,0
        call    pdec
        ld      a,' '
        call    putc
        xor     a
        call    setattr
        ld      a,4
        ld      (dc_row),a
dc0:    ld      a,(dc_row)
        ld      b,a
        ld      c,54
        call    gotoxy
        call    eol
        ld      hl,dc_row
        inc     (hl)
        ld      a,(hl)
        cp      20
        jr      c,dc0
        ld      hl,(nownt)
        dec     hl
        ld      a,(calw)
        ld      e,a
        call    div16
        ld      de,15
        or      a
        sbc     hl,de
        jr      nc,dc1
        ld      hl,0
dc1:    ld      b,h
        ld      c,l
        ld      de,1
dc2:    ld      a,b
        or      c
        jr      z,dc3
        ld      a,(calw)
        add     a,e
        ld      e,a
        jr      nc,dc2b
        inc     d
dc2b:   dec     bc
        jr      dc2
dc3:    ld      (dc_n),de
        ld      a,4
        ld      (dc_row),a
dc4:    ld      hl,(nownt)
        ld      de,(dc_n)
        or      a
        sbc     hl,de
        jr      c,dc9
        ld      a,(dc_row)
        ld      b,a
        ld      c,54
        call    gotoxy
        ld      a,(calw)
        ld      (dc_c),a
dc5:    ld      hl,(dc_n)
        call    glyph
        ld      hl,(dc_n)
        inc     hl
        ld      (dc_n),hl
        ld      hl,dc_c
        dec     (hl)
        jr      nz,dc5
        ld      hl,dc_row
        inc     (hl)
        ld      a,(hl)
        cp      20
        jr      c,dc4
dc9:    ld      b,20
        ld      c,54
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_layer
        call    puts
        ld      a,(layer)
        ld      hl,layertab
        call    tabget
        call    puts
        ld      hl,t_focus
        call    puts
        ld      a,(focus)
        ld      hl,focustab
        call    tabget
        call    puts
        xor     a
        call    setattr
        jp      eol

; glyph: HL = night; two columns of the calendar
glyph:  ld      de,(nownt)
        push    hl
        or      a
        sbc     hl,de
        pop     hl
        jr      z,gl_cur
        jr      c,gl_past
gl_blank: ld    a,' '
        call    putc
        ld      a,' '
        jp      putc
gl_cur: ld      a,(phase)
        or      a
        jr      nz,gl_past
        ld      a,A_BLINK
        call    setattr
        ld      a,'_'
        call    putc
        xor     a
        call    setattr
        ld      a,' '
        jp      putc
gl_past: call   getent
        jr      nc,gl_blank
        ld      a,(layer)
        or      a
        jr      nz,gl1
        ld      a,(ix+2)        ; weather
        and     7
        ld      e,a
        ld      d,0
        ld      hl,wxch
        add     hl,de
        ld      b,(hl)
        ld      c,0
        cp      5
        jr      nz,gl_f
        ld      c,A_BOLD
        jr      gl_f
gl1:    cp      1
        jr      nz,gl2
        ld      a,(ix+3)        ; ships
        and     7
        ld      e,a
        ld      d,0
        ld      hl,shch
        add     hl,de
        ld      b,(hl)
        ld      c,0
        cp      7
        jr      nz,gl1b
        ld      c,A_DIM
        jr      gl_f
gl1b:   bit     5,(ix+3)
        jr      z,gl_f
        ld      c,A_BOLD
        jr      gl_f
gl2:    ld      a,(ix+4)        ; lamp
        and     3
        ld      e,a
        ld      d,0
        ld      hl,lpch
        add     hl,de
        ld      b,(hl)
        ld      c,0
        cp      3
        jr      nz,gl_f
        ld      c,A_DIM
gl_f:   call    matchf
        jr      nc,gl_g
        ld      c,A_REV
gl_g:   ld      a,c
        call    attrset
        ld      a,b
        call    putc
        xor     a
        call    attrset
        ld      a,' '
        jp      putc
wxch:   db      '.','-','=','>','~','#'
shch:   db      'M','D','P','H','O','?','.','.'
lpch:   db      'E','D','L','S'

; ---------------------------------------------------------------- the panel
drawpanel: ld   b,21
dpn0:   push    bc
        ld      c,1
        call    gotoxy
        call    eol
        pop     bc
        inc     b
        ld      a,b
        cp      24
        jr      c,dpn0
        call    oilnow
        ld      (oilv),a
        ld      b,21
        ld      c,2
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_oil
        call    puts
        xor     a
        call    setattr
        ld      a,(oilv)
        or      a
        jr      z,op1
        ld      b,a
        call    gfxon
op0:    ld      a,'a'
        call    gc
        djnz    op0
        call    gfxoff
op1:    ld      a,(oilv)
        ld      b,a
        ld      a,CAPOIL
        sub     b
        jr      z,op3
        ld      b,a
        ld      a,A_DIM
        call    attrset
op2:    ld      a,'.'
        call    putc
        djnz    op2
        xor     a
        call    setattr
op3:    ld      a,' '
        call    putc
        ld      a,(oilv)
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_of
        call    puts
        ld      hl,(nownt)
        ld      e,BOATN
        call    div16
        ld      b,a
        ld      a,(phase)
        or      a
        jr      nz,ob1
        ld      a,b
        or      a
        jr      nz,ob1
        ld      hl,t_tonight
        call    puts
        jr      ob3
ob1:    ld      a,BOATN
        sub     b
        ld      (tmp1),a
        ld      hl,t_boatin
        call    puts
        ld      a,(tmp1)
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_nights
        ld      a,(tmp1)
        cp      1
        jr      nz,ob2
        ld      hl,t_night1
ob2:    call    puts
ob3:    ld      a,(phase)
        or      a
        jr      nz,dpn_c
        ; the night is open: how will the lamp burn?
        ld      b,22
        ld      c,2
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_open1
        call    puts
        ld      hl,(nownt)
        call    pdec
        ld      hl,t_open2
        call    puts
        xor     a
        call    setattr
        ld      b,23
        ld      c,2
        call    gotoxy
        ld      hl,loptab
        ld      b,0
lo1:    push    bc
        push    hl
        ld      e,b
        ld      d,0
        ld      hl,costtab
        add     hl,de
        ld      a,(oilv)
        cp      (hl)
        ld      a,0
        jr      nc,lo2
        ld      a,A_DIM
lo2:    call    attrset
        pop     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    hl
        ex      de,hl
        call    puts
        xor     a
        call    attrset
        pop     hl
        pop     bc
        inc     b
        ld      a,b
        cp      4
        jr      c,lo1
        ret
dpn_c:  ld      b,22
        ld      c,2
        call    gotoxy
        ld      hl,t_written
        call    puts
        ld      hl,(nownt)
        call    pdec
        ld      hl,t_written2
        call    puts
        call    drawwhen
        ld      b,23
        ld      c,2
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_lastlamp
        call    puts
        ld      a,(lastlamp)
        ld      hl,lampwtab
        call    tabget
        call    puts
        ld      hl,t_nothing
        call    puts
        xor     a
        jp      setattr

; drawwhen: how long to the next night, on row 22
drawwhen: ld    a,(phase)
        or      a
        ret     z
        ld      b,22
        ld      c,30
        call    gotoxy
        call    eol
        ld      b,22
        ld      c,30
        call    gotoxy
        ld      a,(hasclk)
        or      a
        jr      nz,dwn1
        ld      hl,t_noclk2
        jp      puts
dwn1:   ld      hl,t_begins
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
        jp      putc

drawhints: ld   b,24
        ld      c,1
        call    gotoxy
        call    eol
        ld      b,24
        ld      c,2
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_hints
        call    puts
        xor     a
        jp      setattr

; msg: HL = a line for row 24; msgbeg and msgend let a caller add numbers
msg:    push    hl
        call    msgbeg
        pop     hl
        call    puts
msgend: xor     a
        jp      setattr
msgbeg: ld      b,24
        ld      c,1
        call    gotoxy
        call    eol
        ld      b,24
        ld      c,2
        call    gotoxy
        ld      a,A_BOLD
        jp      setattr

bell:   ld      a,(st_mute)
        or      a
        ret     nz
        ld      a,7
        jp      putc

; scrollbook: the page slides up four lines (a VT100 scroll region) to make room for the night
scrollbook: ld  a,(term)
        or      a
        ret     nz
        ld      b,4
        ld      c,19
        call    region
        ld      b,19
        ld      c,2
        call    gotoxy
        ld      b,4
sb1:    push    bc
        ld      a,LF
        call    putc
        call    delay
        pop     bc
        djnz    sb1
        jp      region0

; nightpass: the night goes by. A lit lamp throws its beam along the horizon.
nightpass: ld   hl,t_passes
        call    msg
        ld      a,(lamp)
        cp      3
        jr      nc,np_d
        ld      a,1
        ld      (bx),a
        ld      b,72
np1:    push    bc
        call    beamstep
        call    delay1
        call    delay1
        pop     bc
        djnz    np1
        jp      drawwaves
np_d:   ld      b,15
np2:    push    bc
        call    delay
        pop     bc
        djnz    np2
        ret

; ---------------------------------------------------------------- writing the entry
; compose: three choices (the weather, the lamp, the ships), each from three phrasings of what
; happened. The entry builds on the page as you choose.
compose: xor    a
        ld      (cslot),a
        ld      (cbell),a
cp1:    call    menu
        ld      e,a
        ld      a,(cslot)
        ld      c,a
        ld      b,0
        ld      hl,pvar
        add     hl,bc
        ld      (hl),e
        call    mkpend
        ld      ix,pent
        ld      b,16
        call    drawslot
        ld      hl,cslot
        inc     (hl)
        ld      a,(hl)
        cp      3
        jr      c,cp1
        ret

; menu: the three phrasings for slot cslot on rows 22-24; A = the one chosen (0-2)
menu:   ld      b,21
mn0:    push    bc
        ld      c,1
        call    gotoxy
        call    eol
        pop     bc
        inc     b
        ld      a,b
        cp      25
        jr      c,mn0
        ld      b,21
        ld      c,2
        call    gotoxy
        ld      a,A_REV
        call    setattr
        ld      hl,t_write1
        call    puts
        ld      hl,(nownt)
        call    pdec
        ld      hl,t_write2
        call    puts
        ld      a,(cslot)
        ld      hl,slotwtab
        call    tabget
        call    puts
        ld      hl,t_write3
        call    puts
        xor     a
        call    setattr
        xor     a
        ld      (mn_v),a
mn1:    ld      a,(cslot)       ; try variant mn_v in the slot
        ld      c,a
        ld      b,0
        ld      hl,pvar
        add     hl,bc
        ld      a,(mn_v)
        ld      (hl),a
        call    mkpend
        ld      ix,pent
        call    beginmem
        ld      a,(cslot)
        or      a
        jr      nz,mn2
        call    fm_wx
        jr      mn4
mn2:    cp      1
        jr      nz,mn3
        call    fm_lamp
        jr      mn4
mn3:    call    fm_ship
mn4:    call    endmem
        ld      a,(mn_v)
        add     a,22
        ld      b,a
        ld      c,2
        call    gotoxy
        ld      a,(mn_v)
        add     a,'1'
        call    putc
        ld      a,')'
        call    putc
        ld      a,' '
        call    putc
        ld      hl,tbuf
        call    puts
        ld      hl,mn_v
        inc     (hl)
        ld      a,(hl)
        cp      3
        jr      c,mn1
mn5:    call    key
        or      a
        jr      nz,mn7
        call    cpoll
        call    delay
        jr      mn5
mn7:    cp      CR
        ld      b,0
        jr      z,mn6
        sub     '1'
        jr      c,mn5
        cp      3
        jr      nc,mn5
        ld      b,a
mn6:    ld      a,b
        ret

; cpoll: while the words are being chosen the clock goes on: the header moves, and the bell
; rings once if the next night begins (the entry in hand is finished first, then the relief hand
; catches up on whatever was missed)
cpoll:  ld      a,(hasclk)
        or      a
        ret     z
        call    gettime
        ld      hl,(mdnow)
        ld      de,(lastmd)
        or      a
        sbc     hl,de
        jr      z,cp2
        ld      hl,(mdnow)
        ld      (lastmd),hl
        call    drawhead
cp2:    ld      a,(cbell)
        or      a
        ret     nz
        call    calcn
        ld      de,(nownt)
        or      a
        sbc     hl,de
        ret     z
        ret     c
        ld      a,1
        ld      (cbell),a
        jp      bell

; ---------------------------------------------------------------- the other screens
; screens of text: HL = a table of lines, one per row from row B, a zero ends it
textscr: ld     a,b
        ld      (ts_row),a
ts1:    ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,d
        or      e
        ret     z
        push    hl
        ex      de,hl
        ld      a,(ts_row)
        ld      b,a
        ld      c,3
        call    gotoxy
        call    puts
        pop     hl
        ld      a,(ts_row)
        inc     a
        ld      (ts_row),a
        jr      ts1

intro:  call    cls
        ld      hl,introtab
        ld      b,2
        call    textscr
        ld      b,3
        ld      c,35            ; 'L E D G E R' centred
        call    gotoxy
        ld      a,A_BOLD
        call    setattr
        ld      hl,t_big
        call    puts
        xor     a
        call    setattr
        ld      b,23
        ld      c,35            ; 'press a key' centred
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_press
        call    puts
        xor     a
        call    setattr
        jp      getkey

; welcome: what the relief hand did while the log was shut
welcome: call   cls
        ld      b,1
        ld      c,1
        call    gotoxy
        ld      a,A_REV
        call    setattr
        call    eol
        ld      b,1
        ld      c,1
        call    gotoxy
        ld      hl,t_title
        call    puts
        xor     a
        call    setattr
        ld      b,4
        ld      c,3
        call    gotoxy
        ld      hl,t_away
        call    puts
        ld      hl,(nmiss)
        call    pdec
        ld      hl,t_nights
        ld      de,(nmiss)
        ld      a,d
        or      a
        jr      nz,wl1
        ld      a,e
        cp      1
        jr      nz,wl1
        ld      hl,t_night1
wl1:    call    puts
        ld      a,'.'
        call    putc
        ld      b,6
        ld      c,3
        call    gotoxy
        ld      hl,t_relief1
        call    puts
        ld      b,8
        ld      c,5
        call    gotoxy
        ld      hl,(ac_lit)
        call    pdec
        ld      hl,t_wl1
        call    puts
        ld      b,9
        ld      c,5
        call    gotoxy
        ld      hl,(ac_seen)
        call    pdec
        ld      hl,t_wl2
        call    puts
        ld      b,10
        ld      c,5
        call    gotoxy
        ld      hl,(ac_miss)
        call    pdec
        ld      hl,t_wl3
        call    puts
        ld      b,11
        ld      c,5
        call    gotoxy
        ld      hl,(ac_storm)
        call    pdec
        ld      hl,t_wl4
        call    puts
        ld      a,(ac_let)
        or      a
        jr      z,wl_n
        ld      b,13
        ld      c,3
        call    gotoxy
        ld      hl,t_wlet
        call    puts
        xor     a
        ld      (hb_i),a
        ld      (tmp1),a
wl_l:   ld      a,(hb_i)
        ld      b,a
        ld      a,(ac_let)
        inc     b
wl_s:   rrca
        djnz    wl_s
        jr      nc,wl_x
        ld      a,(tmp1)
        or      a
        jr      z,wl_f
        ld      hl,t_comma
        call    puts
wl_f:   ld      a,1
        ld      (tmp1),a
        ld      a,(hb_i)
        ld      hl,nametab
        call    tabget
        call    puts
wl_x:   ld      hl,hb_i
        inc     (hl)
        ld      a,(hl)
        cp      6
        jr      c,wl_l
        ld      a,'.'
        call    putc
wl_n:   ld      b,16
        ld      c,3
        call    gotoxy
        ld      hl,t_nothing2
        call    puts
        ld      b,23
        ld      c,3
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_press
        call    puts
        xor     a
        call    setattr
        jp      getkey

; harbour: the harbour book, the ships, how often their light was answered, and their letters
harbour: call   cls
        ld      b,1
        ld      c,1
        call    gotoxy
        ld      a,A_REV
        call    setattr
        call    eol
        ld      b,1
        ld      c,1
        call    gotoxy
        ld      hl,t_harbour
        call    puts
        xor     a
        call    setattr
        xor     a
        ld      (hb_i),a
hb1:    ld      a,(hb_i)
        ld      c,a
        add     a,a
        add     a,c
        add     a,3
        ld      (hb_row),a
        ld      b,a
        ld      c,2
        call    gotoxy
        ld      a,(hb_i)
        ld      e,a
        ld      d,0
        ld      hl,shch
        add     hl,de
        ld      a,A_BOLD
        call    setattr
        ld      a,(hl)
        call    putc
        xor     a
        call    setattr
        ld      a,' '
        call    putc
        ld      a,(hb_i)
        ld      hl,nametab
        call    tabget
        ld      a,(hl)
        call    upcase
        call    putc
        inc     hl
        call    puts
        ld      hl,t_dash
        call    puts
        ld      a,(hb_i)
        ld      hl,kindtab
        call    tabget
        call    puts
        ld      a,(hb_row)
        ld      b,a
        ld      c,56
        call    gotoxy
        ld      a,(hb_i)
        ld      e,a
        ld      d,0
        ld      hl,st_ans
        add     hl,de
        ld      a,(hl)
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_ans
        call    puts
        ld      a,(hb_i)
        ld      e,a
        ld      d,0
        ld      hl,st_mis
        add     hl,de
        ld      a,(hl)
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_unseen
        call    puts
        ld      a,(hb_i)        ; the letter, once her light has been answered enough
        ld      e,a
        ld      d,0
        ld      hl,st_ans
        add     hl,de
        ld      c,(hl)
        ld      b,3
        ld      a,(hb_i)
        cp      5
        jr      nz,hb2
        ld      b,2
hb2:    ld      a,c
        cp      b
        jr      c,hb3
        ld      a,(hb_i)
        ld      hl,lettab
        call    tabget
        ld      a,(hb_row)
        inc     a
        ld      b,a
        ld      c,4
        ld      d,72
        ld      e,2
        call    pwrap
        jr      hb4
hb3:    ld      hl,t_noletter
        ld      a,c
        or      a
        jr      nz,hb3b
        ld      a,(hb_i)        ; never answered, and passed unseen three times: a nudge
        ld      e,a
        ld      d,0
        ld      hl,st_mis
        add     hl,de
        ld      a,(hl)
        ld      hl,t_noletter
        cp      3
        jr      c,hb3b
        ld      hl,t_hint0
hb3b:   push    hl
        ld      a,(hb_row)
        inc     a
        ld      b,a
        ld      c,4
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        pop     hl
        call    puts
        xor     a
        call    setattr
hb4:    ld      hl,hb_i
        inc     (hl)
        ld      a,(hl)
        cp      6
        jp      c,hb1
        ld      b,21
        ld      c,3
        call    gotoxy
        ld      hl,t_village
        call    puts
        ld      hl,0
        ld      de,st_ans
        ld      b,6
hb5:    ld      a,(de)
        add     a,l
        ld      l,a
        jr      nc,hb6
        inc     h
hb6:    inc     de
        djnz    hb5
        call    pdec
        ld      hl,t_village2
        call    puts
        ld      a,(st_fore)
        ld      l,a
        ld      h,0
        call    pdec
        ld      a,'.'
        call    putc
        ld      b,23
        ld      c,3
        call    gotoxy
        ld      a,A_DIM
        call    setattr
        ld      hl,t_press
        call    puts
        xor     a
        call    setattr
        jp      getkey
