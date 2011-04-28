#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = 4;
plan tests => $test_count;

use X11::Protocol::WM
  'set_wm_hints',
  'set_wm_transient_for',
  'set_net_wm_window_type';

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  MyTestHelpers::diag ('No DISPLAY set');
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("DISPLAY $display");

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ("Cannot connect to X server -- $@");
  foreach (1 .. $test_count) {
    skip ("Cannot connect to X server", 1, 1);
  }
  exit 0;
}

$X->QueryPointer($X->{'root'});  # sync

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->{'root'},     # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border
my $window2 = $X->new_rsrc;
$X->CreateWindow ($window2,
                  $window,          # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  1,1,              # width,height
                  0);               # border


set_wm_hints($X,$window,input=>1);
set_wm_transient_for($X,$window2,$window);
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window2,
                       $X->atom('WM_TRANSIENT_FOR'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('WINDOW'));
  my ($unpack) = unpack 'L', $value;
  ok ($unpack, $window);

  # ok ($window, get_wm_transient_for($X,$window2,$window));
}
set_net_wm_window_type($X,$window,'SPLASH');

$X->QueryPointer($X->{'root'});  # sync
ok (1, 1);

exit 0;