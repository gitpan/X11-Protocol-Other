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

my $test_count = 10;
plan tests => $test_count;

require X11::Protocol::Other;

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
MyTestHelpers::X11_server_info($X);

$X->QueryPointer($X->{'root'});  # sync

#------------------------------------------------------------------------------
# VERSION

my $want_version = 2;
ok ($X11::Protocol::Other::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::Other->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::Other->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::Other->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# root_to_screen()

{
  ## no critic (ProtectPrivateSubs)
  my $screens_aref = $X->{'screens'};
  my $good = 1;
  foreach my $screen_number (0 .. $#$screens_aref) {
    my $rootwin = $screens_aref->[$screen_number]->{'root'}
      || die "oops, no 'root' under screen $screen_number";
    my $got = X11::Protocol::Other::root_to_screen($X,$rootwin);
    if (! defined $got || $got != $screen_number) {
      $good = 0;
      MyTestHelpers::diag ("root_to_screen() wrong on rootwin $rootwin screen $screen_number");
      MyTestHelpers::diag ("got ", (defined $got ? $got : 'undef'));
    }
  }
  ok ($good, 1, "root_to_screen()");
}

#------------------------------------------------------------------------------
# visual_class_is_dynamic()

{
  my $visual_class = 'PseudoColor';
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      1,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 3;
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      1,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 'TrueColor';
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      0,
      "visual_class_is_dynamic() $visual_class");
}
{
  my $visual_class = 4;
  ok (X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class),
      0,
      "visual_class_is_dynamic() $visual_class");
}

#------------------------------------------------------------------------------
# visual_is_dynamic()

{
  my $good = 1;
  foreach (keys %{$X->{'visuals'}}) {
    my $visual_id = $_;
    my $visual_class = $X->{'visuals'}->{$visual_id}->{'class'};
    my $got = X11::Protocol::Other::visual_is_dynamic($X,$visual_id);
    my $want = X11::Protocol::Other::visual_class_is_dynamic($X,$visual_class);
    if ($got != $want) {
      MyTestHelpers::diag ("wrong: visual_id $visual_id visual_class $visual_class got $got want $want");
      $good = 0;
    }
  }
  ok ($good, 1,
     'visual_is_dynamic() ');
}

#------------------------------------------------------------------------------
$X->QueryPointer($X->{'root'});  # sync

exit 0;
