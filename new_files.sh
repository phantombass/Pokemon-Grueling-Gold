#!/bin/sh
FILES=`git ls-files --modified`
export_dir="E:\Games\Pokemon Grueling Gold"
for x in $FILES
do
   prev_dir=$PWD
   folder=$(dirname $x)
   echo "Exporting to..." $export_dir/$x
   cp $prev_dir/$x $export_dir/$x
done