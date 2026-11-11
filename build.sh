#!/bin/sh
# Build LEDGER: words.inc from words.txt (Node.js), then LEDGER.COM with pasmo
# (apt install pasmo, or set PASMO=/path/to/pasmo).
# DEST=<dir> also copies the program there (DigitalRerun's shelf disk).
set -e
cd "$(dirname "$0")"
node mkwords.js
${PASMO:-pasmo} ledger.asm LEDGER.COM
if [ -n "$DEST" ]; then cp LEDGER.COM "$DEST"/; fi
ls -l LEDGER.COM
