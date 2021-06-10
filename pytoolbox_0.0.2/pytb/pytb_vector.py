#=========================================================================================
"""
 pytb_vector.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.2'
__author__='J.Laurenceau/Airbus France'
__history__=\
"""
_ Creation date : mar 2007
_ basic tools for vectors (list of float/int)
"""
#=========================================================================================

import commands,os,re,string,sys,shutil
##========================
##
##========================
def convert_str(vect):
    """
    Get a vector and return the values it contains in a single string
    """
    try:
        strvect = ''
        for i in range(0,len(vect)) :
            strvect = strvect + str(vect[i]) + '\t'
        return strvect
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_vector.convert_str()'
        print error
        sys.exit(9999)
##========================
##
##========================
def printscr(vect):
    """
    print a vector in a single line
    """
    try:
        strvect = convert_str(vect)
        print strvect
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_vector.print()'
        print error
        sys.exit(9999)
##========================
##
##========================
def vect_norm2(vect):
    """
    Get a vector and return its norm**2
    """
    norm = 0.0
    for i in range(0,len(vect)) :
        norm = norm + vect[i]**2
    return norm
