#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

# uncomment this to run the ### lines
#use Smart::Comments;


my $test_count = (tests => 7)[1];
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
MyTestHelpers::diag ("DISPLAY ", $display);

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


# Something fishy with xvfb test server seems to cause the reconnect below
# to fail.  Keeping a second connection makes it better, dunno why.
my $keepalive_X = X11::Protocol->new ($display);


require X11::Protocol::XSetRoot;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 19;
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

### black ...
X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'black');

X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'white');

### green ...
X11::Protocol::XSetRoot->set_background
  (display => $display,
   color => 'green');

X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixel => $X->{'black_pixel'});

X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixmap => 0);

### None ...
X11::Protocol::XSetRoot->set_background
  (X => $X,
   pixmap => 'None');

### pixmap ...
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
# _tog_cup_pixel_is_reserved()

### new connection ...
$X = X11::Protocol->new ($display);

my $screen_num = 0;
### $screen_num

my $black_pixel = $X->{'screens'}->[$screen_num]->{'black_pixel'};
my $white_pixel = $X->{'screens'}->[$screen_num]->{'white_pixel'};

# results if TOG-CUP not initialized ... but currently always automatically
# attempted
#
# {
#   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$white_pixel),
#       0);
#   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$black_pixel),
#       0);
#   ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,-99),
#       0);
# }

{
  my $got = X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$white_pixel);

  my $have_tog_cup = ($X->init_extension('TOG-CUP') ? 1 : 0);
  MyTestHelpers::diag ("have TOG-CUP: $have_tog_cup");
  my $want_yes = ($have_tog_cup ? 1 : 0);

  ok ($got,
      $want_yes,
      'white_pixel in TOG-CUP reserved');
  ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,$black_pixel),
      $want_yes,
      'black_pixel in TOG-CUP reserved');
  ok (X11::Protocol::XSetRoot::_tog_cup_pixel_is_reserved($X,$screen_num,-99),
      0,
      'bogus pixel not in TOG-CUP reserved');
}



#------------------------------------------------------------------------------

exit 0;
