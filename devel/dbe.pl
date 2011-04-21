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

use strict;
use X11::Protocol;

use lib 'devel', '.';

# uncomment this to run the ### lines
use Smart::Comments;

{
  # require("X11/Protocol/Ext/DBE.pm");

  my $X = X11::Protocol->new ($ENV{'DISPLAY'} || ':0');
  $X->init_extension('DOUBLE-BUFFER') or die;

  { my @version = $X->DbeGetVersion (99,99);
    ### @version
  }
  $X->QueryPointer($X->{'root'}); # sync

  { my @infos = $X->DbeGetVisualInfo($X->root);
    ### @infos
  }
  $X->QueryPointer($X->{'root'}); # sync

  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### event_handler: \%h
  };

  $X->init_extension('DBE') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");

  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,
                         'None',  # mask font
                         3,
                         0,
                         0xFFFF, 0xFFFF, 0xFFFF,
                         0,0,0);
  $X->QueryPointer($X->{'root'}); # sync

  # { my @reqdata = $X->get_request('DbeGetCursorName');
  #   ### @reqdata
  # }
  { my @ret = $X->DbeGetCursorName ($cursor);
    ### DbeGetCursorName: @ret
  }
  $X->QueryPointer($X->{'root'}); # sync

  my $region = $X->new_rsrc;
  $X->DbeCreateRegion ($region);
  $X->QueryPointer($X->{'root'}); # sync

  my $region_dst = $X->new_rsrc;
  $X->DbeCreateRegion ($region_dst);
  $X->DbeExpandRegion ($region, $region_dst, 1,1,1,1);
  $X->QueryPointer($X->{'root'}); # sync

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->root,         # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    100,100,          # width,height
                    0,                # border
                    background_pixel => $X->black_pixel,
                   );
  $X->MapWindow ($window);
  sleep 1;
  $X->QueryPointer($X->{'root'}); # sync

  $region = $X->new_rsrc;
  $X->DbeCreateRegionFromWindow ($region, $window, 'Bounding');
  { my @ret = $X->DbeFetchRegion ($region);
    ### @ret
  }


  $X->DbeSelectCursorInput ($X->root, 1);
  $X->QueryPointer($X->{'root'}); # sync
  $X->handle_input;

  exit 0;
}

sub atom_name_maybe {
  my ($X, $atom) = @_;
  my $ret = $X->robust_req ('GetAtomName', $atom);
  if (ref $ret) {
    return @$ret;
  }
  return '[not-atom]';
}
