; term.asm: the terminal driver (VT100, VT52, ADM-3A), the console, decimal output, the random
; generator and the choice of terminal. From Signal Seeker, Cold Storage and Tidepool (MIT), with
; two additions: putc can write into memory instead of the console (omode, tptr), which is how
; LEDGER builds a line of the log once and shows it on the screen or in LEDGER.LOG; and the VT100
; scroll region (region, region0).

; ---------------------------------------------------------------- terminal
; gotoxy: B = row (1-based), C = column (1-based)
gotoxy: push    bc
        push    hl
        ld      a,(term)
        cp      T_VT100
        jr      nz,gx52
        ld      a,ESC
        call    putc
        ld      a,'['
        call    putc
        ld      a,b
        call    decn
        ld      a,';'
        call    putc
        ld      a,c
        call    decn
        ld      a,'H'
        call    putc
        jr      gxend
gx52:   ld      a,ESC
        call    putc
        ld      a,(term)
        cp      T_VT52
        ld      a,'Y'
        jr      z,gx1
        ld      a,'='
gx1:    call    putc
        ld      a,b
        add     a,31
        call    putc
        ld      a,c
        add     a,31
        call    putc
gxend:  pop     hl
        pop     bc
        ret

cls:    ld      a,(term)
        ld      hl,c_vt100
        cp      T_VT100
        jp      z,puts
        ld      hl,c_vt52
        cp      T_VT52
        jp      z,puts
        ld      a,26            ; ^Z
        jp      putc

; eol: erase to the end of the line (a reverse bar keeps its colour to the edge on a VT100)
eol:    ld      a,ESC
        call    putc
        ld      a,(term)
        cp      T_VT100
        ld      a,'['
        jr      nz,eol1
        call    putc
        ld      a,'K'
        jp      putc
eol1:   ld      a,(term)
        cp      T_VT52
        ld      a,'K'
        jp      z,putc
        ld      a,'T'           ; ADM-3A
        jp      putc

; setattr: A = the look from here on, of A_BOLD A_DIM A_BLINK A_REV, 0
; plain. VT100: ESC [ 0 ; 1 ; 2 ; 5 ; 7 m. ADM: ESC G n (2 blink, 4
; reverse) and ESC ) ( (half intensity on, off); no bold. VT52: none.
A_BOLD  equ     1
A_DIM   equ     2
A_BLINK equ     4
A_REV   equ     8
setattr: ld     c,a
        ld      a,(term)
        cp      T_VT52
        ret     z
        cp      T_ADM
        jr      z,sa_adm
        ld      a,ESC
        call    putc
        ld      a,'['
        call    putc
        ld      a,'0'
        call    putc
        ld      b,'1'
        ld      a,c
        and     A_BOLD
        call    nz,sa_n
        ld      b,'2'
        ld      a,c
        and     A_DIM
        call    nz,sa_n
        ld      b,'5'
        ld      a,c
        and     A_BLINK
        call    nz,sa_n
        ld      b,'7'
        ld      a,c
        and     A_REV
        call    nz,sa_n
        ld      a,'m'
        jp      putc
sa_n:   ld      a,';'
        call    putc
        ld      a,b
        jp      putc
sa_adm: ld      a,ESC
        call    putc
        ld      a,'G'
        call    putc
        ld      b,'0'
        ld      a,c
        and     A_BLINK
        jr      z,sa1
        inc     b
        inc     b
sa1:    ld      a,c
        and     A_REV
        jr      z,sa2
        ld      a,b
        add     a,4
        ld      b,a
sa2:    ld      a,b
        call    putc
        ld      a,ESC
        call    putc
        ld      a,c
        and     A_DIM
        ld      a,'('
        jr      z,sa3
        ld      a,')'
sa3:    jp      putc

; attrset: setattr that keeps every register
attrset: push   bc
        push    de
        push    hl
        call    setattr
        pop     hl
        pop     de
        pop     bc
        ret

; the cursor, hidden and shown: VT100 ESC[?25l/h, ADM ESC C 4 / ESC B 4; VT52 has none
curoff: ld      hl,h_vt100
        ld      de,h_adm
        jr      cur1
curon:  ld      hl,s_vt100
        ld      de,s_adm
cur1:   ld      a,(term)
        cp      T_VT100
        jp      z,puts
        cp      T_ADM
        ret     nz
        ex      de,hl
        jp      puts
h_vt100: db     ESC,'[?25l',0
s_vt100: db     ESC,'[?25h',0
h_adm:  db      ESC,'C4',0
s_adm:  db      ESC,'B4',0

c_vt100: db     ESC,'[H',ESC,'[2J',0
c_vt52: db      ESC,'H',ESC,'J',0

; the VT100 line-drawing set. gfxon/gfxoff switch G0 (ESC ( 0, ESC ( B); gc prints the
; drawing character A (l k m j corners, q x lines, a the checkerboard) and, on a terminal
; without the set, a plain ASCII stand-in (the caller keeps its loop in B: gc spends C).
gfxon:  ld      a,(term)
        cp      T_VT100
        ret     nz
        ld      a,'0'
        jr      gfx1
gfxoff: ld      a,(term)
        cp      T_VT100
        ret     nz
        ld      a,'B'
gfx1:   push    af
        ld      a,ESC
        call    putc
        ld      a,'('
        call    putc
        pop     af
        jp      putc
gc:     ld      c,a
        ld      a,(term)
        cp      T_VT100
        ld      a,c
        jp      z,putc
        cp      'q'
        ld      a,'-'
        jp      z,putc
        ld      a,c
        cp      'x'
        ld      a,'|'
        jp      z,putc
        ld      a,c
        cp      'a'
        ld      a,'#'
        jp      z,putc
        ld      a,'+'
        jp      putc

; ---------------------------------------------------------------- console
putc:   push    af
        push    bc
        push    de
        push    hl
        ld      e,a
        ld      a,(omode)
        or      a
        jr      nz,pc_mem
        ld      c,6
        call    BDOS
pc_x:   pop     hl
        pop     de
        pop     bc
        pop     af
        ret
pc_mem: ld      hl,(tptr)
        ld      (hl),e
        inc     hl
        ld      (tptr),hl
        jr      pc_x

; region: the VT100 scroll region from row B to row C (the cursor goes home); region0 sets it free.
; Other terminals: nothing.
region: ld      a,(term)
        or      a
        ret     nz
        ld      a,ESC
        call    putc
        ld      a,'['
        call    putc
        ld      a,b
        call    decn
        ld      a,';'
        call    putc
        ld      a,c
        call    decn
        ld      a,'r'
        jp      putc
region0: ld     a,(term)
        or      a
        ret     nz
        ld      hl,c_free
        jp      puts
c_free: db      ESC,'[r',0

; key: A = key or 0, no wait. VT100/VT52 arrows (ESC [ C, ESC C) map
; to WordStar ^E ^X ^S ^D.
key:    call    raw
        cp      ESC
        ret     nz
        call    raw
        cp      '['
        jr      nz,key1
        call    raw
key1:   cp      'A'
        ld      b,5
        jr      z,key2
        cp      'B'
        ld      b,24
        jr      z,key2
        cp      'C'
        ld      b,4
        jr      z,key2
        cp      'D'
        ld      b,19
        jr      z,key2
        ld      b,ESC
key2:   ld      a,b
        ret
raw:    push    bc
        push    de
        push    hl
        ld      e,0ffh
        ld      c,6
        call    BDOS
        pop     hl
        pop     de
        pop     bc
        ret

; wait for a key
getkey: call    key
        or      a
        jr      z,getkey
        ret

puts:   ld      a,(hl)
        or      a
        ret     z
        call    putc
        inc     hl
        jr      puts

; spaces: B of them
spaces: ld      a,' '
        call    putc
        djnz    spaces
        ret

upcase: cp      'a'
        ret     c
        cp      'z'+1
        ret     nc
        sub     32
        ret

; A in decimal, no padding (for VT100 coordinates)
decn:   cp      10
        jr      c,dn1
        ld      b,'0'-1
dn0:    inc     b
        sub     10
        jr      nc,dn0
        add     a,10
        push    af
        ld      a,b
        call    putc
        pop     af
dn1:    add     a,'0'
        jp      putc

; A as two digits
dec2:   ld      b,'0'-1
d20:    inc     b
        sub     10
        jr      nc,d20
        add     a,10+'0'
        push    af
        ld      a,b
        call    putc
        pop     af
        jp      putc

; pdec: HL in decimal, no padding
pdec:   ld      b,0
        ld      de,10000
        call    pd1
        ld      de,1000
        call    pd1
        ld      de,100
        call    pd1
        ld      de,10
        call    pd1
        ld      a,l
        add     a,'0'
        jp      putc
pd1:    ld      a,'0'-1
pd2:    inc     a
        or      a
        sbc     hl,de
        jr      nc,pd2
        add     hl,de
        cp      '0'
        jr      nz,pd3
        bit     0,b
        ret     z
pd3:    set     0,b
        jp      putc

; ---------------------------------------------------------------- random
; xorshift16 (7,9,8); A = the high byte of the new seed, 8 random bits
rnd:    push    hl
        ld      hl,(rseed)
        ld      a,h
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
        ld      (rseed),hl
        pop     hl
        ret

; the seed: R register mixed in (never zero)
seed:   ld      a,r
        ld      hl,(rseed)
        xor     l
        ld      l,a
        or      h
        jr      nz,sd1
        inc     l
sd1:    ld      (rseed),hl
        ret

; ---------------------------------------------------------------- terminal choice
; command tail: /100 /52 /ADM, and /S<number> (the world of a new log: for demonstrations and tests)
parse:  ld      hl,TAIL
        ld      b,(hl)
        inc     hl
pa1:    ld      a,b
        or      a
        ret     z
        ld      a,(hl)
        inc     hl
        dec     b
        cp      '/'
        jr      nz,pa1
        ld      a,b
        or      a
        ret     z
        ld      a,(hl)
        cp      '1'
        ld      c,T_VT100
        jr      z,pa2
        cp      '5'
        ld      c,T_VT52
        jr      z,pa2
        cp      'A'
        ld      c,T_ADM
        jr      z,pa2
        cp      'S'
        jr      z,pa_s
        jr      pa1
pa2:    ld      a,c
        ld      (term),a
        jr      pa1
pa_s:   inc     hl
        dec     b
        ld      de,0
ps1:    ld      a,b
        or      a
        jr      z,ps9
        ld      a,(hl)
        sub     '0'
        jr      c,ps9
        cp      10
        jr      nc,ps9
        push    hl
        ld      h,d
        ld      l,e
        add     hl,hl
        add     hl,hl
        add     hl,de
        add     hl,hl
        ld      e,a
        ld      d,0
        add     hl,de
        ex      de,hl
        pop     hl
        inc     hl
        dec     b
        jr      ps1
ps9:    ld      (argseed),de
        jr      pa1

askterm: ld     hl,m_ask
        call    puts
ak1:    ld      hl,(rseed)      ; the wait stirs the seed
        inc     hl
        ld      (rseed),hl
        call    raw
        sub     '1'
        jr      c,ak1
        cp      3
        jr      nc,ak1
        ld      (term),a
        ret
