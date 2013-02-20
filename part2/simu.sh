#!/bin/sh

for i in `seq $2 $4 $3`; do
	ns "$1.tcl" $i
done