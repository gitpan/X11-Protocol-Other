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

my $test_count = 4;
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
    = $X->QueryExtension('MIT-SCREEN-SAVER');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no MIT-SCREEN-SAVER on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("MIT-SCREEN-SAVER extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('MIT-SCREEN-SAVER')) {
  die "QueryExtension says MIT-SCREEN-SAVER avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

my $mit_obj = $X->{'ext'}->{'MIT_SCREEN_SAVER'}->[3];
ok (!!$mit_obj, 1, 'Mit object');

#------------------------------------------------------------------------------
# MitScreenSaverQueryVersion

{
  my ($major, $minor) = $X->MitScreenSaverQueryVersion (1,0);
  MyTestHelpers::diag ("MIT-SCREEN-SAVER extension version $major.$minor");
}


#------------------------------------------------------------------------------
# MitScreenSaverKind enum

{
  ok ($X->num('MitScreenSaverKind','Blanked'),  0);
  ok ($X->num('MitScreenSaverKind','Internal'), 1);
  ok ($X->num('MitScreenSaverKind','External'), 2);

  # ok ($X->interp('DbeSwapAction',0), 'Undefined');
  # ok ($X->interp('DbeSwapAction',1), 'Background');
  # ok ($X->interp('DbeSwapAction',2), 'Untouched');
  # ok ($X->interp('DbeSwapAction',3), 'Copied');
}

#------------------------------------------------------------------------------

exit 0;
