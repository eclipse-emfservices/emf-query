#!/bin/sh

echo " "
echo "[`date +%k\:%M\:%S`]"
echo "  $1" | sed -e 's/\ \-/\¶\ \ \ \ \-/g' | tr "¶" "\n"
$1
