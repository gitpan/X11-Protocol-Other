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

my $test_count = 25;
plan tests => $test_count;

require X11::Protocol::WM;

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

#------------------------------------------------------------------------------
# VERSION

my $want_version = 6;
ok ($X11::Protocol::WM::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::WM->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::WM->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::WM->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# set_wm_transient_for()

{
  my $elem;
  foreach $elem ([$window, $window], # a window
                 [0, 0],             # 0==None
                 ['None', 0],        # 0==None
                 [undef, undef],     # delete
                ) {
    my ($transient_for, $want) = @$elem;
    X11::Protocol::WM::set_wm_transient_for ($X, $window2, $transient_for);

    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window2,
                         $X->atom('WM_TRANSIENT_FOR'),
                         'AnyPropertyType',
                         0,  # offset
                         1,  # length, 1 x CARD32
                         0); # delete
    ok ($format, (defined $want ? 32 : 0));
    ok ($type, (defined $want ? $X->atom('WINDOW') : 0));
    my $type_name = ($type ? $X->atom_name($type) : 'None');
    ok ($type_name, (defined $want ? 'WINDOW' : 'None'));
    my ($got) = unpack 'L', $value;
    ok ($got, $want, $window);
  }
}

#------------------------------------------------------------------------------
# get_wm_transient_for()
# ok ($window,
#     X11::Protocol::WM::get_wm_transient_for($X,$window2,$window),
#    'get_wm_transient_for()/set_wm_transient_for()');


#------------------------------------------------------------------------------
# set_wm_hints()

X11::Protocol::WM::set_wm_hints ($X, $window,
                                 input => 1,
                                 initial_state => 'NormalState',
                                 icon_x  => -1,
                                 icon_y  => -1,
                                 urgency => 1,
                                );

#------------------------------------------------------------------------------
# _wm_unpack_wm_hints()

# {
#   my $format = 'LLLLLllLL';
#
#   foreach ([ pack($format,0,(0)x8) ],
#            [ pack($format,0,(0)x7) ],  # short from X11R2 ?
#
#            [ pack($format,1,0,(0)x7), input => 0 ],
#            [ pack($format,1,1,(0)x7), input => 1 ],
#
#            [ pack($format,2,0,1,(0)x6), initial_state => 'NormalState' ],
#            [ pack($format,2,0,3,(0)x6), initial_state => 'IconicState' ],
#
#            [ pack($format, 16, 0,0,0,0, 123,456, 0,0),
#              icon_x => 123, icon_y => 456 ],
#            [ pack($format, 16, 0,0,0,0, -123,-456, 0,0),
#              icon_x => -123, icon_y => -456 ],
#
#            [ pack($format, 64, 0,0,0,0, 0,0, 0,0), window_group => 0 ],
#            [ pack($format, 64, 0,0,0,0, 0,0, 0,123), window_group => 123 ],
#            [ pack($format, 256, (0)x8), urgency => 1 ],
#           ) {
#     my $elem = $_;
#     my ($bytes, @want) = @$elem;
#     my @got = X11::Protocol::WM::_unpack_wm_hints($X,$bytes);
#     my $good = 1;
#     ok (scalar(@got), scalar(@want));
#     for (my $i = 0; $i < @got && $i < @want; $i++) {
#       unless ((! defined $got[$i] && ! defined $want[$i])
#               || (defined $got[$i] && defined $want[$i]
#                   && $got[$i] eq $want[$i])) {
#         $good = 0;
#         MyTestHelpers::diag ("Got ",$got[$i]," want ",$want[$i]);
#       }
#     }
#     ok ($good, 1);
#   }
# }


#------------------------------------------------------------------------------
# set_net_wm_window_type()

X11::Protocol::WM::set_net_wm_window_type ($X, $window, 'NORMAL');
{
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_WINDOW_TYPE'),
                       'AnyPropertyType',
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  ok ($format, 32);
  ok ($type, $X->atom('ATOM'));
  ok ($X->atom_name($type), 'ATOM');
  my ($value_atom) = unpack 'L', $value;
  ok ($value_atom, $X->atom('_NET_WM_WINDOW_TYPE_NORMAL'));
  ok ($X->atom_name($value_atom), '_NET_WM_WINDOW_TYPE_NORMAL');
}

#------------------------------------------------------------------------------
# get_net_wm_window_type()
# {
#   my $atom_name = $X->atom_name($atom);
#   ok ($atom_name, '_NET_WM_WINDOW_TYPE_NORMAL', 'set_net_wm_window_type');
# 
#   # my $atom = X11::Protocol::WM::_get_net_wm_window_type_atom ($X, $window);
# }

#------------------------------------------------------------------------------
$X->QueryPointer($X->{'root'});  # sync

exit 0;
