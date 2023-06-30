#!/usr/bin/python
import argparse
from time import perf_counter


t_start = perf_counter()
import pandas as pd


def parquet2csv_io():
    """
    routine that gets user inputs
    """
    parser = argparse.ArgumentParser(description="""convert parquet files to csv""")
    parser.add_argument("-i","--input", default='file.parquet', help="name of the json input file to convert")
    parser.add_argument("-o","--output", help="name of the json output file")
    parser.add_argument("-m","--method", default='pandas', help="method to use")
    args = parser.parse_args()
    infile = args.input
    outfile = args.output
    if not outfile:
        outfile = infile[:-7] + "csv"
    print(f"Convert {infile} to {outfile}")
    if args.method == "'fastparquet":
        parquet2csv_fp(infile, outfile)
    else:
        parquet2csv_pd(infile, outfile)
        
    return


def parquet2csv_pd(infile, outfile):
    t0 = perf_counter()
    print("time for pre : %f"% (t0-t_start))
    df = pd.read_parquet(infile)
    t1 = perf_counter()
    print("time for read : %f"% (t1-t0))
    t0 = t1
    df.to_csv(outfile)
    t1 = perf_counter()
    print("time for write : %f"% (t1-t0))
    print("TOTAL time : %f"% (t1-t_start))


def parquet2csv_fp(infile, outfile):
    from fastparquet import ParquetFile
    t0 = perf_counter()
    print("time for pre : %f"% (t0-t_start))
    pf = ParquetFile(infile)
    t1 = perf_counter()
    print("time for read : %f"% (t1-t0))
    t0 = t1
    df = pf.to_pandas()
    t1 = perf_counter()
    print("time for dataframe creation : %f", t1-t0)
    t0 = t1
    df.to_csv(outfile)
    t1 = perf_counter()
    print("time for write : %f", t1-t0)
    print("TOTAL time : %f"% (t1-t_start))
    return


if __name__ == "__main__":
    parquet2csv_io()
