; fmt.asm: an entry as words. The entry is bytes (see world.asm); here the grammar turns it into
; a sentence in memory (tbuf) once, and the screen or LEDGER.LOG prints that. Output goes to
; memory while omode is 1: every routine that prints (puts, pdec, putc) can build text.
;
; entry: +0,+1 the night; +2 weather | variant<<3 | relief<<6; +3 ship | time<<3 | seen<<5 |
; variant<<6; +4 lamp | boat<<2 | variant<<3; +5 the oil left. A variant of 3 is the plain
; entry the relief hand writes.

; beginmem: output goes to tbuf. endmem: ends the text with a zero and goes back to the console.
beginmem: ld    hl,tbuf
        ld      (tptr),hl
memon:  ld      a,1
        ld      (omode),a
        ret
endmem: xor     a
        call    putc
memoff: xor     a
        ld      (omode),a
        ret

; fmtent: IX = entry -> tbuf = "Night 17. <weather> <lamp> <ship> <boat>"
fmtent: call    beginmem
        ld      hl,t_night
        call    puts
        ld      l,(ix+0)
        ld      h,(ix+1)
        call    pdec
        bit     6,(ix+2)
        jr      z,fe1
        ld      hl,t_relief
        call    puts
fe1:    ld      a,'.'
        call    putc
        ld      a,' '
        call    putc
        call    fm_wx
        ld      a,' '
        call    putc
        call    fm_lamp
        ld      a,' '
        call    putc
        call    fm_ship
        bit     2,(ix+4)
        jr      z,fe2
        ld      a,' '
        call    putc
        ld      hl,t_boat
        call    puts
fe2:    jp      endmem

; fm_wx, fm_lamp, fm_ship: one sentence of the entry IX, into the current output
fm_wx:  ld      a,(ix+2)
        and     7
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(ix+2)
        rrca
        rrca
        rrca
        and     3
        add     a,b
        ld      hl,wxtab
        call    tabget
        jr      tmpl
fm_lamp: ld     a,(ix+4)
        and     3
        add     a,a
        add     a,a
        ld      b,a
        ld      a,(ix+4)
        rrca
        rrca
        rrca
        and     3
        add     a,b
        ld      hl,lamptab
        call    tabget
        jr      tmpl
fm_ship: ld     a,(ix+3)
        and     7
        cp      7
        ld      b,8
        jr      z,fs1
        bit     5,(ix+3)
        ld      b,0
        jr      nz,fs1
        ld      b,4
fs1:    ld      a,(ix+3)
        rlca
        rlca
        and     3
        add     a,b
        ld      hl,shiptab
        call    tabget
        jr      tmpl

; tabget: A = index, HL = table of words -> HL = the word
tabget: add     a,a
        ld      e,a
        ld      d,0
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ret

; tmpl: HL = a phrase; the bytes 1 (the ship), 5 (the ship, capitalised) and 2 (when she
; passed) are filled in from the entry IX
tmpl:   ld      a,(hl)
        inc     hl
        or      a
        ret     z
        cp      8
        jr      c,tm_t
        call    putc
        jr      tmpl
tm_t:   push    hl
        ld      b,a
        cp      2
        jr      z,tk_t
        ld      a,(ix+3)
        and     7
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,nametab
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        ld      a,b
        cp      5
        jr      nz,tk_p
        ld      a,(hl)
        call    upcase
        call    putc
        inc     hl
tk_p:   call    puts
        pop     hl
        jr      tmpl
tk_t:   ld      a,(ix+3)
        rrca
        rrca
        rrca
        and     3
        add     a,a
        ld      e,a
        ld      d,0
        ld      hl,timetab
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        jr      tk_p

; pwrap: print the text HL in a column: B = first row, C = column, D = width, E = most rows.
; Breaks at spaces. In memory (omode 1) it ends each line with CR LF instead of moving the
; cursor, and the rows and column mean nothing but the width.
pwrap:  ld      a,e
        ld      (pw_rows),a
        ld      a,d
        ld      (pw_w),a
        ld      a,b
        ld      (pw_row),a
        ld      a,c
        ld      (pw_col),a
        xor     a
        ld      (pw_first),a
pw1:    ld      a,(hl)
        or      a
        ret     z
        ld      a,(pw_rows)
        or      a
        ret     z
        dec     a
        ld      (pw_rows),a
        ld      a,(omode)
        or      a
        jr      nz,pw_m
        push    hl
        ld      a,(pw_row)
        ld      b,a
        inc     a
        ld      (pw_row),a
        ld      a,(pw_col)
        ld      c,a
        call    gotoxy
        pop     hl
        jr      pw_g
pw_m:   ld      a,(pw_first)
        or      a
        jr      z,pw_f
        ld      a,CR
        call    putc
        ld      a,LF
        call    putc
pw_f:   ld      a,1
        ld      (pw_first),a
pw_g:   ld      a,(pw_w)
        ld      b,a
        ld      d,h
        ld      e,l
        ld      c,0
        ld      a,0ffh
        ld      (pw_ls),a
pw2:    ld      a,(de)
        or      a
        jr      z,pw_e
        cp      ' '
        jr      nz,pw3
        ld      a,c
        ld      (pw_ls),a
pw3:    inc     de
        inc     c
        djnz    pw2
        ld      a,(de)          ; the line is full: break at a space
        or      a
        jr      z,pw_e
        cp      ' '
        jr      z,pw_e
        ld      a,(pw_ls)
        cp      0ffh
        jr      z,pw_e
        ld      c,a
pw_e:   ld      b,c
        ld      a,b
        or      a
        jr      z,pw5
pw4:    ld      a,(hl)
        call    putc
        inc     hl
        djnz    pw4
pw5:    ld      a,(hl)
        cp      ' '
        jr      nz,pw1
        inc     hl
        jr      pw5
