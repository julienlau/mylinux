#=========================================================================================
"""
 pytb_damas.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.1'
__author__='R. Boisard/Altran & J.Laurenceau/Airbus France'
__history__=\
"""
_ Creation date : mar 2007
_ manipulate damas
"""
#=========================================================================================

import commands,os,re,string,sys,shutil
##========================
##
##========================
def rmdam(damas):
    """
    remove a damas database
    """
    try:
        for nb_base in range(1,6):
            deldam=str(damas)+'_'+str(nb_base)+'.sda'
            if os.path.isfile(deldam):
                os.remove(deldam)
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_damas.rmdam()'
        print error
        return False
##========================
##
##========================
def cpdam(damasin,damasout):
    """
    copy a damas database
    """
    try:
        for nb_base in range(1,5):
            shutil.copy(str(damasin)+'_'+str(nb_base)+'.sda',
                            str(damasout)+'_'+str(nb_base)+'.sda')
        if os.path.isfile(str(damasin)+'_5.sda'):
            shutil.copy(str(damasin)+'_5.sda',
                            str(damasout)+'_5.sda')
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_damas.cpdam()'
        print error
        return False
##========================
##
##========================
def mvdam(damasin,damasout):
    """
    move a damas database
    """
    try:
        for nb_base in range(1,5):
            os.rename(str(damasin)+'_'+str(nb_base)+'.sda',
                            str(damasout)+'_'+str(nb_base)+'.sda')
        if os.path.isfile(str(damasin)+'_5.sda'):
            os.rename(str(damasin)+'_5.sda',
                            str(damasout)+'_5.sda')
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_damas.mvdam()'
        print error
        return False
##========================
##
##========================
def cleandam():
    """
    remove all damas databases in the current directory
    """
    try:
        list = os.listdir('.')
        for file in list:
            name = string.split(file)
            name = name[0]
            n = len(name)
            if name[n-1] == 'a' and name[n-2] == 'd' and name[n-3] == 's' and name[n-4] == '.':
                damas = ''
                for i in range(0,n-4-2):
                    damas = damas+ name[i]
                for nb_base in range(1,6):
                    deldam=str(damas)+'_'+str(nb_base)+'.sda'
                    if os.path.isfile(deldam):
                        print 'Removing damas '+damas
                        os.remove(deldam)
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_damas.rmdam()'
        print error
        return False
