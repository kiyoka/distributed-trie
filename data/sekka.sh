#!/bin/sh
egrep 'MASTER::[(][a-z][a-z][)]' SEKKA-JISYO.SMALL.tsv > kanji.tsv
cat kanji.tsv | nendo kanji_index.nnd > sekka_roman_of_kanjidata.txt

