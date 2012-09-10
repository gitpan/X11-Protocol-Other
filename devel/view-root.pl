#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use X11::Protocol::WM;

# uncomment this to run the ### lines
use Smart::Comments;


my $X = X11::Protocol->new;
my ($root, $root_parent, @toplevels) = $X->QueryTree($X->root);

my ($focus_window, $focus_revert_to) = $X->GetInputFocus;

my @remap;
foreach my $frame (@toplevels) {
  my $window = X11::Protocol::WM::frame_window_to_client($X,$frame) || next;

  my ($state, $icon_window) = X11::Protocol::WM::get_wm_state($X,$window);
  if (($state||'') eq 'NormalState') {
    ### WM_NAME: $X->GetProperty($window, $X->atom('WM_NAME'), $X->atom('STRING'), 0, 999, 0)

    X11::Protocol::WM::iconify($X, $window, $root);
    push @remap, $window;
  }

  # my %attr = $X->GetWindowAttributes ($window);
  # if ($attr{'map_state'} eq 'Viewable') {
  #   $X->UnmapWindow ($window);
  #   push @remap, $window;
  # }
}

$X->flush;
$X->QueryPointer($root); # sync
sleep 5;

### @remap
foreach my $window (@remap) {
  $X->MapWindow ($window);
}
$X->flush;
$X->QueryPointer($root); # sync
sleep 1;
$X->SetInputFocus($focus_window, $focus_revert_to, 0);

$X->QueryPointer($root); # sync
exit 0;
