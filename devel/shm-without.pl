#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

use lib 't/lib';



use strict;
use Test::Without::Shm;
use IPC::SysV;

# uncomment this to run the ### lines
use Smart::Comments;

require IPC::SysV;
Test::Without::Shm->mode('nomem');
Test::Without::Shm->mode('enabled');
my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                    5000,
                    IPC::SysV::IPC_CREAT() | 0666); # world read/write
print $shmid,"\n";

Test::Without::Shm->mode('not_implemented');
my $var;
if (! shmread($shmid,$var,0,1)) {
  print "shmread: $!\n";
}
# shmwrite
