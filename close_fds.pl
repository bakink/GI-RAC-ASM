--https://www.performatune.com/en/migrating-asm-diskgroups-to-another-storage-without-downtime/
--ASM 11.2.0.2 Is Not Releasing File Descriptors After Drop or Dismount Diskgroup. (Doc ID 1306574.1)
--http://blog.itpub.net/17252115/viewspace-1442634/
--https://www.freelists.org/post/oracle-l/close-fdspl-perl-script,1
--http://rajakaparthi.blogspot.com/2014/06/disks-of-dropped-diskgroup-are-still.html

#!/usr/local/bin/perl
# 
# $Header: gitools/src/asm/scripts/close_fds.pl asolisg_closefds/7 2012/07/24 14:58:42 asolisg Exp $
#
# close_fds.pl
# 
# Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      close_fds.pl - Close file descriptors.
#
#    DESCRIPTION
#      This utility signals the specified processes to close their open 
#      file descriptors.
#
#    NOTES
#       Work-around for Bug14223113.
#
#    MODIFIED   (MM/DD/YY)
#    asolisg     07/19/12 - Creation
# 

use strict;


#########################################################################
# inputs

my(@pids);                  # Array of process IDs specified by the user
my($pid) = 0;

use IO::Handle;
my $sqlpluspid;
my $line;

#########################################################################
# process args

if ($#ARGV < 0)
{
  usage();
  exit 1;
}

foreach $pid (@ARGV) {
  push(@pids,  "\L$pid");
}

if ("$ENV{'ORACLE_HOME'}" eq "") 
{
  die "\nERROR: The environment variable ORACLE_HOME is empty.\n";
}
if ("$ENV{'ORACLE_SID'}" eq "") 
{
  die "\nERROR: The environment variable ORACLE_SID is empty.\n";
}

#########################################################################

#
# Connect to the Oracle instance and call function kfkFDCleanup, which
# will close the open file descriptors of each process in the array.
#
pipe (FROM_MAIN, TO_SQLPLUS);
pipe (FROM_SQLPLUS, TO_MAIN);

TO_SQLPLUS->autoflush(1);
TO_MAIN->autoflush(1);

if ($sqlpluspid = fork)
{
  # fork parent
  close FROM_MAIN;
  close TO_MAIN;

  # Discard initial sqlplus output
  $line = <FROM_SQLPLUS>; # ""
  $line = <FROM_SQLPLUS>; # "SQL*Plus: Realease ...
  die "Error starting sqlplus process." unless ($line =~ m/^SQL\*Plus: /);
  $line = <FROM_SQLPLUS>; # ""
  $line = <FROM_SQLPLUS>; # "Copyright (c) ..."
  $line = <FROM_SQLPLUS>; # ""

  print TO_SQLPLUS "connect / as sysdba\n";
  if ( ($line = <FROM_SQLPLUS>) =~ m/ERROR/ )
  {
    $line = <FROM_SQLPLUS>;
    print STDERR $line;
    exit;
  }

  foreach $pid(@pids)
  {
    print TO_SQLPLUS "oradebug setospid $pid\n";
    if ( ($line = <FROM_SQLPLUS>) =~ m/ORA-/ )
    {
      # pid is invalid, print errors found
      $line =~ s/SQL> //g;
      print STDERR $line;
    }
    else 
    {
      # pid is valid
      print "Closing ASM disk descriptors for process $pid.\n";
      print TO_SQLPLUS "oradebug unit_test_rem asm_test kfk cleanup\n";
      $line = <FROM_SQLPLUS>; # "Statement processed."
    }
  }

  print TO_SQLPLUS "EXIT\n";

  close FROM_SQLPLUS;
  close TO_SQLPLUS;

  waitpid ($sqlpluspid, 0);
} 
else 
{
  # fork child
  die "\nERROR: Could not fork.\n" unless defined $sqlpluspid;

  close FROM_SQLPLUS;
  close TO_SQLPLUS;

  # Redirect input and output to pipes
  open (STDIN, "<&FROM_MAIN");
  open (STDOUT, ">&TO_MAIN");

  exec ("sqlplus /nolog") or die "\nERROR: Could not create sqlplus process.\n";
}

#########################################################################
# subroutines
#

sub usage
{
  print STDERR "close_fds - close file descriptors\n\n";
  print STDERR "USAGE: perl close_fds.pl PID...\n\n";
  print STDERR "This utility signals the specified processes to close ";
  print STDERR "their open\nfile descriptors\n\n";
}


