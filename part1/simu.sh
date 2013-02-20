#!/bin/sh

for i in `seq 1 20`; do
	ns "$1.tcl" $i
done