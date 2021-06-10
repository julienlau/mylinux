#=========================================================================================
"""
 pytb_datadic.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.2'
__author__='J.Laurenceau/Airbus France'
__history__=\
"""
_ Creation date : mar 2007
_ basic commands for data dictionary files, line='key value'
"""
#=========================================================================================

import commands,os,re,string,sys,shutil
##========================
##
##========================
def printdic(dico):
    """
    print a dictionary in the command line
    """
    try:
        if dico is not None:
            printme="\n*** VARIABLES ***"
	    listkeys, listvalues = sortdict(dico)
	    for i in range(len(listkeys)):
		printme+='\n'+string.ljust(str(listkeys[i]),25)+" = "+string.ljust(str(listvalues[i]),25)
            return printme+'\n'
        else:
            return 'None'
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_datadic.printdic()'
        print error
        return False
##========================
##
##========================
def catdic(master,slave):
    """
    cat 2 dicitionnary, the master one taking over the slave one
    return the master dictionary
    """
    try:
        for var,val in slave.iteritems():
            if var not in master.keys():
                master[var]=val
        return master
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_datadic.catdic()'
        print error
        return False
##========================
##
##========================
def sortdict1(adict):
    items = adict.items()
    items.sort()
    return [value for key, value in items]
##========================
##
##========================
def sortdict2(adict):
    """
    Sort a dictionnary by ordering the keys.
    """
    keys = adict.keys()
    keys.sort()
    return [adict[key] for key in keys]
##========================
##
##========================
def sortdict3(adict):
    keys = adict.keys()
    keys.sort()
    return map(adict.get, keys)
##========================
##
##========================
def sortdict(adict):
    keys = adict.keys()
    keys.sort()
    values = map(adict.get, keys)
    return keys, values
##========================
##
##========================

def writedic(dico,file,name):
    """
    Write backup of a dictionary into a file (python format)
    """
    try:
	listkeys, listvalues = sortdict(dico)
        fid=open(file,'w')
	for i in range(len(listkeys)):
	    fid.write(str(name)+"['"+str(listkeys[i])+"']=\""+str(listvalues[i])+'"\n')
        fid.close()
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_datadic.writedic()'
        print error
        return False
##========================
##
##========================
def read_datafile(datafile):
  """
  Read a config file, line format = 'key    value'
  and return the corresponding data as a dictionary
  """
  data={}
  try:
      fid=open(datafile,'r')
      for line in fid.readlines():
          if line[0] == '#':
              pass
          else:
              inputline=string.split(line)
              if len(inputline) == 0:
                  pass
              else:
                  if len(inputline) >= 2:
                      data[str(inputline[0])]=inputline[1]
      fid.close()
      return data
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.read_datafile()'
      print error
      return False
##========================
##
##========================
def write_datafile(data,datafile):
  """
  Write a config file, line format = 'key value' from a data dictionary
  """
  try:
      listkeys, listvalues = sortdict(data)
      fid=open(datafile,'w')
      for i in range(len(listkeys)):
          fid.write(str(listkeys[i])+'\t'+str(listvalues[i])+'\n')
      fid.close()
      return True
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.write_datafile()'
      print error
      return False
##========================
##
##========================
def append_datafile(data,datafile):
  """
  Write a config file in append mode, line format = 'key value' from a dictionary
  """
  try:
      slave = read_datafile(datafile)
      master = catdic(data,slave)
      listkeys, listvalues = sortdict(master)
      fid=open(datafile,'a')
      for i in range(len(listkeys)):
          fid.write(str(listkeys[i])+'\t'+str(listvalues[i])+'\n')
      fid.close()
      return master
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.append_datafile()'
      print error
      return False
##========================
##
##========================
def datased(data,f_input,f_output):
  """
  Inputs: dictionary, input filename, output filename
  Enables to perform multiples sed in one command.
  All the strings to be replaced are the keys of the dictionary.
  They are replaced by their correspondinf value in the dictionary.
  replace string data.key in file f_input by data.value in file f_output
  """
  try:
      fin=open(f_input,'r')
      fout=open(f_output,'w')
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.datased()'
      print error
      return False
  try:
      for line in fin.readlines():
          for key,value in data.items():
              newline = string.replace(line,str(key),str(value))
              fout.write(newline)
      fin.close()
      fout.close()
      return True
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.datased()'
      print error
      return False
##========================
##
##========================
def datasedarob(data,f_input,f_output):
  """
  Inputs: dictionary, input filename, output filename
  Same as datased(.,.,.) but replace only the key when its delimited by '@@'.
  replace string @@data.key@@ in file f_input by data.value in file f_output
  """
  try:
      fin=open(f_input,'r')
      fout=open(f_output,'w')
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.datasedarob()'
      print error
      return False
  try:
      for line in fin.readlines():
          newline = line
          for key,value in data.items():
              newline = string.replace(newline,'@@'+str(key)+'@@',str(value))
          fout.write(newline)
      fin.close()
      fout.close()
      return True
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_datadic.datasedarob()'
      print error
      return False
