#=========================================================================================
"""
 pytb_queue.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.2'
__author__='J.Laurenceau/Airbus France'
__history__=\
"""
_ Creation date : mar 2007
Various functions to use PBS or LSF commands in a python script.
_ Choose a queue return a line to cat in your optalia/edm launch file
_ examples:
>>> import pytb
>>> pytb.pytb_queue.choose_els('optalia',4,60)
. Submitting on ccbatch
CLASS     els_ccd

'CLASS     els_ccd\n'
>>> pytb.pytb_queue.choose_els('edm',4,60)
. Submitting on ccbatch
submit job -nproc 4 -server ccbatch -time 1000000 -mode run -class els_ccd

'submit job -nproc 4 -server ccbatch -time 1000000 -mode run -class els_ccd\n'
"""
#=========================================================================================

import commands,os,re,string,sys,shutil,time
from time import time, localtime, strftime, sleep

##========================
##
##========================
def choose_els(cfdsubmit,nproc,nprocmax):
  """
  only for airbus...
  Verify current nproc asked in the queues
  cfdsubmit must be in ['edm' , 'optalia']
  nproc an integer
  nprocmax an integer
  """
  if cfdsubmit not in ['edm' , 'EDM' , 'optalia' , 'OPTALIA' ]:
    cfdsubmit = 'optalia'
  nproc = int(nproc)
  nprocmax = int(nprocmax)
##
  try:
    username = os.environ['USER']
  except:
    username = str(os.getlogin())
##
  icount = 0
  nproctot = nprocmax+1
  while nproctot > nprocmax or nproctot < 0:
    if icount == 1:
      print 'You reached nprocmax '+str(nprocmax)+' limit, script waiting ',
    if icount > 0:
      sleep(20)
      print '.',
    nproctot = lsf_userproc()
    icount = icount +1
  if icount > 1 :
    print ' '
##
  list_q = ['els_cdd' , 'els_cad']
##
##  list from /etc/passwd on 20 march 2007
##
  ccbatch_userlist = ['to21887' , 'to19302' , 'to23995' , 'to21768' , 'to31790' , 'to45074' , 'to72585' , 'to29037' , 'to75315' , 'st02374' , 'to29085' , 'to30571' , 'to18204' , 'to21585' , 'to28945' , 'to28010' , 'to29960' , 'to17277' , 'to39751' , 'to23996' , 'to24144' , 'to67257' , 'to29910' , 'to31961' , 'to13384' , 'to20604' , 'to21769' , 'to34357' , 'to29776' , 'to38084' , 'to45359' , 'to50125' , 'to50139' , 'to32288' , 'to23945' , 'to72659' , 'to22716' , 'to72698' , 'to72655' , 'to67905' , 'to67916' , 'to67923' , 'to67926' , 'to72703' , 'to21097' , 'to38133' , 'to15132' , 'to81565' , 'to67904' , 'to23049' , 'to30934' , 'to38600' , 'to50418' , 'to24147' , 'to38776' , 'to29337' , 'to26189' , 'to31791' , 'to75349' , 'to72078' , 'to40195' , 'to83004' , 'to75577' , 'to83055' , 'to80787' , 'to81153' , 'to81164' , 'st17969' , 'st13366' , 'to82998' , 'to81129' , 'to96665' , 'to28693' , 'to83112' , 'to81048' , 'to72160' , 'to76542' , 'to76589' , 'to76581' , 'to96946' , 'to76590' , 'to76588' , 'to76591' , 'to76598' , 'to76595' , 'to07185' , 'to90010' , 'to75338' , 'st00630' , 'st23022' , 'st13430' , 'st11258' , 'st06747' , 'st11168' , 'st01738' , 'st00192' , 'st01003' , 'st01011' , 'st02139' , 'st02374' , 'st39130' , 'st03853' , 'st01574' , 'st02701' , 'st13412' , 'st11551' , 'st02695' , 'st01575' , 'st05395' , 'st06676' , 'st01881' , 'to24144' , 'to13384' , 'st02564' , 'st04616' , 'st00128' , 'st00204' , 'st01891' , 'st07174' , 'st08695' , 'st03003' , 'st13409' , 'st11789' , 'st02228' , 'st00116' , 'st04189' , 'st26541' , 'st00153' , 'st05266' , 'st04286' , 'st04074' , 'st05120' , 'st02514' , 'st13613' , 'st11528' , 'st00835' , 'st11028' , 'to72078' , 'st06972' , 'st15335' , 'st15435' , 'st11025' , 'st17969' , 'st13366' , 'st17793' , 'st18751' , 'st14972' , 'st15544' , 'st18984' , 'st16477' , 'st15527' , 'st18341' , 'st16113' , 'st19781' , 'st08930' , 'st16482' , 'st21086' , 'st21087' , 'st21088' , 'st20606' , 'st21262' ]
  if username in ccbatch_userlist :
    list_q = list_q + ['els_ccd']
##
##   Retrieve queues informations
##
  sizeq = {}    ## size of the server
  nprocpn = {}  ## nb proc per nodes
  freeproc = {}
  pendproc = {}
  for q in list_q :
    if q in ['els_cad' , 'els_can' , 'els_cam' , 'els_camem'] :
      server = 'cabatch'
      nprocpn[q] = 2
      sizeq[q] = 66 * nprocpn[q]
    elif q in ['els_ccd' , 'els_ccm' , 'els_ccmem'] :
      server = 'ccbatch'
      nprocpn[q] = 2
      sizeq[q] = 140 * nprocpn[q]
    elif q in ['els_cdd' , 'els_cdm' , 'els_cdmem'] :
      server = 'cdbatch'
      nprocpn[q] = 2
      sizeq[q] = 210 * nprocpn[q]
    elif q in ['els_cfd' , 'els_cfm'] :
      server = 'cfbatch'
      nprocpn[q] = 4
      sizeq[q] = 192 * nprocpn[q]
##    freeproc[q] = sizeq[q] - lsf_runproc(q)
    freeproc[q] = lsf_freenodes(server) * nprocpn[q]
    pendproc[q] = float(lsf_allusrpend(q)) / float(sizeq[q]) *100.0
  print 'Ratio CPU pending : '+str(pendproc)
  print 'Nb CPU free : '+str(freeproc)
##
##   loop on all queues and choose the one with less pending proc or biggest size
##
  for q in list_q :
    if q == list_q[0] :
      queue = q
    elif pendproc[q] < pendproc[queue] :
      queue = q
    elif pendproc[q] == pendproc[queue] :
      if freeproc[q] > freeproc[queue] :
        queue = q
      elif freeproc[q] == freeproc[queue] :
        if sizeq[q] >= sizeq[queue] :
          queue = q
##
  if queue in ['els_cad' , 'els_can' , 'els_cam' , 'els_camem'] :
    server = 'cabatch'
  elif queue in ['els_ccd' , 'els_ccm' , 'els_ccmem'] :
    server = 'ccbatch'
  elif queue in ['els_cdd' , 'els_cdm' , 'els_cdmem'] :
    server = 'cdbatch'
  elif queue in ['els_cfd' , 'els_cfm'] :
    server = 'cfbatch'
##
  print 'Script pytb.pytb_queue.choose_els(...) chooses : '+str(server)
  if cfdsubmit in ['edm' , 'EDM'] :
    linequeue = 'submit job -nproc '+str(nproc)+' -server '+str(server)+' -time 1000000 -mode run -class '+str(queue)+'\n'
  else :
    linequeue = 'CLASS     '+str(queue)+'\n'
  print str(linequeue)
  return linequeue
##========================
##
##========================
def listchoose_els(cfdsubmit,nproc,nprocmax,list_q):
  """
  Verify current nproc asked in the queues
  cfdsubmit must be in ['edm' , 'optalia']
  nproc an integer
  nprocmax an integer
  list_q is a list of string containing possible running queues
  """
  if cfdsubmit not in ['edm' , 'EDM' , 'optalia' , 'OPTALIA' ]:
    cfdsubmit = 'optalia'
  nproc = int(nproc)
  nprocmax = int(nprocmax)
  if len(list_q) < 1 :
    print 'Warning ! incorrect list of possible queues'
    list_q = ['els_cdd']
##
  try:
    username = os.environ['USER']
  except:
    username = str(os.getlogin())
##
  icount = 0
  nproctot = nprocmax+1
  while nproctot > nprocmax or nproctot < 0:
    if icount == 1:
      print 'You reached nprocmax '+str(nprocmax)+' limit, script waiting ',
    if icount > 0:
      sleep(20)
      print '.',
    nproctot = lsf_userproc()
    icount = icount +1
  if icount > 1 :
    print ' '
##
##   Retrieve queues informations
##
  sizeq = {}    ## size of the server
  nprocpn = {}  ## nb proc per nodes
  freeproc = {}
  pendproc = {}
  for q in list_q :
    if q in ['els_cad' , 'els_can' , 'els_cam' , 'els_camem'] :
      server = 'cabatch'
      nprocpn[q] = 2
      sizeq[q] = 66 * nprocpn[q]
    elif q in ['els_ccd' , 'els_ccm' , 'els_ccmem'] :
      server = 'ccbatch'
      nprocpn[q] = 2
      sizeq[q] = 140 * nprocpn[q]
    elif q in ['els_cdd' , 'els_cdm' , 'els_cdmem'] :
      server = 'cdbatch'
      nprocpn[q] = 2
      sizeq[q] = 210 * nprocpn[q]
    elif q in ['els_cfd' , 'els_cfm'] :
      server = 'cfbatch'
      nprocpn[q] = 4
      sizeq[q] = 192 * nprocpn[q]
##    freeproc[q] = sizeq[q] - lsf_runproc(q)
    freeproc[q] = lsf_freenodes(server) * nprocpn[q]
    pendproc[q] = float(lsf_allusrpend(q)) / float(sizeq[q]) *100.0
  print 'Ratio CPU pending : '+str(pendproc)
  print 'Nb CPU free : '+str(freeproc)
##
##   loop on all queues and choose the one with less pending proc or biggest size
##
  for q in list_q :
    if q == list_q[0] :
      queue = q
    elif pendproc[q] < pendproc[queue] :
      queue = q
    elif pendproc[q] == pendproc[queue] :
      if freeproc[q] > freeproc[queue] :
        queue = q
      elif freeproc[q] == freeproc[queue] :
        if sizeq[q] >= sizeq[queue] :
          queue = q
##
  if queue in ['els_cad' , 'els_can' , 'els_cam' , 'els_camem'] :
    server = 'cabatch'
  elif queue in ['els_ccd' , 'els_ccm' , 'els_ccmem'] :
    server = 'ccbatch'
  elif queue in ['els_cdd' , 'els_cdm' , 'els_cdmem'] :
    server = 'cdbatch'
  elif queue in ['els_cfd' , 'els_cfm'] :
    server = 'cfbatch'
##
  print 'Script pytb.pytb_queue.listchoose_els(...) chooses : '+str(server)
  if cfdsubmit in ['edm' , 'EDM'] :
    linequeue = 'submit job -nproc '+str(nproc)+' -server '+str(server)+' -time 1000000 -mode run -class '+str(queue)+'\n'
  else :
    linequeue = 'CLASS     '+str(queue)+'\n'
  print str(linequeue)
  return linequeue
##========================
##
##========================
def lsf_runproc(queue):
  """
  Return number of LSF processor on the queue used by Running jobs
  """
  try:
    shell="bqueues | grep "+str(queue)
    shstat,shout=commands.getstatusoutput(shell)
    line=string.split(shout)
    return int(line[7])
  except:
    return 100000
##========================
##
##========================
def lsf_userproc():
  """
  Return total number of proc required by user on all servers
  """
  try:
    shell='busers | grep $USER'
    shstat,shout=commands.getstatusoutput(shell)
    if shstat != 0 :
      print 'ERROR !! '+shell
      print shout
      nproctot = -1
    else:
      line=string.split(shout)
      nproctot = int(line[3])
  except:
    nproctot = -1
  return nproctot
##========================
##
##========================
def lsf_allusrpend(queue):
  """
  Return number of all users pending jobs on a queue
  """
  try:
    shell="bqueues | grep "+str(queue)
    shstat,shout=commands.getstatusoutput(shell)
    line=string.split(shout)
    return int(line[8])
  except:
    return 100000
##========================
##
##========================
def lsf_freenodes(server):
  """
  Return number of LSF free nodes on the server
  """
  try:
    shell='bhosts '+str(server)+' | grep -c " ok"'
    shstat,shout=commands.getstatusoutput(shell)
    return int(shout)
  except:
    return -1
##========================
##
##========================
def pbs_freenodes():
  """
  Return number of PBS free proc on the current server
  """
  try:
    shell='pbsnodes -a | grep -c "state = free"'
    shstat,shout=commands.getstatusoutput(shell)
    return int(shout)
  except:
    return -1
##========================
##
##========================
def pbs_userproc():
  """
  Return total number of proc required by user on current server
  """
  try:
    try:
      username = os.environ['USER']
    except:
      username = str(os.getlogin())
    suftmp = 'tmp_'+username+'_'+str(os.getpid())+'_'+strftime('%d%m%Y_%H%M%S', localtime())
##
    file = 'nproc_'+str(suftmp)
    shell='qstat -a -u '+str(username)+' | grep '+str(username)+' > '+file
    shstat,shout=commands.getstatusoutput(shell)
##
    nproctot = 0
    f_nproc=open(file,'r')
    l_nproc=f_nproc.readlines()
    f_nproc.close()
    for i in range(0,len(l_nproc)):
      line=string.split(l_nproc[i])
      if str(line[9]) in ['R','Q','H','S','T','W']:
        nproctot = nproctot + int(line[6])
      
    os.remove(file)
##
  except:
    nproctot = -1
  return nproctot
##========================
##
##========================
def pbs_userjobs():
  """
  Return total number of jobs required by user on current server
  """
  try:
    try:
      username = os.environ['USER']
    except:
      username = str(os.getlogin())
    suftmp = 'tmp_'+username+'_'+str(os.getpid())+'_'+strftime('%d%m%Y_%H%M%S', localtime())
##
    njobs = 0
    
    shell='qstat -a -u '+str(username)+' | grep -c '+str(username)
    shstat,shout=commands.getstatusoutput(shell)
    if shstat==0:
      njobs = int(shout)
##
  except:
    njobs = -1
  return njobs
##========================
##
##========================
def lsf_status(jobid):
  """
  Return LSF job status in ['PEND','RUN','DONE','EXIT','UNKOWN']
  """
  try:
    shell='bjobs '+str(jobid)+' | grep "'+str(jobid)+' "'
    shstat,shout=commands.getstatusoutput(shell)
    line = string.split(shout)
    if line[0]=='Job' and string.find(shout,' is not found') != -1:
      status = 'UNKNOWN'
    elif shstat == 0:
      if line[2] in ['PEND','PSUSP','USUSP','SSUSP']:
        status = 'PEND'
      elif line[2] == 'RUN':
        status = 'RUN'
      elif line[2] == 'DONE':
        status = 'DONE'
      elif line[2] == 'EXIT':
        status = 'EXIT'
      else:
        status = 'UNKNOWN'
    else:
      status = False
    return status
  except Exception,error:
    return False
##========================
##
##========================
def pbs_status(jobid):
  """
  Return PBS job status in ['PEND','RUN','DONE','EXIT','UNKOWN']
  """
  try:
    shell='qstat -f '+str(jobid)
    shstat,shout=commands.getstatusoutput(shell)
    line = string.split(shout)
    if line[0]=='qstat:' and string.find(shout,' Unknown Job Id ') != -1:
      status = 'UNKNOWN'
    elif shstat == 0:
      pbs_state = '?'
      for i in range(0,len(line)):
        if line[i] == 'job_state':
          pbs_state = str(line[i+2])
      if pbs_state in ['Q','H','T']:
        status = 'PEND'
      elif pbs_state in ['R','W','RUN','WAIT']:
        status = 'RUN'
      elif pbs_state in ['E','EXIT']:
        status = 'EXIT'
      else:
        status = 'UNKNOWN'
    else:
      print 'pbs_state = '+str(pbs_state)
      status = False
    return status
  except Exception,error:
    print Exception
    print error
    return False

##========================
##
##========================
def pbs_waitjob(jobid):
  """
  input: job ID
  Wait until the specified job has a status different than 'RUN' or 'PEND'
  """
  try:
    status = pbs_status(jobid)
    while status in [ 'RUN','PEND']:
      sleep(7)
      status = pbs_status(jobid)
    return
  except Exception,error:
    print Exception
    print error
    sys.exit(9999)
##========================
##
##========================
def kali_wait(nproc,nprocmax):
  """
  only for cerfacs...
  Inputs: nproc (integer), nprocmax (integer)
  You planned to submit a job requiring nproc processors.
  You don't want the total number of processors you are requiring in all your jobs (running or pending) to exceed nprocmax.
  This function will wait for until this is verified.
  """
  nproc = int(nproc)
  nprocmax = int(nprocmax)
  njobmax = 1000
##
  try:
    username = os.environ['USER']
  except:
    username = str(os.getlogin())
##
  icount = 0
  nproctot = nprocmax+1
  njobs = 0
  while nproctot+nproc > nprocmax or nproctot < 0 or njobs >= njobmax:
    if icount == 1:
      if nproctot+nproc > nprocmax:
        print 'You reached nprocmax limit ('+str(nproctot+nproc)+'>'+str(nprocmax)+'), script waiting '
      elif njobs >= njobmax :
        print 'You reached njobmax '+str(njobmax)+' limit, script waiting '
      else:
        print 'You reached queues limit, script waiting '
    if icount > 0:
      sleep(20)
      print '.',
    nproctot = pbs_userproc()
    njobs = pbs_userjobs()
    icount = icount +1
  if icount > 1 :
    print ' '
  return
##========================
##
##========================
def ll_status(jobid):
  """
  Return LOADLEVEL job status in ['PEND','RUN','DONE','EXIT','UNKOWN']
  """
  try:
    shell='llq -f %id %st %c '+str(jobid)
    shstat,shout=commands.getstatusoutput(shell)
    line = string.split(str(shout))
    ll_state = '?'
    status = False
    if line[0]=='llq:' and string.find(shout,' There is currently no job status to report.') != -1:
      status = 'UNKNOWN'
    elif shout != False and shstat == 0:
      for i in range(0,len(line)):
        if jobid == line[i][:(len(jobid))] :
          ll_state = str(line[i+1])
      if ll_state in ['NQ','Q','I','P','C']:
        status = 'PEND'
      elif ll_state in ['R','E']:
        status = 'RUN'
      elif ll_state in ['RM']:
        status = 'EXIT'
      elif ll_state in ['C']:
        status = 'DONE'
      else:
        status = 'UNKNOWN'
    else:
#      print 'jobid    = '+str(jobid)
#      print 'll_state = '+str(ll_state)
      status = False
    return status
  except Exception,error:
    print Exception
    print error
    return False
##========================
##
##========================
def ll_userjobs():
  """
  Return total number of jobs required by user on current server
  """
  try:
    try:
      username = os.environ['USER']
    except:
      username = str(os.getlogin())
##
    njobs = 0
    
    shell='llq -u '+str(username)+' | grep -c '+str(username)
    shstat,shout=commands.getstatusoutput(shell)
    if shstat==0:
      njobs = int(shout)
##
  except:
    njobs = -1
  return njobs
##========================
##
##========================
def ll_waitjob(jobid):
  """
  input: job ID
  Wait until the specified job has a status different than 'RUN' or 'PEND'
  """
  try:
    status = ll_status(jobid)
    print 'Waiting for job '+str(jobid)
    while status in [ 'RUN','PEND']:
      sleep(30)
      print '.',
      status = ll_status(jobid)
    print ' Done.'
  except Exception,error:
    print Exception
    print error

##========================
##
##========================
def octopus_wait(njobmax):
  """
  You don't want the total number of jobs (running or pending) to exceed njobmax.
  This function will wait for until this is verified.
  """
  njobmax = int(njobmax)
##
  icount = 0
  njob=ll_userjobs()
  while njob > njobmax or icount <1 :
    if icount == 1:
      if njob > njobmax:
        print 'You reached njobmax limit ('+str(njob)+'>'+str(njobmax)+'), script waiting '
    if icount > 0:
      sleep(20)
      print '.',
    njob = ll_userjobs()
    icount = icount +1
  if icount > 1 :
    print ' '
  return
