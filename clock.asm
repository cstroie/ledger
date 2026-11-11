; clock.asm: the date and time, the arithmetic it needs, and the night.
;
; DigitalRerun has a clock device on port 20: OUT latches a record, 15 INs read it. Bytes 1-2
; are the days since 31 Dec 1977, 3-5 hour, minute, second in BCD. LEDGER lives on one number,
; M, the minutes since that day. A night is 180 minutes (three hours), so the night count is
; M/180 (cn32, 32 bits: it passes 65535 in the year 2000) and pnow, M mod 180, is how far into
; the night we are. The first night of a log is the one it was started in (st_start): night n
; is cn32 - st_start + 1, which fits 16 bits for sixty years. Without the device (a real Z80,
; another emulator) every start is the next night and nothing moves while you watch.

CLKPORT equ     20
NIGHT   equ     180

; gettime: reads the clock. Sets mnow (32 bits), cn32 (night count), pnow (minute within the
; night), mdnow (minute of the day) and hasclk.
gettime: out    (CLKPORT),a
        ld      hl,clkbuf
        ld      b,15
gt1:    in      a,(CLKPORT)
        ld      (hl),a
        inc     hl
        djnz    gt1
        ld      a,(clkbuf)
        cp      1
        jr      nz,gt_no
        ld      a,1
        ld      (hasclk),a
        ld      hl,(clkbuf+1)
        ld      de,1440
        call    mul32
        ld      a,(clkbuf+3)
        call    bcd2bin
        ld      b,a
        ld      hl,0
        ld      de,60
        inc     b
        jr      gt3
gt2:    add     hl,de
gt3:    djnz    gt2
        ld      a,(clkbuf+4)
        call    bcd2bin
        ld      e,a
        ld      d,0
        add     hl,de
        ld      de,(m32)
        add     hl,de
        ld      (m32),hl
        jr      nc,gt4
        ld      hl,(m32+2)
        inc     hl
        ld      (m32+2),hl
        jr      gt4
gt_no:  xor     a
        ld      (hasclk),a
        ld      hl,0
        ld      (m32),hl
        ld      (m32+2),hl
gt4:    ld      hl,(m32)
        ld      (mnow),hl
        ld      hl,(m32+2)
        ld      (mnow+2),hl
        ld      de,NIGHT
        call    div32
        ld      (pnow),hl
        ld      hl,(m32)
        ld      (cn32),hl
        ld      hl,(m32+2)
        ld      (cn32+2),hl
        ld      hl,(mnow)
        ld      (m32),hl
        ld      hl,(mnow+2)
        ld      (m32+2),hl
        ld      de,1440
        call    div32
        ld      (mdnow),hl
        ret

bcd2bin: ld     c,a
        and     0f0h
        rrca
        rrca
        rrca
        rrca
        ld      b,a
        add     a,a
        add     a,a
        add     a,b
        add     a,a
        ld      b,a
        ld      a,c
        and     0fh
        add     a,b
        ret

; mul32: HL x DE -> m32 (32 bits, little endian)
mul32:  ld      (mA),hl
        ld      hl,0
        ld      (mA+2),hl
        ld      (m32),hl
        ld      (m32+2),hl
        ex      de,hl
        ld      b,16
mm1:    srl     h
        rr      l
        jr      nc,mm2
        push    hl
        ld      hl,(m32)
        ld      de,(mA)
        add     hl,de
        ld      (m32),hl
        ld      hl,(m32+2)
        ld      de,(mA+2)
        adc     hl,de
        ld      (m32+2),hl
        pop     hl
mm2:    push    hl
        ld      hl,(mA)
        add     hl,hl
        ld      (mA),hl
        ld      hl,(mA+2)
        adc     hl,hl
        ld      (mA+2),hl
        pop     hl
        djnz    mm1
        ret

; div32: m32 / DE -> m32 (the quotient), HL = the remainder. DE up to 2000 or so.
div32:  ld      hl,0
        ld      b,32
dv1:    push    hl
        ld      hl,(m32)
        add     hl,hl
        ld      (m32),hl
        ld      hl,(m32+2)
        adc     hl,hl
        ld      (m32+2),hl
        pop     hl
        adc     hl,hl
        or      a
        sbc     hl,de
        jr      nc,dv2
        add     hl,de
        jr      dv3
dv2:    push    hl
        ld      hl,m32
        inc     (hl)            ; bit 0 is clear after the shift
        pop     hl
dv3:    djnz    dv1
        ret

; div16: HL / E (1-255) -> HL the quotient, A the remainder
div16:  xor     a
        ld      b,16
d16a:   add     hl,hl
        rla
        cp      e
        jr      c,d16b
        sub     e
        inc     l
d16b:   djnz    d16a
        ret

; delay: a pause of about 100 ms at 4 MHz; delay1: about 8 ms
DLY_OUT equ     110
delay:  ld      c,DLY_OUT
dly1:   ld      b,0
dly2:   djnz    dly2
        dec     c
        jr      nz,dly1
        ret
delay1: ld      c,9
        jr      dly1
