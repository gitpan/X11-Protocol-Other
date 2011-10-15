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

use 5.004;
use strict;
use X11::Protocol;
use X11::Protocol::WM;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $X = X11::Protocol->new;

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
  X11::Protocol::WM::set_wm_name ($X, $window, "\x{2202}");
  # require Encode;
  # $x->changeproperty($window,
  #                    $X->atom('_NET_WM_NAME'),
  #                    $X->atom('UTF8_STRING'),   # type
  #                    8,                         # byte format
  #                    'Replace',
  #                    Encode::encode_utf8("\x{2202}"));
  $X->MapWindow ($window);

  for (;;) { $X->handle_input }
  exit 0;
}

{
  require Gtk2;
  Gtk2->init;
  my $toplevel = Gtk2::Window->new;
  $toplevel->set_title ("\x{2202}");
  $toplevel->show;
  $toplevel->get_display->flush;

  my $X = X11::Protocol->new;
  my $root = $X->{'root'};
  my ($root_root, $root_parent, @toplevels) = $X->QueryTree($root);
  ### $root_root
  ### $root_parent
  foreach my $window ($toplevel->window->XID,
                      # @toplevels
                     ) {
    ### window: sprintf '%X', $window

    if (1) {
      my @atoms = $X->ListProperties ($window);
      foreach my $atom (@atoms) {
        my ($value, $type, $format, $bytes_after)
          = $X->GetProperty ($window,
                             $atom,
                             0,  # AnyPropertyType
                             0,  # offset
                             0x7FFF_FFFF,  # length
                             0); # delete
        if (length($value)) {
          ### atom: $X->atom_name($atom)
          ### window: sprintf '%X', $window
          ### $value
          ### $type
          ### type: $type && $X->atom_name($type)
          ### $format
          ### $bytes_after
          # my @atoms = unpack 'L*', $value;
          # foreach my $atom (@atoms) {
          #   ### atom: $X->atom_name($atom)
          # }

          if ($type == $X->atom('ATOM')) {
            foreach my $at (unpack 'L*', $value) {
              ### atom: $X->atom_name($at)
            }
          }
        }
      }
    }

    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_PROTOCOLS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      ### $value
      ### $type
      ### type: $type && $X->atom_name($type)
      ### $format
      ### $bytes_after
      my @atoms = unpack 'L*', $value;
      foreach my $atom (@atoms) {
        ### atom: $X->atom_name($atom)
      }
    }
    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_HINTS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      if (length($value)) {
        ### WM_HINTS
        ### window: sprintf '%X', $window
        ### $value
        ### $type
        ### type: $type && $X->atom_name($type)
        ### $format
        ### $bytes_after
        # my @atoms = unpack 'L*', $value;
        # foreach my $atom (@atoms) {
        #   ### atom: $X->atom_name($atom)
        # }
      }
    }

    if (0) {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($window,
                           $X->atom('WM_NORMAL_HINTS'),
                           0,  # AnyPropertyType
                           0,  # offset
                           1,  # length
                           0); # delete
      if (length($value)) {
        ### WM_NORMAL_HINTS
        ### window: sprintf '%X', $window
        ### $value
        ### value length: length($value)
        ### $type
        ### type: $type && $X->atom_name($type)
        ### $format
        ### $bytes_after
        # my @atoms = unpack 'L*', $value;
        # foreach my $atom (@atoms) {
        #   ### atom: $X->atom_name($atom)
        # }
      }
    }
  }

  # ### nosuch: $X->atom_name(73281947)
  exit 0;
}


