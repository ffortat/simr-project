#!/usr/bin/python

import sys

file = open(sys.argv[1] + '.tr')
target = open(sys.argv[1] + '-ms.tr', 'w')

for line in file :
	values = line.split()
	values[1] = str(float(values[1]) * 1000)
	values[2] = str(float(values[2]) * 1000)
	values[3] = str(float(values[3]) * 1000)
	values[4] = str(float(values[4]) * 1000)
	target.write(' '.join(values) + '\n')

file.close()
target.close()
