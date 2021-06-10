#=========================================================================================
"""
 pytb_optfiles.py
"""
#-----------------------------------------------------------------------------------------
__version__ ='0.0.2'
__author__='J.Laurenceau/Airbus France'
__history__=\
"""
_ Creation date : mar 2007
_ Manipulate optalia files
"""
#=========================================================================================

import commands,os,re,string,sys,shutil
import pytb_various, pytb_vector

##========================
##
##========================
def read_dynopt(filename):
    """
    read a dynamic optimization file.
    manage concurent access to the file.
    """
    funcact  = []
    dfuncact = []
    try:
        lines = pytb_various.readlines2(filename)
        
        line = string.split(lines[0])
        ncalc_done = int(line[0])
        
        line = string.split(lines[1])
        ncalc_asked = int(line[0])

        line = string.split(lines[2])
        taskopt = str(line[0])
        if taskopt == 'ERROR':
            print 'taskopt = ERROR'

        line = string.split(lines[3])
        n_var = int(line[0])
        
        line = string.split(lines[4])
        n_fobj = int(line[0])
        
        line = string.split(lines[5])
        n_fcons = int(line[0])

        n_func = n_fobj + n_fcons

        line = string.split(lines[6])
        varprefix = str(line[0])
        
        line = string.split(lines[7])
        funcprefix = str(line[0])
        
        line = string.split(lines[8])
        dfuncprefix = str(line[0])

        line = string.split(lines[9])
        for i in range(0,n_func):
            funcact.append(int(line[i]))
        
        line = string.split(lines[10])
        for i in range(0,n_func):
            dfuncact.append(int(line[i]))
        
        return ncalc_done, ncalc_asked, taskopt, n_var, n_fobj, n_fcons, varprefix, funcprefix, dfuncprefix, funcact, dfuncact
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_dynopt()'
        print 'f_dynopt = '+str(filename)
        print error
        sys.exit(9999)
##========================
##
##========================
def write_dynopt(filename, ncalc_done, ncalc_asked, taskopt, n_var, n_fobj, n_fcons, varprefix, funcprefix, dfuncprefix, funcact, dfuncact):
    """
    write a dynamic optimization file.
    manage concurent access to the file.
    """
    lines = []
    try:
        lines.append(str(ncalc_done)+'\n')
        lines.append(str(ncalc_asked)+'\n')
        lines.append(taskopt+'\n')
        if taskopt == 'ERROR':
            print 'taskopt = ERROR'
        lines.append(str(n_var)+'\n')
        lines.append(str(n_fobj)+'\n')
        lines.append(str(n_fcons)+'\n')
        lines.append(varprefix+'\n')
        lines.append(funcprefix+'\n')
        lines.append(dfuncprefix+'\n')
        line = pytb_vector.convert_str(funcact)
        lines.append(line+'\n')
        line = pytb_vector.convert_str(dfuncact)
        lines.append(line+'\n')
        
        pytb_various.writelines2(filename,lines)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.write_dynopt()'
        print 'f_dynopt = '+str(filename)
        print 'lines    = '+str(lines)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_var(f_var):
    """
    read a variable file.
    manage concurent access to the file.
    """
    var = []
    n_var = -1
    try:
        lines = pytb_various.readlines2(f_var)
        line = string.split(lines[1])
        n_var = int(line[0])
        for i in range(0,n_var):
            line = string.split(lines[2+i])
            var.append(float(line[0]))
        return n_var, var
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_var()'
        print 'f_var = '+str(f_var)
        print 'n_var = '+str(n_var)
        print 'var = '+str(var)
        print error
        sys.exit(9999)
##========================
##
##========================
def write_var(n_var,var,f_var):
    """
    write a variable file.
    manage concurent access to the file.
    """
    try:
        lines = []
        lines.append('# Design variables file\n')
        lines.append(str(n_var)+'\n')
        for i in range(0,n_var) :
            lines.append(str(var[i])+'\n')
        pytb_various.writelines2(f_var,lines)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.write_var()'
        print 'f_var = '+str(f_var)
        print 'n_var = '+str(n_var)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_func(f_func):
    """
    read a function file.
    manage concurent access to the file.
    """
    func = []
    funcact = []
    n_fobj  = -1
    n_fcons = -1
    try:
        lines = pytb_various.readlines2(f_func)
        
        line = string.split(lines[1])             ## this line contains n_fobj n_fcons
        n_fobj = int(line[0])       ## nb of objective functions
        n_fcons = int(line[1])      ## nb of constraint functions
        n_func = n_fobj + n_fcons
        
        line = string.split(lines[2])           ## this line contains list of active functions
        for i in range(0,n_func) :
            funcact.append(int(line[i]))
        
        line = string.split(lines[3])    ## this line contains list of functions values
        for i in range(0,n_func) :
            func.append(float(line[i]))
        
        return n_fobj,n_fcons,funcact,func
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_func()'
        print 'f_func  = '+str(f_func)
        print 'n_fobj  = '+str(n_fobj)
        print 'n_fcons = '+str(n_fcons)
        print 'funcact = '+str(funcact)
        print 'func    = '+str(func)
        print error
        sys.exit(9999)
##========================
##
##========================
def write_func(n_fobj,n_fcons,funcact,func,f_func):
    """
    write a function file.
    manage concurent access to the file.
    """
    try:
        n_func = n_fobj + n_fcons
        if len(func) != n_func or len(funcact) != n_func :
            print 'ERROR !! in pytoolbox : pytb_optfiles.write_func()'
            sys.exit(9999)

        lines = []

        lines.append('# Objective(s) + Constraint(s) function file\n')

        lines.append(str(n_fobj)+'\t'+str(n_fcons)+'\n')

        line = pytb_vector.convert_str(funcact)
        lines.append(line+'\n')

        line = pytb_vector.convert_str(func)
        lines.append(line+'\n')
        
        pytb_various.writelines2(f_func,lines)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.write_func()'
        print 'f_func  = '+str(f_func)
        print 'n_fobj  = '+str(n_fobj)
        print 'n_fcons = '+str(n_fcons)
        print 'funcact = '+str(funcact)
        print 'func    = '+str(func)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_dfunc(f_dfunc):
    """
    read a function function derivatives file.
    manage concurent access to the file.
    """
    dfunc = []
    dfuncact = []
    n_fobj  = -1
    n_fcons = -1
    n_var   = -1
    try:
        lines = pytb_various.readlines2(f_dfunc)
        
        line = string.split(lines[1])             ## this line contains n_fobj n_fcons n_var
        n_fobj = int(line[0])       ## nb of objective functions
        n_fcons = int(line[1])      ## nb of constraint functions
        n_var = int(line[2])        ## nb of variables
        n_func = n_fobj + n_fcons
        
        line = string.split(lines[2])           ## this line contains list of active function derivatives
        for i in range(0,n_func) :
            dfuncact.append(int(line[i]))

        for i in range(0,n_var) :
            line = string.split(lines[i+3])    ## this line contains list of functions derivatives values
            dfunc_j = []
            for j in range(0,n_func) :
                dfunc_j.append(float(line[j]))
            dfunc.append(dfunc_j)
        
        return n_fobj,n_fcons,n_var,dfuncact,dfunc
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_dfunc()'
        print 'f_dfunc  = '+str(f_dfunc)
        print 'n_var   = '+str(n_var)
        print 'n_fobj  = '+str(n_fobj)
        print 'n_fcons = '+str(n_fcons)
        print 'dfuncact = '+str(dfuncact)
        print 'dfunc    = '+str(dfunc)
        print error
        sys.exit(9999)
##========================
##
##========================
def write_dfunc(n_var,n_fobj,n_fcons,dfuncact,dfunc,f_dfunc):
    """
    write a function function derivatives file.
    manage concurent access to the file.
    """
    try:
        n_func = n_fobj + n_fcons
        if len(dfunc) != n_func or len(dfuncact) != n_func or len(dfunc[0]) != n_var:
            print 'ERROR !! in pytoolbox : pytb_optfiles.write_dfunc()'
            sys.exit(9999)

        lines = []
        
        lines.append('# Objective(s) + Constraint(s) function derivatives file\n')

        lines.append(str(n_fobj)+'\t'+str(n_fcons)+'\t'+str(n_var)+'\n')

        line = pytb_vector.convert_str(dfuncact)
        lines.append(line+'\n')

        for j in range(0,n_var):
            line = ''
            for i in range(0,n_func):
                line = line + str(dfunc[i][j]) + '\t'
            lines.append(line+'\n')
        
        pytb_various.writelines2(f_dfunc,lines)
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.write_dfunc()'
        print 'f_dfunc  = '+str(f_dfunc)
        print 'n_var    = '+str(n_var)
        print 'n_fobj   = '+str(n_fobj)
        print 'n_fcons  = '+str(n_fcons)
        print 'dfuncact = '+str(dfuncact)
        print 'dfunc    = '+str(dfunc)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_fobjpost(n_fobj,n_fcons,f_func):
    """
    read the objective function values in an optalia post log file.
    manage concurent access to the file.
    """
    func = []
    funcact = []
    if n_fobj != 1:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_func(), n_fobj'
        sys.exit(9999)
    n_func = n_fobj + n_fcons
    for i in range(0,n_func):
        func.append(float(1.0e+30))
        funcact.append(0)
    try:
        lines = pytb_various.readlines2(f_func)
        for i in range(0,len(lines)):
            if string.find(lines[i],'Fobj(') != -1:
                line = string.split(lines[i])
                func[0] = float(line[3])
                funcact[0] = 1
            if string.find(lines[i],'Fcons(') != -1:
                line = string.split(lines[i])
                func[n_fobj+int(line[1])-1] = float(line[3])
                funcact[n_fobj+int(line[1])-1] = 1
        return funcact, func
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_func()'
        print 'f_func  = '+str(f_func)
        print 'n_fobj  = '+str(n_fobj)
        print 'n_fcons = '+str(n_fcons)
        print 'funcact = '+str(funcact)
        print 'func    = '+str(func)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_fobjpost_mp(n_fobj,n_fcons,n_design,f_func):
    """
    read the objective function values in an optalia post log file.
    manage concurent access to the file.
    manage multipoint computations
    """
    func = []
    funcact = []
    n_func = n_fobj + n_fcons
    if n_fobj != 1 or n_design <1:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_func_mp(), n_fobj or n_design'
        sys.exit(9999)
    for i in range(0,n_func):
        func.append(float(0.0))
        funcact.append(0)
    try:
        lines = pytb_various.readlines2(f_func)
        icount = 0
        for i in range(0,len(lines)):
            if string.find(lines[i],'Fobj(') != -1:
                line = string.split(lines[i])
                func[0] = func[0] + float(line[3])
                funcact[0] = 1
                icount = icount +1
            if string.find(lines[i],'Fcons(') != -1:
                line = string.split(lines[i])
                func[n_fobj+int(line[1])-1] = float(line[3])
                funcact[n_fobj+int(line[1])-1] = 1
        if icount != n_design:
            print 'ERROR !! in pytoolbox : pytb_optfiles.read_func_mp(), i_count'
            sys.exit(9999)
        return funcact, func
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_func_mp()'
        print 'f_func  = '+str(f_func)
        print 'n_fobj  = '+str(n_fobj)
        print 'n_fcons = '+str(n_fcons)
        print 'n_design = '+str(n_design)
        print 'funcact = '+str(funcact)
        print 'func    = '+str(func)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_funcgrad(f_funcgrad):
    """
    read a funcgrad file.
    manage concurent access to the file.
    """
    dfunc = []
    n_var = -1
    n_func = -1
    try:
        lines = pytb_various.readlines2(f_funcgrad)
        line = string.split(lines[0])
        n_func = int(line[0])
        n_var = int(line[1])
        for n in range(0,n_func):
            dfunci = []
            for v in range(0,n_var):
                line = string.split(lines[v+n*n_var+1])
                dfunci.append(float(line[0]))
            dfunc.append(dfunci)
        return n_var, n_func, dfunc
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_funcgrad()'
        print 'f_funcgrad = '+str(f_funcgrad)
        print 'n_func = '+str(n_func)
        print 'n_var = '+str(n_var)
        print 'dfunc = '+str(dfunc)
        print error
        sys.exit(9999)
##========================
##
##========================
def write_funcgrad(n_var,n_func,dfunc,f_funcgrad):
    """
    write a funcgrad file.
    manage concurent access to the file.
    """
    try:
        lines = []
        line = str(n_func)+'\t'+str(n_var)
        lines.append(line+'\n')
        for n in range(0,n_func):
            for v in range(0,n_var):
                line = str(dfunc[n][v])
                lines.append(line+'\n')
        pytb_various.writelines2(f_funcgrad,lines)
        return
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.write_funcgrad()'
        print 'f_funcgrad = '+str(f_funcgrad)
        print 'n_func = '+str(n_func)
        print 'n_var = '+str(n_var)
        print 'dfunc = '+str(dfunc)
        print error
        sys.exit(9999)
##========================
##
##========================
def read_funcgrad_elsalog(f_elsalog):
    """
    read funcgrad values from an elsalog file.
    manage concurent access to the file.
    """
    dfunc = []
    n_var = -1
    n_func = -1
    try:
        lines = pytb_various.readlines2(f_elsalog)
        l=0
        while l < len(lines):
            if string.find(lines[l],'_nbFunction') != -1:
                line = string.split(lines[l])
                n_func = int(line[1])
            if string.find(lines[l],'_nbControl') != -1:
                line = string.split(lines[l])
                n_var = int(line[1])
            if n_var != -1 and n_func != -1:
                l = len(lines)+1
            l=l+1
        for n in range(0,n_func):
            dfunci = []
            for i in range(0,n_var):
                l=0
                while l < len(lines):
                    if string.find(lines[l],'dF_'+str(n+1)+' /d alpha_'+str(i+1)+' =') != -1:
                        line = string.split(lines[l])
                        dfunci.append(float(line[4]))
                    if len(dfunci) == n_var :
                        l = len(lines)+1
                    l=l+1
            dfunc.append(dfunci)
        return n_var, n_func, dfunc
    except Exception,error:
        print 'ERROR !! in pytoolbox : pytb_optfiles.read_funcgrad_elsalog()'
        print 'f_elsalog = '+str(f_elsalog)
        print 'n_func = '+str(n_func)
        print 'n_var = '+str(n_var)
        print 'dfunc = '+str(dfunc)
        print error
        sys.exit(9999)
##========================
##
##========================
def var2samples(fn_varprefix,ns_start,ns_end,fn_samples):
    """
    Convert ns variable files into one samples file.
    """
    ns = ns_end - ns_start + 1
    for i in range(ns_start,ns_end+1):
        fn_var = fn_varprefix+'_'+str(i)+'.opt'
        if not os.path.isfile(fn_var):
            print 'ERROR !! in pytoolbox : pytb_optfiles.var2samples'
            print 'file '+fn_var+' does not exist'
            sys.exit(9999)
            
        n_var , var = read_var(fn_var)
        line = pytb_vector.convert_str(var)
        if i == ns_start:
            lines = tpheader('var',ns,n_var)
        lines.append(line+'\n')
    pytb_various.writelines2(fn_samples,lines)
    return
##========================
##
##========================
def samples2var(fn_samples,n_var,ns_start,ns_end,fn_varprefix):
    """
    Convert one samples file into n variable files.
    """
    lines = pytb_various.readlines2(fn_samples)
    
    for i in range(ns_start,ns_end+1):
        var = []
        fn_var = fn_varprefix+'_'+str(i)+'.opt'
        line = string.split(lines[2+i])
        for k in range(0,n_var):
            var.append(line[k])
        write_var(n_var,var,fn_var)
    return
##========================
##
##========================
def varfunc2samples(fn_varprefix,fn_funcprefix,ns_start,ns_end,fn_samplesprefix):
    """
    Convert ns variable files + ns function files into n_func samples file.
    """
    fn_func = fn_funcprefix+'_1.opt'
    if not os.path.isfile(fn_func):
        print 'ERROR !! in pytoolbox : pytb_optfiles.varfunc2samples'
        print 'file '+fn_func+'does not exist'
        sys.exit(9999)
    n_fobj,n_fcons,funcact,func = read_func(fn_func)
    n_func = n_fobj + n_fcons
        
    for ifunc in range(0,n_func):
        if funcact[ifunc] == 1:
            fn_samples = fn_samplesprefix+'_func'+str(ifunc+1)+'.dat'
            for i in range(ns_start,ns_end+1):
                fn_var = fn_varprefix+'_'+str(i)+'.opt'
                if not os.path.isfile(fn_var):
                    print 'ERROR !! in pytoolbox : pytb_optfiles.varfunc2samples'
                    print 'file '+fn_var+'does not exist'
                    sys.exit(9999)
                fn_func = fn_funcprefix+'_'+str(i)+'.opt'
                if not os.path.isfile(fn_func):
                    print 'ERROR !! in pytoolbox : pytb_optfiles.varfunc2samples'
                    print 'file '+fn_func+'does not exist'
                    sys.exit(9999)
            
                n_var , var = read_var(fn_var)
                line = pytb_vector.convert_str(var)

                n_fobj,n_fcons,funcact,func = read_func(fn_func)
                line = line + '\t' + str(func[ifunc])
        
                if i == ns_start:
                    lines  = tpheader('func',ns_end-ns_start+1,n_var)
                lines.append(line+'\n')
            pytb_various.writelines2(fn_samples,lines)
    return
##========================
##
##========================
def samples2varfunc(fn_samples,n_var,n_fobj,n_fcons,ns_start,ns_end,fn_varprefix,fn_funcprefix):
    """
    Convert one samples file into n variable files and n function files.
    """
    n_func = n_fobj + n_fcons
    funcact = []
    for n in range(0,n_func):
        funcact.append(1)
    lines = pytb_various.readlines2(fn_samples)
    
    for i in range(ns_start,ns_end+1):
        var = []
        func = []
        fn_var = fn_varprefix+'_'+str(i)+'.opt'
        fn_func = fn_funcprefix+'_'+str(i)+'.opt'
        line = string.split(lines[2+i])
        for k in range(0,n_var):
            var.append(line[k])
        write_var(n_var,var,fn_var)
        for k in range(n_var,n_var+n_func):
            func.append(line[k])
        write_func(n_fobj,n_fcons,funcact,func,fn_func)
    return
##========================
##
##========================
def vardfunc2samples(fn_varprefix,fn_funcprefix,fn_dfuncprefix,ns_start,ns_end,fn_samplesprefix):
    """
    Convert ns variable files + ns function files + ns function gradient files into n_func samples file.
    """
    fn_func = fn_funcprefix+'_1.opt'
    fn_dfunc = fn_dfuncprefix+'_1.opt'
    if not os.path.isfile(fn_func) or not os.path.isfile(fn_dfunc):
        print 'ERROR !! in pytoolbox : pytb_optfiles.vardfunc2samples'
        print 'file '+fn_func+' or '+fn_dfunc+'does not exist'
        sys.exit(9999)
    n_fobj,n_fcons,funcact,func = read_func(fn_func)
    n_func = n_fobj + n_fcons
    n_fobj,n_fcons,n_var,dfuncact,dfunc = read_dfunc(fn_dfunc)
        
    for ifunc in range(0,n_func):
        if funcact[ifunc] == 1 and dfuncact[ifunc] == 1:
            fn_samples = fn_samplesprefix+'_func'+str(ifunc+1)+'.dat'
            for i in range(ns_start,ns_end+1):
                fn_var = fn_varprefix+'_'+str(i)+'.opt'
                if not os.path.isfile(fn_var):
                    print 'ERROR !! in pytoolbox : pytb_optfiles.vardfunc2samples'
                    print 'file '+fn_var+'does not exist'
                    sys.exit(9999)
                fn_func = fn_funcprefix+'_'+str(i)+'.opt'
                if not os.path.isfile(fn_func):
                    print 'ERROR !! in pytoolbox : pytb_optfiles.vardfunc2samples'
                    print 'file '+fn_func+'does not exist'
                    sys.exit(9999)
                fn_dfunc = fn_dfuncprefix+'_'+str(i)+'.opt'
                if not os.path.isfile(fn_dfunc):
                    print 'ERROR !! in pytoolbox : pytb_optfiles.vardfunc2samples'
                    print 'file '+fn_dfunc+'does not exist'
                    sys.exit(9999)
                
                n_var , var = read_var(fn_var)
                line = pytb_vector.convert_str(var)

                n_fobj,n_fcons,funcact,func = read_func(fn_func)
                line = line + '\t' + str(func[ifunc])

                n_fobj,n_fcons,n_var,dfuncact,dfunc = read_dfunc(fn_dfunc)
                for v in range(0,n_var):
                    if n_func == 1 :
                        line = line + '\t' +pytb_vector.convert_str(dfunc[v])
                    else:
                        line = line + '\t' +pytb_vector.convert_str(dfunc[ifunc][v])
        
                if i == ns_start:
                    lines  = tpheader('dfunc',ns_end-ns_start+1,n_var)
                lines.append(line+'\n')
            pytb_various.writelines2(fn_samples,lines)
    return
##========================
##
##========================
def samples2vardfunc(fn_samples,n_var,n_fobj,n_fcons,ns_start,ns_end,fn_varprefix,fn_funcprefix,fn_dfuncprefix):
    """
    Convert one samples file into n variable files and n function files.
    """
    n_func = n_fobj + n_fcons
    funcact = []
    dfuncact = []
    for n in range(0,n_func):
        funcact.append(1)
        dfuncact.append(1)
    lines = pytb_various.readlines2(fn_samples)
    
    for i in range(ns_start,ns_end+1):
        var = []
        func = []
        dfunc = []
        fn_var = fn_varprefix+'_'+str(i)+'.opt'
        fn_func = fn_funcprefix+'_'+str(i)+'.opt'
        fn_dfunc = fn_dfuncprefix+'_'+str(i)+'.opt'
        line = string.split(lines[2+i])
        for k in range(0,n_var):
            var.append(line[k])
        write_var(n_var,var,fn_var)
        for k in range(n_var,n_var+n_func):
            func.append(line[k])
        write_func(n_fobj,n_fcons,funcact,func,fn_func)
        n = n_var+n_func
        for k in range(1,n_func+1):
            dfunci = []
            for v in range(0,n_var):
                dfunci.append(line[n+v])
            dfunc.append(dfunci)
            n = n + n_var
        write_dfunc(n_var,n_fobj,n_fcons,dfuncact,dfunc,fn_dfunc)
    return
##========================
##
##========================
def tpheader(mode,ni,nj):
    """
    Tecplot header generator.
    """
    if mode not in ['var','func','dfunc'] :
        mode = 'var'
    header  = []
    line = 'TITLE="Sample Database"'
    header.append(line+'\n')
    line = 'VARIABLES ='
    for j in range(1,nj+1):
        line = line+' "X'+str(j)+'"'
    if mode in ['func','dfunc']:
        line = line+' "F"'
    if mode == 'dfunc' :
        for j in range(1,nj+1):
            line = line+' "dFdX'+str(j)+'"'
    header.append(line+'\n')
    line = 'ZONE T="Samples" i='+str(ni)+' F=POINT'
    header.append(line+'\n')
    return header
##========================
##
##========================
def min_optihist(n_var,f_optihist):
    """
    read a opthistgraph file and return min value.
    column format like: # ncalc niter var(n_var) Fobj
    """
    var = []
    line = ''
    fobj = 1.0e+100
    try:
        fid = open(f_optihist,'r')
        lines = fid.readlines()
        fid.close()
        for n in range(0,len(lines)):
            line = string.split(lines[n])
            if line[0] != '#' and line[0] != '##' and line[n_var+2] not in ['NAN','nan','Nan','NaN'] :
                if float(line[n_var+2]) <= fobj:
                    var = []
                    for i in range(0,n_var):
                        var.append(float(line[i+2]))
                    fobj = float(line[n_var+2])
    except:
        print 'ERROR !! in pytoolbox : pytb_optfiles.min_optihist()'
        print 'f_optihist = '+str(f_optihist)
        print 'var = '+str(var)
        print 'fobj = '+str(fobj)
        print 'current line = '+line
    return var, fobj
##========================
##
##========================
def min_samples(n_var,ns,f_samples):
    """
    read a samples file and return min value
    column format like: # var(n_var) Fobj
    """
    var = []
    line = ''
    fobj = 1.0e+100
    try:
        fid = open(f_samples,'r')
        lines = fid.readlines()
        fid.close()
        for n in range(3,ns+3):
            line = string.split(lines[n])
            if len(line) >= n_var:
                if line[0] not in ['#','##'] and line[n_var] not in ['NAN','nan','Nan','NaN'] :
                    if float(line[n_var]) <= fobj:
                        var = []
                        for i in range(0,n_var):
                            var.append(float(line[i]))
                        fobj = float(line[n_var])
    except:
        print 'ERROR !! in pytoolbox : pytb_optfiles.min_samples()'
        print 'f_samples = '+str(f_samples)
        print 'var = '+str(varvect)
        print 'fobj = '+str(fobj)
        print 'current line = '+str(line)
    return var,fobj
##========================
##
##========================
def read_localjobid():
    """
    read the jobid from an optalia local.log file.
    manage concurent access to the file.
    """
    jobid = False
    if os.path.isfile('local.log'):
            lines = pytb_various.readlines2('local.log')
            for n in range(0,len(lines)):
              if string.find(lines[n],'Create recopy script') != -1 and string.find(lines[n+2],'Create job') != -1:
                nretry = 0
                while string.find(lines[n+4+nretry],'not responding') != -1:
                  nretry = nretry +1
                line = string.split(lines[n+4+nretry])
                if line[0] == 'Job':
                  jobid = line[1]
                  jobid = string.replace(jobid,'<','')
                  jobid = string.replace(jobid,'>','')
                else:
                  jobid = line[0]
    return jobid
##========================
##
##========================
def read_localendmsg():
    """
    read in the current directory the status in the file OPTALIA_END_MSG_*
    manage concurent access to the file.
    """
    status = 'UNKNOWN'
    list_out = os.listdir('.')
    if string.find(str(list_out),'OPTALIA_END_MSG_') != -1:
        for file in os.listdir('.'):
            if string.find(str(file),'OPTALIA_END_MSG_') != -1:
                lines = pytb_various.readlines2(file)
                line = string.split(lines[0])
                status = string.replace(line[0],',','')
    return status
##========================
##
##========================
def datajob_update(fn_datajob,newline):
  """
  Add a new calculation in a job database file.
  """
  line = string.split(newline)
  processname = line[0]
  ncalc = int(line[1])
  
  fid = pytb_various.openf2(fn_datajob,'r')
  lines = fid.readlines()
  newlines = []
  existing = False
  for i in range(0,len(lines)):
    if len(lines[i]) > 0:
      line = string.split(lines[i])
      if len(line) >= 5:
        if line[0] == processname and int(line[1]) == ncalc:
          existing = True
          newlines.append(newline+'\n')
        else:
          newlines.append(lines[i])
      else:
        newlines.append(lines[i])
  if not existing:
    newlines.append(newline+'\n')
  fid.close()

  pytb_various.writelines2(fn_datajob,newlines)
  
  return
##========================
##
##========================
def get_optkeyvalue(lines_optalia,key):
    """
    Get a the value of a given key from an optalia ASCII config file.
    """
    for line in lines_optalia:
        if line[:len(key)] == key:
            theline = string.split(line)
            value = str(theline[1])
    ## substitutes alias by their real values
    listalias = []
    alias = {}
    for line in lines_optalia:
        if line[0] == '@':
            theline = string.split(line)
            listalias.append(theline[0])
            alias[theline[0]] = theline[1]
    for name in listalias:
        value = string.replace(value,name,alias[name])
    return value
##========================
##
##========================
def put_optkeyvalue(lines_optalia,key,value):
    """
    Put the value of a given key in an optalia ASCII config file.
    """
    replaced = False
    newlines = []
    for line in lines_optalia:
        newline = line
        if line[:len(key)] == key:
            theline = string.split(line)
            theline[1] = str(value)
            newline = key+'\t\t'+str(value)+'\n'
            replaced = True
        newlines.append(newline)
    if not replaced:
        newline = key+'\t\t'+str(value)+'\n'
        newlines.append(newline)
    return newlines
##========================
##
##========================
def read_samples(lines,n_var):
    """
    Read a samples datafile
    """
    
    var=[]
    func=[]
    dfunc=[]

    if len(string.split(lines[3])) == n_var:
        readfunc = False
        readgrad = False
    elif len(string.split(lines[3])) == n_var+1:
        readfunc = True
        readgrad = False
    elif len(string.split(lines[3])) == 2*n_var+1:
        readfunc = True
        readgrad = True
    else:
        print 'ERROR !!! pytb_optfiles.read_samples()'
        sys.exit(9999)
        
    for l in range(3,len(lines)):
        line = string.split(lines[l])
        vari = []
        for j in range(0,n_var):
            vari.append(float(line[j]))
        var.append(vari)
        if readfunc:
            funci = (float(line[n_var]))
        func.append(funci)
        if readgrad:
            dfunci = []
            for j in range(n_var+1,2*n_var+1):
                dfunci.append(float(line[j]))
            dfunc.append(dfunci)
    return var,func,dfunc
