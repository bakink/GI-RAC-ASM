
--http://www.hhutzler.de/blog/rac-scripts/#dtrace-script-to-debug-clusterware-startup-problems
--http://www.hhutzler.de/blog/troubleshooting-clusterware-startup-problems-dtrace/4/

#pragma D option dynvarsize=16m
#pragma D option cleanrate=5000hz

char *s;
unsigned short ns_ip_port; 
unsigned short bind_port; 
string var_tmp_loc;
int var_tmp_len;
string grid_bin_loc;
int grid_bin_len;
string pid_file;
int ns_trc_cnt;
int ns_trc_cnt_max;

BEGIN
{
    ns_ip_port = 53; 
    bind_port = 128; 
    ns_trc_cnt = 0;
    ns_trc_cnt_max=3;                        /* We only trace first 3 namesever request */
    var_tmp_loc = "/var/tmp/.oracle" ;
    var_tmp_len=strlen(var_tmp_loc);
    grid_loc = "/u01/app/121/grid";         /* GRIDHOME */ 
    grid_len=strlen(grid_loc);
    grid_bin_loc = strjoin(grid_loc,"/bin");
    grid_bin_len=strlen(grid_bin_loc);
    pid_file="hract21.pid";                 /* Hostname.pid file */ 
    pid_file_len=strlen(pid_file);

    printf("GRIDHOME: %s - GRIDHOME/bin: %s  - Temp Loc: %s -  PIDFILE: %s - Port for bind: %d  ", grid_loc, grid_bin_loc, var_tmp_loc, pid_file, ns_ip_port );
}

syscall::open:entry
{
self->path = copyinstr(arg0);
}

syscall::open:return
/arg0<0 && substr( self->path,0,grid_bin_len) == grid_bin_loc /
{

    printf("- Exec: %s - open() %s failed with error: %d - scan_dir:  %s ", execname, self->path, arg0, substr( self->path,0,grid_bin_len)   );

}

/*
To suppress message like :
  0   9   open:return - Exec: asm_dia0_+asm1 - open() /u01/app/121/grid/bin/asm_dia0_+asm1 failed with error: -2 - scan_dir:  /u01/app/121/grid/bin 
  0   9   open:return - Exec: asm_lmon_+asm1 - open() /u01/app/121/grid/bin/asm_lmon_+asm1 failed with error: -2 - scan_dir:  /u01/app/121/grid/bin 
   --> add  substr(execname,0,4) != "asm_" to our predidate 
       Note there is no executable named  asm_dia0_+asm1  in $GRID_HOME/bin - the executable is named oralce !
       argv[0] argument is changed after staiting and oracle process name get now displayed as:   asm_smon_+ASM1 

Tracing task : Open errors for socket files located in  directory:  /var/tmp/.oracle/
  Typically this directory contains a number of "special" socket files that are used by local clients to 
  connect via the IPC protocol (sqlnet) to various Oracle processes including the TNS listener, the CSS, 
  CRS & EVM daemons or even  database or ASM instances

Clusterware startup fails with following DTRACE output : 
 0      9    open:return - Exec: gpnpd.bin - open() /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock failed with error: -13 - scan_dir:  /var/tmp/.oracle 
 0      9    open:return - Exec: gpnpd.bin - open() /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock failed with error: -13 - scan_dir:  /var/tmp/.oracle 

CRS resources :
*****  Local Resources: *****
Resource NAME               INST   TARGET       STATE        SERVER          STATE_DETAILS
--------------------------- ----   ------------ ------------ --------------- -----------------------------------------
ora.asm                        1   OFFLINE      OFFLINE      -               STABLE  
ora.cluster_interconnect.haip  1   OFFLINE      OFFLINE      -               STABLE  
ora.crf                        1   OFFLINE      OFFLINE      -               STABLE  
ora.crsd                       1   OFFLINE      OFFLINE      -               STABLE  
ora.cssd                       1   ONLINE       OFFLINE      -               STABLE  
ora.cssdmonitor                1   OFFLINE      OFFLINE      -               STABLE  
ora.ctssd                      1   OFFLINE      OFFLINE      -               STABLE  
ora.diskmon                    1   OFFLINE      OFFLINE      -               STABLE  
ora.drivers.acfs               1   ONLINE       ONLINE       hract21         STABLE  
ora.evmd                       1   ONLINE       INTERMEDIATE hract21         STABLE  
ora.gipcd                      1   ONLINE       OFFLINE      -               STABLE  
ora.gpnpd                      1   ONLINE       OFFLINE      hract21         STARTING  
ora.mdnsd                      1   ONLINE       ONLINE       hract21         STABLE  
ora.storage                    1   OFFLINE      OFFLINE      -               STABLE 
--> GPnP deamon does not start as file  /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock  has wrong protections : 
    [ Error -13:  Permission denied ] 
Fix:     
# ls -l /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock
    ---------- 1 grid oinstall 0 Feb 15 08:18 /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock
# chmod 644 /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock
#  ls -l /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock
   -rw-r--r-- 1 grid oinstall 0 Feb 15 08:18 /var/tmp/.oracle/ora_gipc_GPNPD_hract21_lock
     
*/

syscall::open:return
/arg0<0 && substr( self->path,0,var_tmp_len) == var_tmp_loc &&  substr(execname,0,4)  != "asm_"  /
{
    printf("- Exec: %s - open() %s failed with error: %d - scan_dir:  %s ", execname, self->path, arg0, substr( self->path,0,var_tmp_len)   );
}

/*
  Suppress open errors by asm executables by adding substr(execname,0,4) != "asm_")  to our predicates:    
  0      9    open:return - Exec: asm_dia0_+asm1 - open() /u01/app/121/grid/bin/asm_dia0_+asm1 failed with error: -2 - scan_dir:  /u01/app/121/grid/bin 
  0      9    open:return - Exec: asm_lmon_+asm1 - open() /u01/app/121/grid/bin/asm_lmon_+asm1 failed with error: -2 - scan_dir:  /u01/app/121/grid/bin 
  0      9    open:return - Exec: asm_gen0_+asm1 - open() /u01/app/121/grid/bin/asm_gen0_+asm1 failed with error: -2 - scan_dir:  /u01/app/121/grid/bin 

  Search for executable errors : 
*/
syscall::open:return
/arg0<0 && substr( self->path,0,grid_bin_len) == grid_bin_loc && substr(execname,0,4) != "asm_"  /
{
    printf("- Exec: %s - open() %s failed with error: %d - scan_dir:  %s ", execname, self->path, arg0, substr( self->path,0,grid_bin_len)   );
}

/*
    Scan for errors opening HOSTNAME.pid files :  
     /u01/app/121/grid/ohasd/init/hract21.pid
     /u01/app/121/grid/osysmond/init/hract21.pid
     /u01/app/121/grid/gpnp/init/hract21.pid
     /u01/app/121/grid/gipc/init/hract21.pid
     /u01/app/121/grid/log/hract21/gpnpd/hract21.pid
     /u01/app/121/grid/ctss/init/hract21.pid
     /u01/app/121/grid/gnsd/init/hract21.pid
     /u01/app/121/grid/crs/init/hract21.pid
     /u01/app/121/grid/crf/admin/run/crflogd/lhract21.pid
     /u01/app/121/grid/crf/admin/run/crfmond/shract21.pid
     /u01/app/121/grid/evm/init/hract21.pid
     /u01/app/121/grid/mdns/init/hract21.pid
     /u01/app/121/grid/ologgerd/init/hract21.pid
*/ 
syscall::open:return
/arg0<0 && execname!= "crsctl.bin" && substr( self->path,0,grid_len)==  grid_loc &&  strstr(self->path, pid_file ) == pid_file  /
{ 
    printf("- Exec: %s - open() %s failed with error: %d - scan_dir:  %s - PID-File : %s ", execname, self->path, arg0, substr( self->path,0,grid_len), pid_file );
}


/* 
	 Tracing all failed  execve() calls and stop tracing after oradism was started by calling exit()
*/
syscall::execve:entry
{
    self->path = copyinstr(arg0);
}

/* 
	Trace all failed execve call on  the system 
        This allows us to track failed calls for OS utils like awk, sed .....
*/
syscall::execve:return
/arg0<0 && execname != "crsctl.bin"/
{
    printf("- Exec: %s - execve()    %s failed with error: %d", execname, self->path, arg0 );
    self->path = 0;
}

/*
	Track successful CW start 
*/

syscall::execve:return
/execname == "oradism"/
{
    printf("- Exec: %s - execve()  %s -  Lower CLUSTERWARE stack successfully started - ret code:  %d - EXITING !", execname, self->path, arg0 );
    self->path = 0;
    exit(0);
}


/*

To suppress chatty output from semdmsg
  0     96                    sendmsg:entry - Exec: asm_o000_+asm1 - PID: 6639  sendmsg() entry -  fd : 4 - Send-IP: 169.254.213.86 - Port: 47332 
  0     97                   sendmsg:return - Exec: asm_o000_+asm1 - PID: 6639  sendmsg() returns : 32872 
  0     96                    sendmsg:entry - Exec: oracle_6641_+as - PID: 6641  sendmsg() entry -  fd : 4 - Send-IP: 169.254.213.86 - Port: 30631 
  0     97                   sendmsg:return - Exec: oracle_6641_+as - PID: 6641  sendmsg() returns : 32872 
  0     96                    sendmsg:entry - Exec: oracle_6659_+as - PID: 6659  sendmsg() entry -  fd : 4 - Send-IP: 169.254.213.86 - Port: 57092 
  add to our sendmsg predicate: 
   -->  substr(execname,0,4) != "asm_" &&  substr(execname,0,7) != "oracle_"
  
  From strace: 9383  sendmsg(20, {msg_name(16)={sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("192.168.5.50")},
      Byte 0-1 : sa_family
      Byte 2-3 : Portnumber 
      Byte 4-7 _ IP address
    Trace Memory:  tracemem((s+4),16); 
    You may use predicate likes / execname="mdnsd.bin" / to limit the output or suppress any unrelated output !
 
*/

syscall::sendmsg:entry
/execname != "bash"  && substr(execname,0,4) != "asm_" &&  substr(execname,0,7) != "oracle_" &&  substr(execname,0,5) != "gnome" /
{
    self->msghdr =  arg1;
    self->fd = arg0;
    self->msglen = arg2;

    msghdrp = (struct msghdr *)copyin(self->msghdr, sizeof(struct msghdr));
    s = msghdrp->msg_name;
    self->port =  ( unsigned short )(*(s+3)) + ( unsigned short ) ((*(s+2)*256));
    printf("- Exec: %s - PID: %d  sendmsg() entry -  fd : %d - Send-IP: %d.%d.%d.%d - Port: %d " , execname, pid, self->fd, *(s+4), *(s+5) , *(s+6), *(s+7),  ( unsigned short )self->port  );
    self->s= 0;
    self->fd = 0;
    self->port = 0;
}

syscall::sendmsg:return
/execname != "bash"   && substr(execname,0,4) != "asm_" &&  substr(execname,0,7) != "oracle_"/
{
    printf("- Exec: %s - PID: %d  sendmsg() returns : %d ", execname, pid, arg0  );
}

syscall::connect:entry
{
    self->fd = arg0;
    self->sockaddr =  arg1;
    sockaddrp  = (struct sockaddr *)copyin(self->sockaddr, sizeof(struct sockaddr));
    s = (char * )sockaddrp;
    self->port = *(s+3)+ ((*(s+2)*256)); 
    self->ip1=*(s+4);
    self->ip2=*(s+5);
    self->ip3=*(s+6);
    self->ip4=*(s+7);
  /* 
    printf("- Exec: %s - PID: %d  connect() - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, self->fd, 
          self->ip1, self->ip2, self->ip3, self->ip4, self->port  );
*/
}


/*  
        Tracing NameServer connectivty: 
	This script collects TPC/IP address and filedescriptors  for  all connect() system call executed by gipcd.bin against port 53 .
        Port 53 is usally used by nameserver connectivity. If a later sendto() system call fails with the same fd we know 
        that this IP address is not reachable nameserver request. 
*/ 
syscall::connect:return
/self->port == ns_ip_port && execname == "gipcd.bin" && ns_trc_cnt < ns_trc_cnt_max /
{
ns_trc_cnt = ns_trc_cnt +1; 
printf("- Exec: %s - PID: %d  connect() to Nameserver - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, self->fd,
          self->ip1, self->ip2, self->ip3, self->ip4, self->port  );
}

syscall::connect:return
/arg0>0 && execname == "gipcd.bin" && self->port != 0 &&  self->port != 12150 && self->port != ns_ip_port /
{
printf("- Exec: %s - PID: %d  connect() tracking gipcd.bin - ret code: %d  - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, arg0, self->fd,
          self->ip1, self->ip2, self->ip3, self->ip4, self->port  );
}

/* 
    Status : Disabled as this is too chatty
    Generic DTRACE script tracking failed connect() system calls: 
    Don't track the following connection request : 
             connect() failed with error : -2 - fd : 0 - IP: 97.114.47.116 - Port: 12150            --> Disable   port: 12150 
             connect() failed with error : -2 - fd : 0 - IP: 0.0.0.0 -       Port: 0                --> Disable   port:     0
    Dont track error -115 :     #define	EINPROGRESS	115	Operation now in progress 
*/

syscall::connect:return
/arg0<0 && arg0 != -115 && self->port != 0 &&  self->port != 12150 &&  execname != "osysmond.bin" && execname != "ologgerd" && execname != "ons"  && execname != "tnslsnr"  /
{
    printf("- Exec: %s - PID: %d  connect() failed with error : %d - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, arg0, self->fd, 
             self->ip1, self->ip2, self->ip3, self->ip4,    self->port  );
}



syscall::sendto:entry
/execname != "crsctl.bin" /
{
    self->fds = arg0;
}

/* 
    Generic DTRACE script tracking failed sendto() system calls: 
*/ 
syscall::sendto:return
/arg0<0 &&  execname != "crsctl.bin" &&  execname != "osysmond.bin"  &&  execname != "ocssd.bin"  /
{
    printf("- Exec: %s - PID: %d  sendto() failed with error : %d - fd : %d " , execname, pid, arg0, self->fds ); 
}

/* 
    Generic DTRACE script tracking IP-Address and ports for  bind() system calls: 
*/ 
syscall::bind:entry
{
    self->fd = arg0;
    self->sockaddr =  arg1;
    sockaddrp  =(struct sockaddr *)copyin(self->sockaddr, sizeof(struct sockaddr));
    s = (char * )sockaddrp;
    self->port =  ( unsigned short )(*(s+3)) + ( unsigned short ) ((*(s+2)*256));
    self->ip1=*(s+4);
    self->ip2=*(s+5);
    self->ip3=*(s+6);
    self->ip4=*(s+7);
/*
/execname != "crsctl.bin"/
    printf("- Exec: %s - PID: %d  bind() - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, bind_port, 
          self->ip1, self->ip2, self->ip3, self->ip4,  self->port );
*/
}

/* 
    Generic DTRACE script tracking failed bind() system calls: 
*/ 
syscall::bind:return
/arg0<0 && execname != "crsctl.bin"/
{
    printf("- Exec: %s - PID: %d  bind() failed with error : %d - fd : %d - IP: %d.%d.%d.%d - Port: %d " , execname, pid, arg0, self->fd, 
             self->ip1, self->ip2, self->ip3, self->ip4,    self->port  );
}

/* 
	Trace recvmsg() call for any incoming errors :
*/ 
syscall::recvmsg:entry
{
    self->fd = arg0;
}

/*
	Don't trace asm_ and oracle_ processes as they are too chatty and not every recv error is  a real error
*/
syscall::recvmsg:return
/arg0<0 && execname != "crsctl.bin" && execname != "Xorg"  && substr(execname,0,4) != "asm_" &&  substr(execname,0,7) != "oracle_" /
{
    printf("- Exec: %s - PID: %d  recvmsg() failed with error : %d - fd : %d  ", execname, pid,  arg0,  self->fd);
}


****************************
--Output from a successfull Clusterware Startup

# dtrace -s check_rac.d 
dtrace: script 'check_rac.d' matched 21 probes
CPU     ID                    FUNCTION:NAME
  0      1                           :BEGIN GRIDHOME: /u01/app/121/grid - GRIDHOME/bin: /u01/app/121/grid/bin  - Temp Loc: /var/tmp/.oracle -  PIDFILE: hract21.pid - Port for bind: 53  
  0      9                      open:return - Exec: ohasd.bin - open() /var/tmp/.oracle/npohasd failed with error: -6 - scan_dir:  /var/tmp/.oracle 
  0      9                      open:return - Exec: ohasd.bin - open() /var/tmp/.oracle/npohasd failed with error: -6 - scan_dir:  /var/tmp/.oracle 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3070  connect() to Nameserver - fd : 27 - IP: 192.168.5.50 - Port: 53 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3082  connect() to Nameserver - fd : 27 - IP: 192.168.5.50 - Port: 53 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3096  connect() to Nameserver - fd : 27 - IP: 192.168.5.50 - Port: 53 
  0     93                    sendto:return - Exec: crsd.bin - PID: 3367  sendto() failed with error : -32 - fd : 203 
  0     93                    sendto:return - Exec: crsd.bin - PID: 3367  sendto() failed with error : -32 - fd : 203 
  0    103                      bind:return - Exec: ons - PID: 3514  bind() failed with error : -98 - fd : 9 - IP: 0.0.0.0 - Port: 6200 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 191 - IP: 192.168.5.123 - Port: 43956 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 161 - IP: 192.168.5.123 - Port: 43956 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 161 - IP: 192.168.5.123 - Port: 43956 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 161 - IP: 192.168.5.123 - Port: 43956 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 161 - IP: 192.168.5.123 - Port: 43956 
  0     89                   connect:return - Exec: gipcd.bin - PID: 3165  connect() failed with error : -113 - fd : 161 - IP: 192.168.5.123 - Port: 43956 
  0    123                    execve:return - Exec: oradism - execve()  /u01/app/121/grid/bin/oradism -  Lower CLUSTERWARE stack successfully started - ret code:  0 - EXITING !
