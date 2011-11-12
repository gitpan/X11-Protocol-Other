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

use strict;
use X11::Protocol;
use Test;

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
#BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 2)[1];
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

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('XFIXES');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XFIXES on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XFIXES extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XFIXES')) {
  die "QueryExtension says XFIXES avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

{
  my $client_major = 5;
  my $client_minor = 0;
  my ($server_major, $server_minor) = $X->XFixesQueryVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("XFixesQueryVersion ask for $client_major.$client_minor got server version $server_major.$server_minor");
  if ($server_major < $client_major) {
    foreach (1 .. $test_count) {
      skip ("QueryVersion() no XFIXES $client_major.$client_minor on the server", 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# XFixesCreatePointerBarrier() / XFixesDestroyPointerBarrier()

{
  my $barrier = $X->new_rsrc;
  $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 200,100,
                                  0);
  $X->QueryPointer($X->root); # sync

  $X->XFixesDestroyPointerBarrier ($barrier);
  $X->QueryPointer($X->root); # sync

  ok (1,1, 'plain barrier');
}

#------------------------------------------------------------------------------
# XFixesCreatePointerBarrier() / XFixesDestroyPointerBarrier()
# with XInputExtension style "AllDevices"
#
# Saw xvfb 1.11.1.901 server giving "Implementation" (17) error when passing
# AllDevices.  Ignore that, but still throw a normal error for anything
# else, like bad length etc.

{
  my $barrier = $X->new_rsrc;

  my $orig_error_handler = $X->{'error_handler'};
  local $X->{'error_handler'} = sub {
    my ($X, $data) = @_;
    ### error handler
    ### $data

    my ($type, $seq, $info, $minor_op, $major_op) = unpack 'xCSLSC', $data;
    if ($X->interp('Error',$type) eq 'Implementation') {
      MyTestHelpers::diag ("ignore XFixesCreatePointerBarrier error \"Implementation\" for xinput device \"AllDevices\"");
      undef $barrier;
    } else {
      goto $orig_error_handler;
    }
  };

  ### request ...
  $X->XFixesCreatePointerBarrier ($barrier, $X->root, 100,100, 200,100,
                                  0,
                                  'AllDevices');
  ### sync ...
  $X->QueryPointer($X->root);
  ### sync ok ...

  if (defined $barrier) {
    $X->XFixesDestroyPointerBarrier ($barrier);
    $X->QueryPointer($X->root); # sync
  }
  ok (1,1, 'AllDevices barrier');
}

#------------------------------------------------------------------------------

exit 0;
