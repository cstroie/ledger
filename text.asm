; text.asm: the words of the program itself. The phrases of the log are in words.txt.

t_title: db     ' LEDGER  the keeper',39,'s log',0
t_night: db     'Night ',0
t_night1: db    ' night',0
t_nights: db    ' nights',0
t_relief: db    ' (relief hand)',0
t_boat: db      'The oil boat came.',0
t_noclk: db     '(no clock)',0
t_noclk2: db    'The next night begins when you come back.',0
t_h:    db      ' h ',0
t_min:  db      ' min',0
t_booktitle: db ' The Log of the Sisters Light ',0
t_pg:   db      ' nights ',0
t_blank: db     'The page is blank. The lamp is not yet lit.',0
t_cal:  db      ' Calendar, wrap ',0
t_layer: db     'V ',0
t_focus: db     '   F ',0
layertab: dw    ly0,ly1,ly2
ly0:    db      'weather',0
ly1:    db      'ships',0
ly2:    db      'lamp',0
focustab: dw    fc0,fc1,fc2,fc3,fc4,fc5,fc6,fc7,fc8,fc9,fc10
fc0:    db      'nothing',0
fc1:    db      'storms',0
fc2:    db      'swells',0
fc3:    db      'wind',0
fc4:    db      'fog',0
fc5:    db      'Margit',0
fc6:    db      'Dunmore Lass',0
fc7:    db      'packet',0
fc8:    db      'Hester Vane',0
fc9:    db      'Ostrander',0
fc10:   db      'strangers',0
t_oil:  db      'Oil ',0
t_of:   db      ' of 30   Oil boat ',0
t_tonight: db   'tonight',0
t_boatin: db    'in ',0
t_open1: db     ' Night ',0
t_open2: db     ' is open. How will the lamp burn? ',0
loptab: dw      lt0,lt1,lt2,lt3
lt0:    db      'E early (3 oil)   ',0
lt1:    db      'D at dark (2)   ',0
lt2:   db      'L late (1)   ',0
lt3:    db      'S not at all (0)',0
t_written: db   'Night ',0
t_written2: db  ' is written.',0
t_begins: db    'Night ',0
t_in:   db      ' begins in ',0
t_lastlamp: db  'The lamp, last night: ',0
t_nothing: db   '. Nothing needs doing.',0
lampwtab: dw    lw0,lw1,lw2,lw3
lw0:    db      'lit early',0
lw1:    db      'lit at dark',0
lw2:    db      'lit late',0
lw3:    db      'left cold',0
t_hints: db     '<- -> page  W wrap  V show  F find  H harbour  M bell  R new  ? help  Q leave',0
t_passes: db    'The night passes. You hear it more than you see it.',0
t_write1: db    ' Night ',0
t_write2: db    ': the ',0
t_write3: db    '. Choose the words, 1 2 or 3 (Enter takes the first). ',0
slotwtab: dw    sw0,sw1,sw2
sw0:    db      'weather',0
sw1:    db      'lamp',0
sw2:    db      'ships',0
t_noil: db      'Not enough oil for that. The boat comes every twelfth night.',0
t_already: db   'This night is written. Nothing needs doing until the next.',0
t_newn: db      'A new night has begun.',0
t_relw: db      'The relief hand wrote ',0
t_relw2: db     ' while the page waited.',0
t_letter1: db   'A letter has come from ',0
t_letter2: db   '. It is in the harbour book (H).',0
t_bellon: db    'The bell is on.',0
t_belloff: db   'The bell is off.',0
t_press: db     'press a key',0
t_away: db      'You were away for ',0
t_relief1: db   'The relief hand kept the lamp frugally and wrote the log in plain words:',0
t_wl1:  db      ' nights with the lamp lit',0
t_wl2:  db      ' ships answered the light',0
t_wl3:  db      ' ships passed unseen',0
t_wl4:  db      ' storms',0
t_nothing2: db  'Nothing is owed and nothing is lost. The log goes on from here.',0
t_harbour: db   ' The harbour book',0
t_dash: db      ' - ',0
t_ans:  db      ' answered, ',0
t_unseen: db    ' unseen',0
t_noletter: db  'No letter yet. A ship writes once her light has been answered often enough.',0
t_big:  db      'L E D G E R',0
introtab: dw    i0,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,0
i0:     db      0
i1:     db      0
i2:     db      '    the lighthouse keeper',39,'s logbook',0
i3:     db      0
i4:     db      'You keep a coastal light for a village. You never see the sea, only',0
i5:     db      'the book: what the night brought is written there, and nowhere else.',0
i6:     db      0
i7:     db      'Each night, light the lamp early (E), at dark (D), late (L) or not at',0
i8:     db      'all (S), then choose the words you write. Oil is limited; a boat brings',0
i9:     db      'more on every twelfth night.',0
i10:     db      0
i11:     db      'The book is the game. Turn back through it with the arrow keys. At the',0
i12:     db      'right the calendar folds the nights into rows: W changes the width until',0
i13:     db      'they line up, V changes what it shows, F lights up one thing. A ship that',0
i14:     db      'came on the 3rd, the 10th and the 17th will come again. And a swell is',0
i15:     db      'never only a swell.',0
i16:     db      0
i17:     db      'Away, you lose nothing: a relief hand lights the lamp frugally and writes',0
i18:     db      'plain entries. Leave this screen open and it rings when a night begins.',0
i19:     db      'Your diary is the file LEDGER.LOG: TYPE it from CP/M.',0
t_loghead: db   'THE LOG OF THE SISTERS LIGHT',CR,LF,'A night is three hours. A lamp shows a ship that passes after it was lit.',CR,LF,CR,LF,0
t_logfoot: db   CR,LF,'The harbour book',CR,LF,0
t_logans: db    ' answered, ',0
t_logun: db     ' unseen',CR,LF,0
t_bye:  db      'The relief hand has the lamp. The log is in LEDGER.LOG (TYPE LEDGER.LOG).',0
m_ask:  db      'LEDGER: which terminal?  1 VT100   2 VT52   3 ADM-3A  ',0
t_resetq: db    'Start a new log? The old one is lost. Y for yes, any other key keeps it.',0
t_fore: db      'A storm, and the lamp was lit: you saw it coming in the log.',0
t_letterw: db   'A letter came while the page waited. It is in the harbour book (H).',0
t_wlet: db      'A letter is waiting in the harbour book (H) from ',0
t_comma: db     ', ',0
t_hint0: db     'Her light was never answered. See when she passes, and when you lit.',0
t_village: db   'The village has had your light ',0
t_village2: db  ' times. Storms foreseen: ',0
