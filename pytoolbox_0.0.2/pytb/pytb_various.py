#=========================================================================================
"""
 pytb_various.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.2'
__author__='J.Laurenceau/Airbus France , R.Boisard/Altran'
__history__=\
"""
_ Creation date : mar 2007
_ various useful functions
Lots of functions to execute commands directly in a terminal or using rsh, ssh or even a job (sge,pbs,lsf).
Be careful, the shell commands are in KSH format
And the file ~/.profile should exists.
"""
#=========================================================================================

import commands,os,re,string,sys,shutil,time
from time import time, localtime, strftime, sleep
import pytb_queue

##========================
##
##========================
def openf2(filename,mode):
    """
    Open the file filename in a given mode.
    Manage concurrent access.
    return the file identifier.
    """
    if not os.path.isfile(filename):
        print 'ERROR !! in pytoolbox : pytb_various.openf2()'
        print 'file does not exist '+filename
        sys.exit(9999)
    ok = 1
    while ok != 0 and ok < 30  :
        try:
            fid = open(filename,mode)
            ok = 0
        except:
            ok = ok +1
            sleep(10)
    if ok != 0:
        print 'ERROR !! in pytoolbox : pytb_various.openf2()'
        print 'file = '+filename
        sys.exit(9999)
    else:
        return fid
##========================
##
##========================
def readlines2(filename):
    """
    Open the file filename in read mode.
    Manage concurrent access.
    Execute a standard readlines().
    return the list of lines.
    """
#    filename = os.path.abspath(filename)
    if not os.path.isfile(filename):
        print 'ERROR !! in pytoolbox : pytb_various.readlines2()'
        print 'file does not exist '+filename
        sys.exit(9999)
    ok = 1
    while ok != 0 and ok < 30  :
        try:
            fid = open(filename,'r')
            lines = fid.readlines()
            fid.close()
            ok = 0
        except:
            ok = ok +1
            sleep(10)
    if ok != 0:
        print 'ERROR !! in pytoolbox : pytb_various.readlines2()'
        print 'file = '+filename
        sys.exit(9999)
    else:
        return lines
##========================
##
##========================
def writelines2(filename,lines):
    """
    Open the file filename in write mode.
    Manage concurrent access.
    Write the list of lines in the file.
    """
    ok = 1
    while ok != 0 and ok < 30 :
        try:
            fid = open(filename,'w')
            for line in lines :
                fid.write(line)
            fid.close()
            ok = 0
        except:
            ok = ok +1
            sleep(10)
    if ok != 0:
        print 'ERROR !! in pytoolbox : pytb_various.writelines2()'
        print 'file = '+filename
        sys.exit(9999)
##========================
##
##========================
def appendlines2(filename,lines):
    """
    Open the file filename in append mode.
    Manage concurrent access.
    Write the list of lines in the file.
    """
    if not os.path.isfile(filename):
        print 'ERROR !! in pytoolbox : pytb_various.appendlines2()'
        print 'file does not exist '+filename
        sys.exit(9999)
    ok = 1
    while ok != 0 and ok < 30 :
        try:
            fid = open(filename,'a')
            for line in lines :
                fid.write(line)
            fid.close()
            ok = 0
        except:
            ok = ok +1
            sleep(10)
    if ok != 0:
        print 'ERROR !! in pytoolbox : pytb_various.appendlines2()'
        print 'file = '+filename
        sys.exit(9999)
##========================
##
##========================
def appendfiles(forg,filetoappend):
    """
    Append the text of filetoappend into the file forg.
    """
    try:
        fappend=open(filetoappend,'r')
        text=fappend.readlines()
        fappend.close()
        forg.writelines(text)
        return True
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_various.appendfiles()'
        print error
        return False
##========================
##
##========================
def execshell(shell):
    """
    Execute a shell command, return False if status!=0
    pytb.pytb_various.execshell(shell)
    """
    status,output=commands.getstatusoutput(str(shell))
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.execshell()'
        print 'shell command: '+str(shell)
        print 'output status: '+str(status)
        print 'output       : '+str(output)
        return False
    else:
        print str(output)
        return True
##========================
##
##========================
def xshell(shell):
    """
    Execute a shell command, exit if status!=0
    pytb.pytb_various.xshell(shell)
    """
    status,output=commands.getstatusoutput(str(shell))
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.xshell()'
        print 'output       : '+str(output)
        print 'shell command: '+str(shell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def retrievestat_rsh(output):
  """
  Retrieve a shell status from a file.
  If the file contains the string 'RSHOK' then status=0
  """
  try:
    if string.find(str(output),'RSHOK') != -1 :
        status = 0
    else:
        status = 9999
    return status
  except Exception,error:
    print 'function : retrievestat_rsh'
    print error
    return 9999
##========================
##
##========================
def execshell_rsh(shell,host):
    """
    Execute a shell command on a remote host via rsh, return False if status!=0
    pytb.pytb_various.execshell_rsh(shell,host)
    """
    rsh_shell = 'rsh -n '+str(host)+' ". /etc/profile;. ~/.profile;cd '+str(os.getcwd())+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(rsh_shell)
    status_rsh = retrievestat_rsh(output)
    if status != 0 or status_rsh != 0 :
        print 'ERROR !! in pytoolbox : pytb_various.execshell_rsh()'
        print 'shell command    : '+str(shell)
        print 'output status    : '+str(status)
        print 'rsh output status: '+str(status_rsh)
        print 'rsh output       : '+str(output)
        return False
    else:
        print str(output)
        return True
##========================
##
##========================
def xshell_rsh(shell,host):
    """
    Execute a shell command on a remote host via rsh, exit if status!=0
    pytb.pytb_various.xshell_rsh(shell,host)
    """
    rsh_shell = 'rsh -n '+str(host)+' ". /etc/profile;. ~/.profile;cd '+str(os.getcwd())+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(rsh_shell)
    status_rsh = retrievestat_rsh(output)
    if status != 0 or status_rsh != 0 :
        print 'ERROR !! in pytoolbox : pytb_various.xshell_rsh()'
        print 'rsh output    : '+str(output)
        print 'shell command : '+str(shell)
        if status != 0 :
            sys.exit(status)
        else:
            sys.exit(status_rsh)
    else:
        return str(output)
##========================
##
##========================
def execshell_ssh(shell,host):
    """
    Execute a shell command on a remote host via ssh, return False if status!=0
    pytb.pytb_various.execshell_ssh(shell,host)
    """
    ssh_shell = 'ssh '+str(host)+' ". /etc/profile;. ~/.profile;cd '+str(os.getcwd())+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(ssh_shell)
    if status != 0 :
        print 'ERROR !! in pytoolbox : pytb_various.execshell_ssh()'
        print 'shell command    : '+str(shell)
        print 'output status    : '+str(status)
        print 'ssh output       : '+str(output)
        return False
    else:
        print str(output)
        return True
##========================
##
##========================
def xshell_ssh(shell,host):
    """
    Execute a shell command on a remote host via ssh, exit if status!=0
    pytb.pytb_various.xshell_ssh(shell,host)
    """
    ssh_shell = 'ssh -n '+str(host)+' ". /etc/profile;. ~/.profile;cd '+str(os.getcwd())+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(ssh_shell)
    if status != 0:
        print 'ERROR !! in pytoolbox : pytb_various.xshell_ssh()'
        print 'ssh output    : '+str(output)
        print 'shell command : '+str(shell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def execshell_ssh_nfs2home(shell,host):
    """
    only for cerfacs...
    Execute a shell command on a remote host via ssh, return False if status!=0
    You are working on kali (the path begins with /nfs/) and the command is executed on local computer (the path begins with /home/)
    pytb.pytb_various.execshell_ssh(shell,host)
    """
    d_work = str(os.getcwd())
    d_work = string.replace(d_work,'/nfs/','/home/')
    ssh_shell = 'ssh '+str(host)+' ". /etc/profile;. ~/.profile;cd '+d_work+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(ssh_shell)
    if status != 0 :
        print 'ERROR !! in pytoolbox : pytb_various.execshell_ssh()'
        print 'shell command    : '+str(shell)
        print 'output status    : '+str(status)
        print 'ssh output       : '+str(output)
        return False
    else:
        print str(output)
        return True
##========================
##
##========================
def xshell_ssh_nfs2home(shell,host):
    """
    only for cerfacs...
    Execute a shell command on a remote host via ssh, exit if status!=0
    You are working on kali (the path begins with /nfs/) and the command is executed on local computer (the path begins with /home/)
    pytb.pytb_various.xshell_ssh(shell,host)
    """
    d_work = str(os.getcwd())
    d_work = string.replace(d_work,'/nfs/','/home/')
    ssh_shell = 'ssh -n '+str(host)+' ". /etc/profile;. ~/.profile;cd '+d_work+';'+str(shell)+' && echo RSHOK'+'"'
    status,output=commands.getstatusoutput(ssh_shell)
    if status != 0:
        print 'ERROR !! in pytoolbox : pytb_various.xshell_ssh()'
        print 'ssh output    : '+str(output)
        print 'shell command : '+str(shell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def pbs_subshell(f_job,queue,nproc,shell):
    """
    Execute a shell command as a pbs job on the current server
    pytb.pytb_various.pbs_subshell(f_job,nproc,shell)
    f_job = filename for the job file
    """
    status = 9999
    try:
        if queue not in ['test']:
            queue = 'NONE'
        d_work = str(os.getcwd())
        fid = open(f_job,'w')
        if queue not in ['test']:
            fid.write('#PBS -l walltime=24:00:00'+'\n')
        nnodes = int(nproc/2)+2*(float(nproc)/float(2)-int(nproc/2))
        if nproc == 1:
            fid.write('#PBS -l nodes=1:ppn=1'+'\n')
        else:
            fid.write('#PBS -l nodes='+str(nnodes)+':ppn=2'+'\n')
        fid.write('#PBS -j oe'+'\n')
        fid.write('#PBS -S /bin/ksh'+'\n')
        fid.write('#PBS -N pbs_subshell'+'\n')
##        fid.write('set -x'+'\n')
        fid.write('echo $PBS_JOBID'+'\n')
        fid.write('echo "BEGIN Job"'+'\n')
        fid.write('date\n')
        if os.path.isfile('/var/opt/pce/wlm/settings.sh'):
            fid.write('. /var/opt/pce/wlm/settings.sh'+'\n')
        fid.write('. ./.profile'+'\n')
        fid.write('export NPROC='+str(nproc)+'\n')
        fid.write('cd '+str(d_work)+'\n')
        fid.write('\n')
        fid.write('echo $PBS_JOBID > jobid'+'\n')
        if nproc == 1:
            fid.write(shell+'\n')
        elif string.find(os.environ['HOSTNAME'],'kali') != -1:
            fid.write('mpiexec -n '+str(nproc)+' $XD1LAUNCHER '+shell+'\n')
        else:
            fid.write('mpirun -x PYTHONPATH -np '+str(nproc)+' '+shell+'\n')
        fid.write('\n')
        fid.write('echo "END Job"'+'\n')
        fid.write('date\n')
        fid.write('\n')
        fid.close()
        os.chmod(f_job,0755)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_various.pbs_subshell()'
        print error
        sys.exit(status)
    if queue in ['test']:
        submitshell = 'qsub -q '+str(queue)+' '+f_job
    else:
        submitshell = 'qsub '+f_job
    status,output = commands.getstatusoutput(submitshell)
    jobid = str(output)
    pytb_queue.pbs_waitjob(jobid)
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.pbs_subshell()'
        print 'output       : '+str(output)
        print 'shell command: '+str(submitshell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def lsf_subshell(f_job,queue,nproc,shell):
    """
    Execute a shell command as a LSF job on the specified queue
    pytb.pytb_various.lsf_subshell(f_job,queue,nproc,shell)
    f_job = filename for the job file
    """
    status = 9999
    try:
        d_work = str(os.getcwd())
        fid = open(f_job,'w')
        fid.write('#!/bin/ksh'+'\n')
        fid.write('#BSUB -q '+str(queue)+'\n')
        fid.write('#BSUB -n '+str(nproc)+'\n')
        fid.write('#BSUB -e /work/jobrem_'+f_job+' -o /work/jobrem_'+f_job+'\n')
        fid.write('#BSUB -f '+d_work+'/'+f_job+'.log < /work/jobrem_'+f_job+'\n')
        fid.write('#BSUB -L /bin/ksh'+'\n')
        fid.write('#BSUB -J lsf_subshell'+'\n')
        fid.write('#BSUB -sp 10'+'\n')
##        fid.write('set -x'+'\n')
        fid.write('echo "BEGIN Job"'+'\n')
        fid.write('date\n')
        fid.write('. /etc/profile'+'\n')
        fid.write('. ~/.profile'+'\n')
        fid.write('export NPROC='+str(nproc)+'\n')
        fid.write('cd '+str(d_work)+'\n')
        fid.write('\n')
        if nproc == 1:
            fid.write(shell+'\n')
        else:
            fid.write('mpirun -n '+str(nproc)+' '+shell+'\n')
        fid.write('\n')
        fid.write('echo "END Job"'+'\n')
        fid.write('date\n')
        fid.write('\n')
        fid.close()
        os.chmod(f_job,0755)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_various.lsf_subshell()'
        print error
        sys.exit(status)
    submitshell = 'bsub '+f_job
    status,output = commands.getstatusoutput(submitshell)
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.lsf_subshell()'
        print 'output       : '+str(output)
        print 'shell command: '+str(submitshell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def sge_subshell(f_job,shell):
    """
    Execute a shell command as a sge job
    pytb.pytb_various.sge_subshell(f_job,shell)
    f_job = filename for the job file
    """
    status = 9999
    try:
        d_work = str(os.getcwd())
        fid = open(f_job,'w')
        fid.write('#!/bin/ksh'+'\n')
        fid.write('#$ -S /bin/ksh'+'\n')
        fid.write('#$ -N sge_subshell'+'\n')
        fid.write('#$ -o '+str(d_work)+'\n')
        fid.write('#$ -e '+str(d_work)+'\n')
        fid.write('echo "BEGIN SGE Job ; machine $(uname -n)"'+'\n')
        fid.write('date\n')
        fid.write('. ~/.profile'+'\n')
##        fid.write('set -x'+'\n')
        fid.write('cd '+str(d_work)+'\n')
        fid.write(shell+'\n')
        fid.write('echo "END SGE Job"'+'\n')
        fid.write('date\n')
        fid.write('\n')
        fid.close()
        os.chmod(f_job,0755)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_various.sge_subshell()'
        print error
        sys.exit(status)
    submitshell = 'qsub '+f_job
    status,output = commands.getstatusoutput(submitshell)
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.sge_subshell()'
        print 'output       : '+str(output)
        print 'shell command: '+str(submitshell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def sge_rshshell(f_job,shell):
    """
    Execute a shell command as a sge qrsh
    pytb.pytb_various.sge_rshshell(f_job,shell)
    f_job = filename for the job file
    """
    status = 9999
    try:
        d_work = str(os.getcwd())
        fid = open(f_job,'w')
        fid.write('#!/bin/ksh'+'\n')
        fid.write('#$ -S /bin/ksh'+'\n')
        fid.write('#$ -N sge_rshshell'+'\n')
        fid.write('#$ -o '+str(d_work)+'\n')
        fid.write('#$ -e '+str(d_work)+'\n')
        fid.write('echo "BEGIN SGE Job ; machine $(uname -n)"'+'\n')
        fid.write('date\n')
        fid.write('. ~/.profile'+'\n')
##        fid.write('set -x'+'\n')
        fid.write('cd '+str(d_work)+'\n')
        fid.write(shell+'\n')
        fid.write('echo "END SGE Job"'+'\n')
        fid.write('date\n')
        fid.write('\n')
        fid.close()
        os.chmod(f_job,0755)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_various.sge_rshshell()'
        print error
        sys.exit(status)
    submitshell = 'qrsh '+f_job
    status,output = commands.getstatusoutput(submitshell)
    if status!=0:
        print 'ERROR !! in pytoolbox : pytb_various.sge_rshshell()'
        print 'output       : '+str(output)
        print 'shell command: '+str(submitshell)
        sys.exit(status)
    else:
        return str(output)
##========================
##
##========================
def copytree(src, dst, symlinks=False):
    """
    Like the shutil.copytree except mkdir commands have no error
    if directories exist.

    Recursively copy a directory tree using copy2().

    If exception(s) occur, an Error is raised with a list of reasons.

    If the optional symlinks flag is true, symbolic links in the
    source tree result in symbolic links in the destination tree; if
    it is false, the contents of the files pointed to by symbolic
    links are copied.
    """
    names = os.listdir(src)
    try:
        os.mkdir(dst)
    except:
        pass
    errors = []
    for name in names:
        srcname = os.path.join(src, name)
        dstname = os.path.join(dst, name)
        try:
            if symlinks and os.path.islink(srcname):
                linkto = os.readlink(srcname)
                os.symlink(linkto, dstname)
            elif os.path.isdir(srcname):
                copytree(srcname, dstname, symlinks)
            else:
                shutil.copy2(srcname, dstname)
            # XXX What about devices, sockets etc.?
        except (IOError, os.error), why:
            errors.append((srcname, dstname, why))
    if errors:
        raise Error, errors
##========================
##
##========================
def sedg(str2find,str2add,f_input,f_output):
  """
  Global sed
  replace string str2find in file f_input by str2add in file f_output
  """
  str2find = str(str2find)
  str2add = str(str2add)
  try:
      fin=open(f_input,'r')
      lines = fin.readlines()
      fin.close()
  except Exception,error:
      print 'ERROR !! in pytoolbox : pytb_various.sedg()'
      print error
      return False
  try:
      fout=open(f_output,'w')
      for line in lines:
          newline = string.replace(line,str2find,str2add)
          fout.write(newline)
      fout.close()
      return True
  except Exception,error :
      print 'ERROR !! in pytoolbox : pytb_various.sedg()'
      print error
      return False
##========================
##
##========================
def gen_tmpstring(signature):
  """
  Retrun a pseudo random string.
  Useful to name temporary files.
  """
  username = 'pytoolbox'
  try:
      username = os.environ['USER']
  except:
      username = str(os.getlogin())
  if len(str(signature)) > 0:
      suftmp = str(signature)+'-tmp_'+username+'_'+strftime('%d%m%Y_%H%M%S', localtime())
  else:
      suftmp = 'tmp_'+username+'_'+strftime('%d%m%Y_%H%M%S', localtime())
  return str(suftmp)
##========================
##
##========================
def primes(n):
  """
  Fast prime number list generator using sieve algorithm.
  Return the list of prime numbers <= n
  """
  if n==2:
      return [2]
  elif n<2:
      return []
  s=range(3,n+1,2)
  mroot = n ** 0.5
  half=(n+1)/2-1
  i=0
  m=3
  while m <= mroot:
      if s[i]:
          j=(m*m-3)/2
          s[j]=0
          while j<half:
              s[j]=0
              j+=m
      i=i+1
      m=2*i+3
  return [2]+[x for x in s if x]
##========================
##
##========================
