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

# ... waiting for XFIXES ...



# Tests of DAMAGE 1.1 things when available, being DamageAdd.

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

my $test_count = 16;
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
    = $X->QueryExtension('DAMAGE');
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no DAMAGE on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("DAMAGE extension opcode=$major_opcode event=$first_event error=$first_error");
}
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

if (! $X->init_extension ('DAMAGE')) {
  die "QueryExtension says DAMAGE avaiable, but init_extension() failed";
}
if (! $X->init_extension ('XFIXES')) {
  die "QueryExtension says XFIXES avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync

my $damage_obj = $X->{'ext'}->{'DAMAGE'}->[3];
MyTestHelpers::diag ("DAMAGE extension version $damage_obj->{'major'}.$damage_obj->{'minor'}");
unless (($damage_obj->{'major'} <=> 1 || $damage_obj->{'minor'} <=> 1) >= 0) {
  MyTestHelpers::diag ("DAMAGE 1.1 not available");
  foreach (1 .. $test_count) {
    skip ('no DamageAdd on server', 1, 1);
  }
  exit 0;
}

#------------------------------------------------------------------------------
# DamageAdd / DamageNotify

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->root,
                    $X->root_depth,
                    200,100);  # width,height

  my $damage = $X->new_rsrc;
  $X->DamageCreate ($damage, $pixmap, 'BoundingBox');

  my %notify;
  local $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
    if ($h{'name'} eq 'DamageNotify') {
      %notify = %h;
    }
  };

  my $region = $X->new_rsrc;
  $X->XFixesCreateRegion ($region, [10,11, 40,50]);

  $X->DamageAdd ($pixmap, $region);
  # sync, so as to wait for the DamageNotify
  $X->QueryPointer($X->root);

  ok (!!$notify{'synthetic'}, '', 'DamageAdd/DamageNotify - synthetic');

  ok ($notify{'damage'}, $damage, 'DamageAdd/DamageNotify - damage');
  ok ($notify{'drawable'}, $pixmap, 'DamageAdd/DamageNotify - drawable');
  ok ($notify{'level'}, 'BoundingBox', 'DamageAdd/DamageNotify - level');
  ok ($notify{'more'}, 0, 'DamageAdd/DamageNotify - more');
  ok ($notify{'time'} != 0, 1, 'DamageAdd/DamageNotify - time');

  my $area = $notify{'area'};
  ok (ref $area, 'ARRAY', 'DamageAdd/DamageNotify - area');
  ok ($area && $area->[0], 10, 'DamageAdd/DamageNotify - area[0]');
  ok ($area && $area->[1], 11, 'DamageAdd/DamageNotify - area[1]');
  ok ($area && $area->[2], 40, 'DamageAdd/DamageNotify - area[2]');
  ok ($area && $area->[3], 50, 'DamageAdd/DamageNotify - area[3]');

  my $geometry = $notify{'geometry'};
  ok (ref $geometry, 'ARRAY', 'DamageAdd/DamageNotify - geometry');
  ok ($geometry && $geometry->[0], 0, 'DamageAdd/DamageNotify - geometry[0]');
  ok ($geometry && $geometry->[1], 0, 'DamageAdd/DamageNotify - geometry[1]');
  ok ($geometry && $geometry->[2],200, 'DamageAdd/DamageNotify - geometry[2]');
  ok ($geometry && $geometry->[3],100, 'DamageAdd/DamageNotify - geometry[3]');

  $X->DamageDestroy ($damage);
}

#------------------------------------------------------------------------------

exit 0;
