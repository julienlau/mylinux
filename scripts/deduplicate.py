#!/usr/bin/python
import sys

filename1 = sys.argv[1]
filename2 = sys.argv[2]
outfilename = sys.argv[3]

truncate = True
trunclen = 230

if not truncate : 
    with open(filename1, "r") as fio:
        lines_seen = fio.readlines()
    print "nblines in file1", len(lines_seen)
    outfile = open(outfilename, "w")
    with open(filename2, "r") as fio:
        for line in fio:
            print "DBG 1 = ", line[:230]
            print "DBG 2 = ", lines_seen[1][:128]
            if line not in lines_seen: # not a duplicate
                outfile.write(line)
    outfile.close()

else :
    lines_seen = []
    with open(filename1, "r") as fio:
        for line in fio:
            lines_seen.append(line[:min(trunclen,len(line))])
    print "nblines in file1", len(lines_seen)
    outfile = open(outfilename, "w")
    with open(filename2, "r") as fio:
        for line in fio:
            print "DBG 1 = ", line[:min(trunclen,len(line))]
            print "DBG 2 = ", lines_seen[1][:min(trunclen,len(line))]
            if line[:min(trunclen,len(line))] not in lines_seen: # not a duplicate
                outfile.write(line)
    outfile.close()

print "file %s written" % outfilename
