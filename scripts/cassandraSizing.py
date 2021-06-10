# Python 2 and 3: 
from __future__ import print_function
from __future__ import unicode_literals
#
import math
import argparse

def cassandraSizingIO() :
    """
    I/O routines that gets characteristics of your Cassandra database
    """
    parser = argparse.ArgumentParser(description="Estimate the size of a Cassandra database")
    parser.add_argument("--nr", default='-1', help="number of ROWS (or estimated target)")
    parser.add_argument("--nc", default='0',help="average number of COLUMNS over all the rows")
    parser.add_argument("--cns", default='10',help="average byte size of name of COLUMN. Default=10.")
    parser.add_argument("--cvs", default='4',help="average byte size of data stored in a COLUMN value. Default=4")
    parser.add_argument("--rks", default='4*9',help="average byte size of KEYS.")
    parser.add_argument("--rf", type=int, default=3,help="replication factor. Default=3")
    parser.add_argument("--nn", type=int, default=1,help="number of nodes in cluster. Default=1")
    parser.add_argument("--compression", type=float, default=0.2,help="ratio of compression achieved when using SnappyCompression or LZO. Default=0.2")

    args = parser.parse_args()
    
    nr = float(eval(args.nr))
    if nr < 1.0:
        parser.print_help()
        raise Exception("nr argument should be specified as a positive number")
    nc = float(eval(args.nc))
    if nc < 1.0:
        parser.print_help()
        raise Exception("nc argument should be specified as a positive number")
    cns = float(eval(args.cns))
    cvs = float(eval(args.cvs))
    rks = float(eval(args.rks))
    rf = args.rf
    nn = args.nn
    compress = float(args.compression)
    
    cassandraSizing( nr, nc, cns, cvs, rks, rf, nn, compress )

    return

def cassandraSizing( nr, nc, cns, cvs, rks, rf, nn, compress ) :
    # if column value use TTL (Time To Live) there is a 8 bytes overhead
    colTTL = 0 * 8.0
    # if column value use counter there is a 8 bytes overhead
    colCounter = 0 * 8.0
    tnc = float(nr * nc)
    
    colData = tnc * cvs
    colOverhead = tnc * (15 + colTTL + colCounter + cns) # timestamp takes 8bytes
    rowHeaderOverhead = float(nr) * (23 + rks)
    rowBloomFilter = float(nr) * (2+8+math.ceil((nc*4+20)/8))
    rowIndex = nr * 4.0
    sstableIndex = float(nr) * (10 + rks)
    sstableBloomFilter = (float(nr) * 15 + 20) /8

    baseSize = colData + colOverhead + rowHeaderOverhead + rowBloomFilter + rowIndex + sstableIndex + sstableBloomFilter
    replicatedSize = baseSize * rf
    compactionOverhead = baseSize * 2
    totalSize = baseSize * 2 * rf

    print("nb row                   = {:1.2e}".format(nr) )
    print("nb col                   = {:1.2e}".format(nc) )
    print("avg bytesize of col name = {:}".format(cns) )
    print("avg bytesize of col val  = {:}".format(cvs) )
    print("avg bytesize of keys     = {:}".format(rks) )
    print("replication              = {:}".format(rf) )
    print("nb nodes in cluster      = {:}".format(nn) )

    print ("===========================")
    print ("===========================")
    print ("===========================")

    print ("number of cells = {:1.2e} equivalent to a denormalized vector of floating point values sizing {:1.2e}Gb".format(tnc, cvs*tnc/1024**3) )
    if tnc >= 2.0e+9 :
        print("BE AWARE ! number of cells exceeds CASSANDRA RECOMMENDED limitations for one partition : 2 billions")
        print("BE AWARE ! consider a minimum number of partition = {:d}".format(int(round(tnc/2.0e+9))))
        print("BE AWARE ! choose your PRIMARY_KEY in order to target a partition smaller than 100Mb and 100000 cells.")
    print ('')
    print ("actual column value data = {:1.2e} Gb ({:.2f} %)".format(colData/1024**3 , 100.0*colData/baseSize) )
    print ("column overhead          = {:1.2e} Gb ({:.2f} %)".format(colOverhead/1024**3, 100.0*colOverhead/baseSize ) )
    print ("row overhead             = {:1.2e} Gb ({:.2f} %)".format((rowHeaderOverhead + rowBloomFilter + rowIndex)/1024**3, 100.0*(rowHeaderOverhead + rowBloomFilter + rowIndex)/baseSize) )
    print ("SSTABLE overhead         = {:1.2e} Gb ({:.2f} %)".format((sstableIndex + sstableBloomFilter)/1024**3, 100.0*(sstableIndex + sstableBloomFilter)/baseSize) )
    print ('')
    print ("CASSANDRA base size (without replication and compaction) = {:1.2e} Tb".format(baseSize/1024**4) )
    print ("CASSANDRA TOTAL size                                     = {:1.2e} Tb".format(totalSize/1024**4) )
    print ('When activating the compressor and supposing a ratio of {}'.format(compress))
    print ("compressCASSANDRA base size                              = {:1.2e} Tb".format(baseSize/1024**4*compress) )
    print ("compressCASSANDRA TOTAL size                             = {:1.2e} Tb".format(totalSize/1024**4*compress) )
    print ("BE AWARE ! the size taken by the log is not taken into account")
    
    return

## 1024**1 -> Kb
## 1024**2 -> Mb
## 1024**3 -> Gb
## 1024**4 -> Tb

if __name__ == "__main__":
    cassandraSizingIO()
