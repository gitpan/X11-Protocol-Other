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
use X11::AtomConstants;
use Carp;

# uncomment this to run the ### lines
use Smart::Comments;

{

  #------------------------------------------------------------------------------
  # MOTIF_WM_HINTS

  # set_MOTIF_WM_HINTS
  # what's in "status" ?
  # just "application_modal" ?

  # =item C<_set_motif_wm_hints ($X, $window, key=E<gt>value...)>
  #
  # Set the C<MOTIF_WM_HINTS> property on C<$window> (an XID).  These hints
  # are used by the Motif window manager and by many other compatible window
  # managers.  The key/value arguments are
  #
  #     functions       arrayref
  #     decorations     arrayref
  #     input_mode      enum string or integer
  #     status
  #
  # C<functions> is an arrayref of strings for what operations the window
  # manager should offer on the window in a drop-down menu or similar.  The
  # default is "all".
  #
  #     "all"         all functions
  #     "resize"      to resize the window
  #     "move"        to move the window
  #     "minimize"    to iconify
  #     "maximize"    to make full-screen (but still with a frame)
  #     "close"       to close the window
  #
  # C<decorations> is an arrayref of some of the following strings for what
  # visual decorations the window manager should draw around the window.  The
  # default is "all".
  #
  #     "all"          draw all decorations
  #     "border"       a border around the window
  #     "resizeh"      handles to resize by dragging
  #     "title"        show WM_NAME across the top etc
  #     "menu"         drop-down menu of "functions" above
  #     "minimize"     button minimize, ie. iconify, button
  #     "maximize"     button to maximize, ie full-screen
  #
  # C<input_mode> allows a window to be "modal", meaning the user should
  # interact only with that window.  For this the window manager will
  # generally keep it on top, not set the focus to other windows, etc.  The
  # value is one of the following strings,
  #
  #     "modeless"                         not modal (the default)
  #     "primary_application_modal"      \ modal to its "transient for" parent,
  #     "application_modal"              /  but not other toplevels
  #     "system_modal"                     modal to the whole display
  #     "full_application_modal"           modal to the current client
  #
  # C<primary_application_modal> and C<application_modal> are two names for
  # the same thing.
  #
  # C<status> field is an arrayref of some of the following strings (but
  # currently just one choice).
  #
  #     "tearoff_window"     is a tearoff menu
  #
  # In Motif C<mwm>, C<tearoff_window> means a title (C<WM_NAME>) shown in the
  # title bar is not truncated, but instead the window expanded as necessary.
  #

  sub _set_motif_wm_hints {
    my $X = shift;
    my $window = shift;
    $X->ChangeProperty($window,
                       $X->atom('_MOTIF_WM_HINTS'),  # property
                       $X->atom('_MOTIF_WM_HINTS'),  # type
                       32,                          # format
                       'Replace',
                       _pack_motif_wm_hints ($X, @_));
  }

  {
    # /usr/include/Xm/MwmUtil.h
    my $format = 'L5';
    my %key_to_flag = (functions   => 1,
                       decorations => 2,
                       input_mode  => 4,
                       status      => 8,
                      );
    my %arefargs = (functions => { all      => 1,
                                   resize   => 2,
                                   move     => 4,
                                   minimize => 8,
                                   maximize => 16,
                                   close    => 32 },
                    decorations => { all      => 1,
                                     border   => 2,
                                     resizeh  => 4,
                                     title    => 8,
                                     menu     => 16,
                                     minimize => 32,
                                     maximize => 64 },
                    status => { tearoff_window => 1,
                              },
                   );
    sub _pack_motif_wm_hints {
      my ($X, %hint) = @_;

      my $flags = 0;
      foreach my $key (keys %hint) {
        if (defined $hint{$key}) {
          $flags |= $key_to_flag{$key};
        } else {
          croak "Unrecognised MOTIF_WM_HINTS field: ",$key;
        }
      }
      foreach my $field (keys %arefargs) {
        my $bits = 0;
        if (my $h = $hint{$field}) {
          if (ref $h) {
            foreach my $key (@$h) {
              if (defined (my $bit = $arefargs{$field}->{$key})) {
                $bits |= $bit;
              } else {
                croak "Unrecognised MOTIF_WM_HINTS ",$field," field: ",$key;
              }
            }
          }
        }
        $hint{$field} = $bits;
      }
      pack ($format,
            $flags,
            $hint{'functions'},
            $hint{'decorations'},
            _motif_input_mode_num($hint{'input_mode'}) || 0,
            $hint{'status'});
    }
  }

  {
    my %input_mode_num = (modeless                  => 0,
                          primary_application_modal => 1,
                          application_modal         => 1,
                          system_modal              => 2,
                          full_application_modal    => 3,
                         );
    sub _motif_input_mode_num {
      my ($X, $input_mode) = @_;
      if (exists $input_mode_num{$input_mode}) {
        return $input_mode_num{$input_mode};
      } else {
        return $input_mode;
      }
    }
  }


}


my $X = X11::Protocol->new;

my $w1 = $X->new_rsrc;
$X->CreateWindow ($w1,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  100,100,          # width,height
                  0,                # border
                  background_pixel => $X->black_pixel,
                 );
$X->ChangeProperty($w1,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'ssssssssssssssssss ssssssssssssssssssssss sssssssssssssssssss'); # window title
$X->MapWindow ($w1);

my $w2 = $X->new_rsrc;
$X->CreateWindow ($w2,
                  $X->root,         # parent
                  'InputOutput',
                  0,                # depth, from parent
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  100,100,          # width,height
                  0,                # border
                  background_pixel => $X->black_pixel,
                 );
#_set_motif_wm_hints ($X, $w2, status => ['tearoff_window']);
$X->ChangeProperty($w2,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'jfksl jksd fjskl fjskl fjskl fjksl fjkls dlfjk slkf'); # window title
$X->MapWindow ($w2);

while (1) {
  $X->handle_input;
}
exit 0;




