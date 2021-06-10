import sys
import string
import csv

filename = sys.argv[1]
print "Treating ",filename
outfilename = filename + '.out'

with open(filename,'r') as csvinput:
    with open(outfilename, 'w') as csvoutput:
        writer = csv.writer(csvoutput, lineterminator='\n')
        reader = csv.reader(csvinput)

        all = []
        # row = next(reader)
        # row.append('true')
        # all.append(row)

        for row in reader:
            row.append('true')
            all.append(row)

        writer.writerows(all)

print "Done writing ",outfilename
