# Python 2 and 3: 
from __future__ import print_function
from __future__ import unicode_literals
#
import argparse
import string
import sys
reload(sys)
sys.setdefaultencoding('utf8')

def slatevdbg_io():
    """
    routine that gets user inputs
    """
    parser = argparse.ArgumentParser(description="""Add a test on variable v_isdbg before all 'console.log'
    The input file is the export of a slate to a json.""")
    parser.add_argument("-i","--input", default='file.json', help="name of the json input file to parse and convert")
    parser.add_argument("-o","--output", default='file.json', help="name of the json output file")
    args = parser.parse_args()
    infile = args.input
    outfile = args.output
    slatevdbg(infile, outfile)
    return

def slatevdbg(infile, outfile):
    """
    infile : a json file exported from slate
    outfile : a json file to be imported in slate
    """
    fin = open(infile,'r')
    all_line = fin.readlines()
    fin.close()
    fout = open(outfile,'w')
    counter = 0
    for line in all_line:
        newline = line
        if string.find(line,"""console.log(""") != -1 :
            counter += 1
            newline = line.replace("""console.log(""", """if ({{v_isdbg}}>=1) console.log(""")
            print (line + " => " + newline)
        fout.write("%s\n" % newline)
    fout.close()
    print("there was %i replace operations" % counter)
    return

if __name__ == "__main__":
    slatevdbg_io()
