 PyToolbox. VERSION 0.0.2
 Various useful functions for easy python scripting
 Don't forget to update your PYTHONPATH 
export PYTHONPATH=$PYTHONPATH:pytoolbox_path

+--------------------+
| List of functions: |
| pytb_damas         |
+--------------------+
manipulate damas databases (files *_i.sda)

- rmdam(damas):
    remove a damas database

- cpdam(damasin,damasout):
    copy a damas database

- mvdam(damasin,damasout):
    move a damas database

- cleandam():
    remove all damas databases in the current directory

+--------------------+
| List of functions: |
| pytb_datadic       |
+--------------------+
Basic commands for python dictionary.
Useful to create and manipulate config files (line format = 'key   value') from data dictionary.

- printdic(dico):
    print a dictionnary in the command line

- catdic(master,slave):
    cat 2 dicitionary, the master one taking over the slave one
    return the master dictionary

- writedic(dico,file,name):
    Write backup of a dictionary into a file (python format)

- read_datafile(datafile):
  Read a config file, line format = 'key    value'
  and return the corresponding data as a dictionary

- write_datafile(data,datafile):
  Write a config file, line format = 'key value' from a data dictionary

- append_datafile(data,datafile):
  Write a config file in append mode, line format = 'key value' from a dictionary

- datased(data,f_input,f_output):
  Enables to perform multiples sed in one command.
  All the strings to be replaced are the keys of the dictionary.
  They are replaced by their correspondinf value in the dictionary.
  replace string data.key in file f_input by data.value in file f_output

- datasedarob(data,f_input,f_output):
  Inputs: dictionary, input filename, output filename
  Same as datased(.,.,.) but replace only the key when its delimited by '@@'.
  replace string @@data.key@@ in file f_input by data.value in file f_output


+--------------------+
| List of functions: |
| pytb_optfiles      |
+--------------------+
Manipulate optalia files

- read_dynopt(filename):
    read a dynamic optimization file.
    manage concurent access to the file.

- write_dynopt(filename, ncalc_done, ncalc_asked, taskopt, n_var, n_fobj, n_fcons, varprefix, funcprefix, dfuncprefix, funcact, dfuncact):
    write a dynamic optimization file.
    manage concurent access to the file.

- read_var(f_var):
    read a variable file.
    manage concurent access to the file.

- write_var(n_var,var,f_var):
    write a variable file.
    manage concurent access to the file.

- read_func(f_func):
    read a function file.
    manage concurent access to the file.

- write_func(n_fobj,nfcons,funcact,func,f_func):
    write a function file.
    manage concurent access to the file.

- read_dfunc(f_dfunc):
    read a function function derivatives file.
    manage concurent access to the file.

- write_dfunc(n_var,n_fobj,nfcons,dfuncact,dfunc,f_dfunc):
    write a function function derivatives file.
    manage concurent access to the file.

- read_dfobj(f_dfobj):
    read a funcgrad file.
    manage concurent access to the file.

- write_dfobj(n_var,dfobj,f_dfobj):
    read a funcgrad file.
    manage concurent access to the file.

- read_fobjpost(n_fobj,n_fcons,f_func):
    read the objective function values in an optalia post log file.
    manage concurent access to the file.

- read_fobjpost_mp(n_fobj,n_fcons,n_design,f_func):
    read the objective function values in an optalia post log file.
    manage concurent access to the file.
    manage multipoint computations

- read_funcgrad(f_funcgrad):
    read a funcgrad file.
    manage concurent access to the file.

- write_funcgrad(n_var,n_func,dfunc,f_funcgrad):
    write a funcgrad file.
    manage concurent access to the file.

- var2samples(fn_varprefix,ns_start,ns_end,fn_samples):
    Convert ns variable files into one samples file.

- samples2var(fn_samples,n_var,ns_start,ns_end,fn_varprefix):
    Convert one samples file into n variable files.

- varfunc2samples(fn_varprefix,fn_funcprefix,ns_start,ns_end,fn_samplesprefix):
    Convert ns variable files + ns function files into n_func samples file.

- samples2varfunc(fn_samples,n_var,n_fobj,n_fcons,ns_start,ns_end,fn_varprefix,fn_funcprefix):
    Convert one samples file into n variable files and n function files.

- vardfunc2samples(fn_varprefix,fn_funcprefix,fn_dfuncprefix,ns_start,ns_end,fn_samplesprefix):
    Convert ns variable files + ns function files + ns function gradient files into n_func samples file.

- samples2vardfunc(fn_samples,n_var,n_fobj,n_fcons,ns_start,ns_end,fn_varprefix,fn_funcprefix,fn_dfuncprefix):
    Convert one samples file into n variable files and n function files.

- tpheader(mode,ni,nj):
    Tecplot header generator.

- min_optihist(n_var,f_optihist):
    read a opthistgraph file and return min value.
    column format like: # ncalc niter var(n_var) Fobj

- min_samples(n_var,ns,f_samples):
    read a samples file and return min value
    column format like: # var(n_var) Fobj

- read_localjobid():
    read the jobid from an optalia local.log file.
    manage concurent access to the file.

- read_localendmsg():
    read in the current directory the status in the file OPTALIA_END_MSG_*
    manage concurent access to the file.

- datajob_update(fn_datajob,newline):
    Add a new calculation in a job database file.


+--------------------+
| List of functions: |
| pytb_queue         |
+--------------------+
Various functions to use PBS or LSF commands in a python script.

- choose_els(cfdsubmit,nproc,nprocmax):
  only for airbus...
  Verify current nproc asked in the queues
  cfdsubmit must be in ['edm' , 'optalia']
  nproc an integer
  nprocmax an integer

- listchoose_els(cfdsubmit,nproc,nprocmax,list_q):
  only for airbus...
  Verify current nproc asked in the queues
  cfdsubmit must be in ['edm' , 'optalia']
  nproc an integer
  nprocmax an integer
  list_q is a list of string containing possible running queues

- lsf_runproc(queue):
  Return number of LSF processor on the queue used by Running jobs

- lsf_userproc():
  Return total number of proc required by user on all servers

- lsf_allusrpend(queue):
  Return number of all users pending jobs on a queue

- lsf_freenodes(server):
  Return number of LSF free nodes on the server

- pbs_freenodes():
  Return number of PBS free proc on the current server

- pbs_userproc():
  Return total number of proc required by user on current server

- pbs_userjobs():
  Return total number of jobs required by user on current server

- lsf_status(jobid):
  Return LSF job status in ['PEND','RUN','DONE','EXIT','UNKOWN']

- pbs_status(jobid):
  Return PBS job status in ['PEND','RUN','DONE','EXIT','UNKOWN']

- pbs_waitjob(jobid):
  input: job ID
  Wait until the specified job has a status different than 'RUN' or 'PEND'

- kali_wait(nproc,nprocmax):
  only for cerfacs...
  Inputs: nproc (integer), nprocmax (integer)
  You planned to submit a job requiring nproc processors.
  You don't want the total number of processors you are requiring in all your jobs (running or pending) to exceed nprocmax.
  This function will wait for until this is verified.

+--------------------+
| List of functions: |
| pytb_various       |
+--------------------+
Lots of functions to execute commands directly in a terminal or using rsh, ssh or even a job (sge,pbs,lsf).
Be careful, the shell commands are in KSH format
And the file ~/.profile should exists.

- openf2(filename,mode):
    Open the file filename in a given mode.
    Manage concurrent access.
    return the file identifier.

- readlines2(filename):
    Open the file filename in read mode.
    Manage concurrent access.
    Execute a standard readlines().
    return the list of lines.

- writelines2(filename,lines):
    Open the file filename in write mode.
    Manage concurrent access.
    Write the list of lines in the file.

- appendlines2(filename,lines):
    Open the file filename in append mode.
    Manage concurrent access.
    Write the list of lines in the file.

- appendfiles(forg,filetoappend):
    Append the text of filetoappend into the file forg.

- execshell(shell):
    Execute a shell command, return False if status!=0
    pytb.pytb_various.execshell(shell)

- xshell(shell):
    Execute a shell command, exit if status!=0
    pytb.pytb_various.xshell(shell)

- retrievestat_rsh(output):
  Retrieve a shell status from a file.
  If the file contains the string 'RSHOK' then status=0

- execshell_rsh(shell,host):
    Execute a shell command on a remote host via rsh, return False if status!=0
    pytb.pytb_various.execshell_rsh(shell,host)

- xshell_rsh(shell,host):
    Execute a shell command on a remote host via rsh, exit if status!=0
    pytb.pytb_various.xshell_rsh(shell,host)

- execshell_ssh(shell,host):
    Execute a shell command on a remote host via ssh, return False if status!=0
    pytb.pytb_various.execshell_ssh(shell,host)

- xshell_ssh(shell,host):
    Execute a shell command on a remote host via ssh, exit if status!=0
    pytb.pytb_various.xshell_ssh(shell,host)

- execshell_ssh_nfs2home(shell,host):
    only for cerfacs...
    Execute a shell command on a remote host via ssh, return False if status!=0
    You are working on kali (the path begins with /nfs/) and the command is executed on local computer (the path begins with /home/)
    pytb.pytb_various.execshell_ssh(shell,host)

- xshell_ssh_nfs2home(shell,host):
    only for cerfacs...
    Execute a shell command on a remote host via ssh, exit if status!=0
    You are working on kali (the path begins with /nfs/) and the command is executed on local computer (the path begins with /home/)
    pytb.pytb_various.xshell_ssh(shell,host)

- pbs_subshell(f_job,nproc,shell):
    Execute a shell command as a pbs job on the current server
    pytb.pytb_various.pbs_subshell(f_job,nproc,shell)
    f_job = filename for the job file

- lsf_subshell(f_job,queue,nproc,shell):
    Execute a shell command as a LSF job on the specified queue
    pytb.pytb_various.lsf_subshell(f_job,queue,nproc,shell)
    f_job = filename for the job file

- sge_subshell(f_job,shell):
    Execute a shell command as a sge job
    pytb.pytb_various.sge_subshell(f_job,shell)
    f_job = filename for the job file

- sge_rshshell(f_job,shell):
    Execute a shell command as a sge qrsh
    pytb.pytb_various.sge_rshshell(f_job,shell)
    f_job = filename for the job file

- copytree(src, dst, symlinks=False):
    Like the shutil.copytree except mkdir commands have no error
    if directories exist.
    Recursively copy a directory tree using copy2().
    If exception(s) occur, an Error is raised with a list of reasons.
    If the optional symlinks flag is true, symbolic links in the
    source tree result in symbolic links in the destination tree; if
    it is false, the contents of the files pointed to by symbolic
    links are copied.

- sedg(str2find,str2add,f_input,f_output):
  Global sed
  replace string str2find in file f_input by str2add in file f_output

- gen_tmpstring(signature):
  Retrun a pseudo random string.
  Useful to name temporary files.

- primes(n):
  Fast prime number list generator using sieve algorithm.
  Return the list of prime numbers <= n


+--------------------+
| List of functions: |
| pytb_vector        |
+--------------------+
basic tools for vectors (list of float/int)

- convert_str(vect):
    Get a vector and return the values it contains in a single string

- printscr(vect):
    print a vector in a single line

- vect_norm2(vect):
    Get a vector and return its norm**2

+--------+
| Usage: |
+--------+

[optalia@courlis]$  echo $PYTHONPATH
/home/optalia_wkdir/python/pytoolbox/pytoolbox_0.0.2:/home/mdoaero/bin/Linux2.6.5-1.358/PyXML-0.8.4:/home/mdoaero/bin/Pmw/Pmw_1_2/lib:/home/optalia_wkdir/python/pytoolbox/pytoolbox_0.0.2
[optalia@courlis]$ python
Python 2.3.3 (#1, May  7 2004, 10:31:40)
Type "help", "copyright", "credits" or "license" for more information.
>>> import pytb
>>> shell='ls'
>>> pytb.pytb_various.xshell(shell)
'__init__.py\n__init__.pyc\npytb_damas.py\npytb_damas.pyc\npytb_datadic.py\npytb_datadic.pyc\npytb_optfiles.py\npytb_optfiles.pyc\npytb_queue.py\npytb_queue.pyc\npytb_various.py\npytb_various.pyc\npytb_vector.py\npytb_vector.pyc\nreadme.txt'

#
#
#
#

mx61> export PYTHONPATH=$PYTHONPATH:/home/optalia/pytoolbox/pytoolbox_0.0.2
mx61> python
       
>>> import pytb

>>> pytb.pytb_queue.choose_els('optalia',4,60)
. Submitting on ccbatch
CLASS     els_ccd

'CLASS     els_ccd\n'


>>> pytb.pytb_queue.choose_els('edm',4,60)
. Submitting on ccbatch
submit job -nproc 4 -server ccbatch -time 1000000 -mode run -class els_ccd

'submit job -nproc 4 -server ccbatch -time 1000000 -mode run -class els_ccd\n'

>>> pytb.pytb_various.execshell('ls')
__init__.py        pytb_damas.pyc     pytb_optfiles.py   pytb_queue.pyc
__init__.pyc       pytb_datadic.py    pytb_optfiles.pyc  pytb_various.py
pytb_damas.py      pytb_datadic.pyc   pytb_queue.py      pytb_various.pyc


>>> data={}
>>> data['TOTO']=-1
>>> pytb.pytb_datadic.datasedarob(data,'fin','fout')
## avec un fichier d'entrée contenant par exemple:
## mx61> cat fin
## KEY1      1
## TOTO      @@TOTO@@
## KEY2      2
## on obtient un ficher de sortie fout:
## mx61> cat fin
## KEY1      1
## TOTO      -1
## KEY2      2
