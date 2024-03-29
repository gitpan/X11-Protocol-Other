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

use lib 'devel/lib';


use strict;
use X11::Protocol;
use X11::Protocol::WM;
use X11::Protocol::ChooseWindow;


# uncomment this to run the ### lines
use Smart::Comments;

my $X = X11::Protocol->new (':0');
# my $chooser = X11::Protocol::ChooseWindow->new (X => $X);

my $window = X11::Protocol::ChooseWindow->choose (
                                                  # X => $X,
                                                  screen => 0,
                                                  # display => ':2',
                                                  # want_frame_window => 0,
                                                  # cursor => 'None',
                                                 );
printf "%s 0x%X\n", $window, ($window eq 'None' ? 0 : $window);

{
  my ($str, $type, $format, $bytes_after) = $X->GetProperty ($window, $X->atom('WM_NAME'), $X->atom('STRING'), 0, 999, 0);
  print "WM_NAME $str\n";
}
{
  my ($str, $type, $format, $bytes_after) = $X->GetProperty ($window, $X->atom('WM_CLASS'), $X->atom('STRING'), 0, 999, 0);
  print "WM_CLASS $str\n";
}

if ($window ne 'None') {
  my $client_window = X11::Protocol::WM::frame_window_to_client ($X, $window);
  printf "%s 0x%X\n", $client_window, $client_window;
}

exit 0;
