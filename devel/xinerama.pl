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
  my $X = X11::Protocol->new (':0');
  ### root: $X->{'root'}

  { my @query = $X->QueryExtension('XINERAMA');
    ### @query
  }
  $X->QueryPointer($X->{'root'}); # sync

  $X->init_extension('XINERAMA') or die $@;
  $X->QueryPointer($X->{'root'}); # sync

  { my @ret = $X->PanoramiXQueryVersion (99,99);
    ### @ret
  }
  $X->QueryPointer($X->{'root'}); # sync

  my @state = $X->PanoramiXGetState ($X->{'root'});
  ### @state
  $X->QueryPointer($X->{'root'}); # sync

  my @count = $X->PanoramiXGetScreenCount ($X->{'root'});
  ### @count
  $X->QueryPointer($X->{'root'}); # sync

  my @size = $X->PanoramiXGetScreenSize ($X->{'root'}, 0);
  ### @size
  $X->QueryPointer($X->{'root'}); # sync

  my @active = $X->XineramaIsActive;
  ### @active
  $X->QueryPointer($X->{'root'}); # sync

  my @query = $X->XineramaQueryScreens ($X->{'root'}, 0);
  ### @query
  $X->QueryPointer($X->{'root'}); # sync

  # my $pixmap;
  # foreach (1 .. 37) {
  #   $pixmap = $X->new_rsrc;
  #   $X->CreatePixmap ($pixmap,
  #                     $X->{'root'},
  #                     $X->{'root_depth'},
  #                     2,2);  # width,height
  # }
  # $X->QueryPointer($X->{'root'}); # sync
  # 
  # { my @res = $X->XineramaQueryClientResources ($pixmap);
  #   ### @res
  #   foreach (@res) {
  #     printf "%s (atom %d)   %d\n", atom_name_maybe($X,$_->[0]), @$_;
  #   }
  # }
  # 
  # foreach my $client (@clients) {
  #   my $xid = $client->[0];
  #   my @res = $X->XineramaQueryClientResources ($xid);
  #   printf "\nclient %X\n", $xid;
  #   foreach (@res) {
  #     printf "%s (atom %d)   %d\n", atom_name_maybe($X,$_->[0]), @$_;
  #   }
  # }
  # 
  # { my @bytes = $X->XineramaQueryClientPixmapBytes ($pixmap);
  #   ### @bytes
  # }
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
