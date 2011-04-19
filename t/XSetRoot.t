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

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = 4;
plan tests => $test_count;

{
  my $have_x11_protocol = eval { require X11::Protocol; 1 };
  if (! $have_x11_protocol) {
    MyTestHelpers::diag ('X11::Protocol not available -- ',$@);
    foreach (1 .. $test_count) {
      skip ('X11::Protocol not available', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);
}
{
  my $have_x11_protocol_other = eval { require X11::Protocol::Other; 1 };
  if (! $have_x11_protocol_other) {
    MyTestHelpers::diag ('X11::Protocol::Other not available -- ',$@);
    foreach (1 .. $test_count) {
      skip ('X11::Protocol::Other not available', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("X11::Protocol::Other version ", X11::Protocol::Other->VERSION);
}

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

require X11::Protocol::XSetRoot;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 4;
ok ($X11::Protocol::XSetRoot::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::XSetRoot->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::XSetRoot->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::XSetRoot->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# set_background()

X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'black');

X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'white');

X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'green');

X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixel => $X->{'black_pixel'});

X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixmap => 0);

X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixmap => 'None');

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->{'root'},
                    $X->{'root_depth'},
                    1,1);  # width,height
  X11::Protocol::XSetRoot->set_background
      (X => $X,
       pixmap => $pixmap);
}

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->{'root'},
                    $X->{'root_depth'},
                    1,1);  # width,height
  $X->QueryPointer($X->{'root'});  # sync
  X11::Protocol::XSetRoot->set_background
      (X => $X,
       pixmap => $pixmap,
       pixmap_allocated_colors => 1);
  undef $X;
}



#------------------------------------------------------------------------------

exit 0;
