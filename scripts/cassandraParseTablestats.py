#!/bin/python3

import sys
import argparse
from time import perf_counter


t_start = perf_counter()


def config():
    """
    get user inputs
    """
    parser = argparse.ArgumentParser(description="""parse cassandra tablestats to csv""")
    parser.add_argument("-i","--input", default='cassandraDiscover.log', help="name of the log file input file to parse")
    parser.add_argument("-o","--output", help="name of the csv output file")
    args = parser.parse_args()
    infile = args.input
    outfile = args.output
    if not outfile:
        outfile = infile[:-3] + "csv"
    print(f"Parse {infile} to {outfile}")
    parse(infile, outfile)
    return


def parse(infile, outfile):
    """
    parse cassandra tablestats logs
    """
    t0 = perf_counter()

    listkeys = ['Table', 'SSTable count', 'Old SSTable count', 'SSTables in each level', 'SSTable bytes in each level', 'Space used (live)', 'Space used (total)', 'Space used by snapshots (total)', 'Off heap memory used (total)', 'SSTable Compression Ratio', 'Number of partitions (estimate)', 'Memtable cell count', 'Memtable data size', 'Memtable off heap memory used', 'Memtable switch count', 'Local read count', 'Local read latency', 'Local write count', 'Local write latency', 'Pending flushes', 'Percent repaired', 'Bytes repaired', 'Bytes unrepaired', 'Bytes pending repair', 'Bloom filter false positives', 'Bloom filter false ratio', 'Bloom filter space used', 'Bloom filter off heap memory used', 'Index summary off heap memory used', 'Compression metadata off heap memory used', 'Compacted partition minimum bytes', 'Compacted partition maximum bytes', 'Compacted partition mean bytes', 'Average live cells per slice (last five minutes)', 'Maximum live cells per slice (last five minutes)', 'Average tombstones per slice (last five minutes)', 'Maximum tombstones per slice (last five minutes)', 'Read Count', 'Read Latency', 'Write Count', 'Write Latency', 'Pending Flushes', 'Dropped Mutations', 'Droppable tombstone ratio']
    dico = {}
    for k in listkeys:
        dico[k.strip()] = []
    print(dico)
    startTableStats = 0
    endTableStats = 0
    ks = "NaN"
    table = "NaN"
    with open(infile,'r') as f:
        lines = f.read().splitlines()
        for i in range(len(lines)):
            line = lines[i]
            if not startTableStats and line[:22] == "===== tablestats =====":
                startTableStats = i
                print(f"startTableStats = {startTableStats}")
            elif not endTableStats and line[:26] == "===== tablestats END =====":
                endTableStats = i
                print(f"endTableStats = {endTableStats}")
            elif startTableStats and not endTableStats and i > startTableStats:
                vals = line.split(":")
                key = vals[0].strip()
                if len(vals) > 1:
                    val = vals[1].strip()
                    # there can be comma in the values SSTables in each level=[1, 0, 0, 0, 0, 0, 0, 0, 0]
                    val = val.replace(",",";")
                else:
                    val = "NaN"
                if key == "Keyspace":
                    ks = val
                if ks not in ["system", "system_auth", "system_schema", "system_distributed"]:
                    if key in ["Table", "Table (index)"]:
                        table = f"{ks}.{val}"
                        # init all columns with NaN
                        for k in listkeys:
                            dico[k].append("NaN")
                        dico["Table"][-1] = table
                    elif key in listkeys and table != "NaN":
                        if val[-3:] == "KiB":
                            val = float(val[:-3]) * 1024
                        elif val[-3:] == "MiB":
                            val = float(val[:-3]) * 1024**2
                        elif val[-3:] == "GiB":
                            val = float(val[:-3]) * 1024**3
                        elif val[-3:] == "TiB":
                            val = float(val[:-3]) * 1024**4
                        elif val[-3:] == " ms":
                            val = val[:-3]
                        dico[key][-1] = str(val)

    #print(dico)
    fio = open(outfile, 'w')
    fio.write(",".join(listkeys)+"\n")
    for i in range(len(dico["Table"])):
        line = ""
        for k in listkeys:
            line += f",{dico[k][i]}"
        fio.write(line.lstrip(",")+"\n")
    t1 = perf_counter()
    print("TOTAL time : %f"% (t1-t0))


if __name__ == "__main__":
    config()
