#!/usr/bin/env python
"""
Produces load on all available CPU cores
"""

from multiprocessing import Pool
from multiprocessing import cpu_count
import time
import math

def g(x):
    while True:
        math.log(math.exp(1.0*x*x))

if __name__ == '__main__':
    processes = cpu_count()
    print 'Infinite loop using %d cores\n' % processes
    pool = Pool(processes)
    pool.map(g, range(processes))
