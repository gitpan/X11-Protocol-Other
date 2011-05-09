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

use lib 'devel', '.';



use strict;
use X11::Protocol;
use Test;

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = 18;
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
$X->QueryPointer($X->root);  # sync

{
  my ($major_opcode, $first_event, $first_error)
    = $X->QueryExtension('DOUBLE-BUFFER');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no DOUBLE-BUFFER on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("DOUBLE-BUFFER extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('DOUBLE-BUFFER')) {
  die "QueryExtension says DOUBLE-BUFFER avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

my $dbe_obj = $X->{'ext'}->{'DOUBLE_BUFFER'}->[3];
ok (!!$dbe_obj, 1, 'Dbe object');
MyTestHelpers::diag ("DOUBLE-BUFFER extension version $dbe_obj->{'major'}.$dbe_obj->{'minor'}");


#------------------------------------------------------------------------------
# DbeSwapAction enum

{
  ok ($X->num('DbeSwapAction','Undefined'),  0);
  ok ($X->num('DbeSwapAction','Background'), 1);
  ok ($X->num('DbeSwapAction','Untouched'),  2);
  ok ($X->num('DbeSwapAction','Copied'),     3);

  ok ($X->num('DbeSwapAction',0), 0);
  ok ($X->num('DbeSwapAction',1), 1);
  ok ($X->num('DbeSwapAction',2), 2);
  ok ($X->num('DbeSwapAction',3), 3);

  ok ($X->interp('DbeSwapAction',0), 'Undefined');
  ok ($X->interp('DbeSwapAction',1), 'Background');
  ok ($X->interp('DbeSwapAction',2), 'Untouched');
  ok ($X->interp('DbeSwapAction',3), 'Copied');
}

#------------------------------------------------------------------------------
# DbeGetVisualInfo

my $have_root_dbe = 0;
{
  my @infos = $X->DbeGetVisualInfo ($X->root);
  $X->QueryPointer($X->{'root'}); # sync

  ok (scalar(@infos), 1);
  my $info = $infos[0];
  ok (ref $info, 'ARRAY');

  my $good = 1;
  foreach my $elem (@$info) {
    my ($visual, $depth, $perflevel) = @$elem;
    $have_root_dbe ||= ($visual == $X->root_visual);

    if (! $X->{'visuals'}->{$visual}) {
      MyTestHelpers::diag ("DbeGetVisualInfo no such visual $visual");
      $good = 0;
      next;
    }
    my $want_depth = $X->{'visuals'}->{$visual}->{'depth'};
    if ($depth != $want_depth) {
      MyTestHelpers::diag ("DbeGetVisualInfo visual $visual depth $depth but server info has $want_depth");
      $good = 0;
    }
  }
}

{
  my @infos = $X->DbeGetVisualInfo ();
  $X->QueryPointer($X->{'root'}); # sync

  my $num_screens = scalar(@{$X->{'screens'}});
  ok (scalar(@infos), $num_screens);
}

#------------------------------------------------------------------------------

{
  my $buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($X->root, $buffer, 'Copied');
  $X->QueryPointer($X->root); # sync

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, $X->root, 'GetBackBufferAttributes window');
  }

  $X->DbeBeginIdiom;
  $X->DbeEndIdiom;

  $X->DbeSwapBuffers ($X->root, 'Untouched');
  $X->DbeSwapBuffers ($X->root, 'Untouched');

  $X->DbeDeallocateBackBufferName ($buffer);
  $X->QueryPointer($X->root); # sync
}

{
  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0);               # border

  my $buffer = $X->new_rsrc;
  $X->DbeAllocateBackBufferName ($window, $buffer, 'Copied');

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, $window, 'GetBackBufferAttributes for own window');
  }

  $X->DestroyWindow ($window);

  {
    my $got_window = $X->DbeGetBackBufferAttributes ($buffer);
    ok ($got_window, 'None', 'GetBackBufferAttributes for destroyed window');
  }
}

#------------------------------------------------------------------------------

exit 0;
