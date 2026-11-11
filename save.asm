; save.asm: LEDGER.SAV (the state: 7 records of 128 bytes, straight from `state`) and LEDGER.LOG
; (the diary, as text: the same entries as the book, one paragraph a night, the last 128 nights).
; Both are written whenever a night is written and when you leave; the .SAV is read at the start.

SAVEREC equ     7
STATESZ equ     896
LOGEND  equ     lbuf+26600      ; the entries stop here, the harbour book follows

; fcbz: DE = a file control block -> its working part cleared
fcbz:   ld      hl,12
        add     hl,de
        ld      d,h
        ld      e,l
        inc     de
        ld      (hl),0
        ld      bc,23
        ldir
        ret

; wfile: DE = fcb, HL = data, B = records: delete, make, write, close
wfile:  ld      (wf_fcb),de
        ld      (wf_p),hl
        ld      a,b
        ld      (wf_n),a
        ld      de,(wf_fcb)
        call    fcbz
        ld      de,(wf_fcb)
        ld      c,19
        call    BDOS
        ld      de,(wf_fcb)
        call    fcbz
        ld      de,(wf_fcb)
        ld      c,22
        call    BDOS
        inc     a
        ret     z               ; the disk is full: no file
wf1:    ld      a,(wf_n)
        or      a
        jr      z,wf2
        ld      de,(wf_p)
        ld      c,26
        call    BDOS
        ld      de,(wf_fcb)
        ld      c,21
        call    BDOS
        ld      hl,(wf_p)
        ld      de,128
        add     hl,de
        ld      (wf_p),hl
        ld      hl,wf_n
        dec     (hl)
        jr      wf1
wf2:    ld      de,(wf_fcb)
        ld      c,16
        jp      BDOS

savegame: ld    de,fcb_sav
        ld      hl,state
        ld      b,SAVEREC
        call    wfile
        call    genlog
        ld      de,fcb_log
        ld      hl,lbuf
        ld      a,(lrecs)
        ld      b,a
        jp      wfile

; load: A = 1 if there was a save to read
load:   ld      de,fcb_sav
        call    fcbz
        ld      de,fcb_sav
        ld      c,15
        call    BDOS
        inc     a
        jr      z,ld_none
        ld      hl,state
        ld      b,SAVEREC
ld1:    push    bc
        push    hl
        ex      de,hl
        ld      c,26
        call    BDOS
        ld      de,fcb_sav
        ld      c,20
        call    BDOS
        pop     hl
        pop     bc
        or      a
        jr      nz,ld_bad
        ld      de,128
        add     hl,de
        djnz    ld1
        ld      de,fcb_sav
        ld      c,16
        call    BDOS
        ld      a,(state)
        cp      'L'
        jr      nz,ld_bad
        ld      a,(state+1)
        cp      'G'
        jr      nz,ld_bad
        ld      a,(state+2)
        cp      1
        jr      nz,ld_bad
        ld      a,1
        ret
ld_bad: xor     a
        ret
ld_none: xor    a
        ret

; genlog: the diary as text in lbuf; lrecs = its length in records
genlog: ld      hl,lbuf
        ld      (tptr),hl
        call    memon
        ld      hl,t_loghead
        call    puts
        ld      hl,(st_last)
        ld      a,h
        or      l
        jr      z,gl_foot
        ld      de,128
        or      a
        sbc     hl,de
        jr      c,lg1
        inc     hl
        jr      lg2
lg1:    ld      hl,1
lg2:    ld      (gl_n),hl
gl3:    ld      hl,(tptr)
        ld      de,LOGEND
        or      a
        sbc     hl,de
        jr      nc,gl_foot
        ld      hl,(gl_n)
        call    getent
        jr      nc,gl5
        ld      hl,(tptr)
        ld      (lptr),hl
        call    fmtent
        ld      hl,(lptr)
        ld      (tptr),hl
        call    memon
        ld      hl,tbuf
        ld      b,0
        ld      c,0
        ld      d,72
        ld      e,10
        call    pwrap
        ld      a,CR
        call    putc
        ld      a,LF
        call    putc
gl5:    ld      hl,(gl_n)
        inc     hl
        ld      (gl_n),hl
        ld      de,(st_last)
        ex      de,hl
        or      a
        sbc     hl,de
        jr      nc,gl3
gl_foot: ld     hl,t_logfoot
        call    puts
        xor     a
        ld      (hb_i),a
gf1:    ld      a,(hb_i)
        ld      hl,nametab
        call    tabget
        ld      a,(hl)
        call    upcase
        call    putc
        inc     hl
        call    puts
        ld      a,':'
        call    putc
        ld      a,' '
        call    putc
        ld      a,(hb_i)
        ld      e,a
        ld      d,0
        ld      hl,st_ans
        add     hl,de
        ld      a,(hl)
        ld      l,a
        ld      h,0
        call    pdec
        ld      hl,t_logans
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
        ld      hl,t_logun
        call    puts
        ld      hl,hb_i
        inc     (hl)
        ld      a,(hl)
        cp      6
        jr      c,gf1
        ld      hl,(tptr)
        call    memoff
        push    hl              ; the end of the text
        ld      de,lbuf
        or      a
        sbc     hl,de
        ld      de,127
        add     hl,de
        ld      a,h             ; records = (length + 127) / 128
        add     a,a
        ld      b,a
        ld      a,l
        rlca
        and     1
        add     a,b
        ld      (lrecs),a
        ld      h,a             ; the end of the last record = lbuf + records * 128
        srl     h
        ld      l,0
        rr      l
        ld      de,lbuf
        add     hl,de
        ex      de,hl
        pop     hl
gl6:    push    hl
        or      a
        sbc     hl,de
        pop     hl
        ret     nc
        ld      (hl),1ah
        inc     hl
        jr      gl6

fcb_sav: db     0,'LEDGER  SAV',0,0,0,0
        defs    20
fcb_log: db     0,'LEDGER  LOG',0,0,0,0
        defs    20
