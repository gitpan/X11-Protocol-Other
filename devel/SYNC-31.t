#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 90)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('SYNC');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no SYNC on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("SYNC extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('SYNC')) {
  die "QueryExtension says SYNC avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# Errors

{
  ok ($X->num('Error','Counter'),    $first_error);
  ok ($X->num('Error','Alarm'),      $first_error+1);
  ok ($X->num('Error','Fence'),      $first_error+2);
  ok ($X->num('Error',$first_error), $first_error);
  ok ($X->num('Error',$first_error+1), $first_error+1);
  ok ($X->num('Error',$first_error+2), $first_error+2);
  ok ($X->interp('Error',$first_error), 'Counter');
  ok ($X->interp('Error',$first_error), 'Alarm');
  ok ($X->interp('Error',$first_error), 'Fence');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
    ok ($X->interp('Error',$first_error+1), $first_error+1);
    ok ($X->interp('Error',$first_error+2), $first_error+2);
  }
}


#------------------------------------------------------------------------------
# SyncReportLevel enum

{
  ok ($X->num('SyncReportLevel','RawRectangles'),   0);
  ok ($X->num('SyncReportLevel','DeltaRectangles'), 1);
  ok ($X->num('SyncReportLevel','BoundingBox'),     2);
  ok ($X->num('SyncReportLevel','NonEmpty'),        3);

  ok ($X->num('SyncReportLevel',0), 0);
  ok ($X->num('SyncReportLevel',1), 1);
  ok ($X->num('SyncReportLevel',2), 2);
  ok ($X->num('SyncReportLevel',3), 3);

  ok ($X->interp('SyncReportLevel',0), 'RawRectangles');
  ok ($X->interp('SyncReportLevel',1), 'DeltaRectangles');
  ok ($X->interp('SyncReportLevel',2), 'BoundingBox');
  ok ($X->interp('SyncReportLevel',3), 'NonEmpty');
}


#------------------------------------------------------------------------------
# SyncQueryVersion

{
  my $client_major = 1;
  my $client_minor = 1;
  my @ret = $X->SyncQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server SYNC version ", join('.',@ret));
  ok (scalar(@ret), 2);
  ok ($ret[0] <= $client_major, 1);
}
  $X->QueryPointer($X->root); # sync

#------------------------------------------------------------------------------
# SyncCreate / SyncDestroy

{
  my $level;
  foreach $level ('RawRectangles',
                  'DeltaRectangles',
                  'BoundingBox',
                  'NonEmpty') {
    my $damage = $X->new_rsrc;
    $X->SyncCreate ($damage, $X->root, $level);
    $X->SyncDestroy ($damage);
    $X->QueryPointer($X->root); # sync
    ok (1, 1, 'SyncCreate / SyncDestroy');
  }
}

#------------------------------------------------------------------------------
# SyncNotify event

{
  my $aref = $X->{'ext'}->{'SYNC'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, at least in 0.56
                   # name      => "SyncNotify",
                   synthetic => 1,
                   code      => $event_num,
                   sequence_number => 100,
                   damage   => 101,
                   drawable => 102,
                   level    => 'BoundingBox',
                   more     => $more,
                   time     => $time,
                   area     => [-104,-105,106,107],
                   geometry => [108,109,110,111]);
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'SyncNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});
      ok ($output{'damage'},    $input{'damage'});
      ok ($output{'drawable'},  $input{'drawable'});
      ok ($output{'level'},     $input{'level'});
      ok ($output{'more'},      $input{'more'});
      ok ($output{'time'},      $input{'time'});

      ok ($output{'area'}->[0], $input{'area'}->[0]);
      ok ($output{'area'}->[1], $input{'area'}->[1]);
      ok ($output{'area'}->[2], $input{'area'}->[2]);
      ok ($output{'area'}->[3], $input{'area'}->[3]);

      ok ($output{'geometry'}->[0], $input{'geometry'}->[0]);
      ok ($output{'geometry'}->[1], $input{'geometry'}->[1]);
      ok ($output{'geometry'}->[2], $input{'geometry'}->[2]);
      ok ($output{'geometry'}->[3], $input{'geometry'}->[3]);
    }
  }
}


#------------------------------------------------------------------------------

exit 0;
