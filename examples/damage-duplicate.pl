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


# Usage: perl damage-duplicate.pl [--id WindowID]
#
# This is an example of duplicating the contents of a window in real-time by
# listening for changes to the source window with the DAMAGE extension.
#
# A new $window toplevel displays the contents of a $source window.  The key
# feature of the damage extension is that it reports when $source changes.
# Without that a duplicating program like this would have to re-copy every 1
# second or something like that.
#
# Details:
#
# The window chooser code is an ugly chunk.  All it does is let the user
# click on a window to be the $source, if not supplied as a "--id" on the
# command line.  It's similar to what the X utility programs like xwininfo
# and xprop have in their private dmsimple.c Select_Window(), and the search
# down past the window manager frame is similar to what XmuClientWindow()
# does.  It might go into a module subroutine one day :-).
#
# In the event_handler() code care is taken not to do anything which reads a
# reply.  This is because reading the reply may also read and process other
# events, calling to event_handler() recursively and possibly endlessly.
# Any event handler should bear that in mind.  In this program if the
# $source window is changing rapidly then a new DamageNotify event may come
# very soon after each DamageSubtract().
#
# The $gc used for copying has graphics_expose off, which means any regions
# not available in the source window (obscured by other windows) are cleared
# and left as the destination background colour.
#
# In the core protocol there's no easy way to get content from $source when
# it's obscured, since the server generally doesn't keep the contents of
# obscured windows, and further since a good program won't draw at all if
# fully obscured.
#
# If the "Composite" extension is available then it does exposes and content
# retention of overlapped windows.  CompositeRedirectWindow() in the setups
# is all that's needed to have full $source contents available for the
# CopyArea()s.
#
# For simplicity the entire source window is copied whenever it changes.  In
# a more sophisticated program the "$parts_region" of changes from the
# damage object could be a clip mask for the CopyArea().  Changes outside
# the duplicated area would then go back and forward as DamageNotify and
# CopyArea, but the server can notice clip region means no actual drawing is
# needed.
#
# If $window is bigger than the $source then the excess is cleared.  Some
# care is taken to clear only the excess area, not merely the whole of
# $window, since the latter way would make it flash to black and then to the
# copy of $source.  On a fast screen you might not notice, but on a slower
# screen or if the server is a bit bogged down it's unattractive.
#
# Limitations:
#
# The created $window is always on the same screen as $source and uses the
# same depth, visual and colormap.  Doing so means a simple CopyArea
# suffices to copy the contents across.  If source and destination were
# different depth, visual or colormap then pixel conversions would be
# required.  Or if the destination was on a different server then some data
# transfers with perhaps GetImage() and PutImage() would be needed, plus
# pixel conversions.
#

use 5.004;
use strict;
use Getopt::Long;
use X11::Protocol;
use X11::AtomConstants;

use lib 'devel', '.';

# uncomment this to run the ### lines
#use Smart::Comments;

my $X = X11::Protocol->new (':0');

if (! $X->init_extension('DAMAGE')) {
  print "DAMAGE extension not available on the server\n";
  exit 1;
}

#------------------------------------------------------------------------------
# command line

my $source;       # source window to duplicate
my $verbose = 1;
GetOptions ('source=s' => \$source,
            'verbose+' => \$verbose)
  or exit 1;

#------------------------------------------------------------------------------
# choose source window

my $popup_time;

if ($source) {
  # command line --id
  # allow hex style 0xA0000F style as well as decimal
  $source = oct($source);

} else {
  # ask the user to click on a window

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");

  # "crosshair" cursor
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # font
                         $cursor_font,  # mask font
                         34,      # "crosshair"
                         34+1,    # and its mask
                         0,0,0,                    # foreground, black
                         0xFFFF, 0xFFFF, 0xFFFF);  # background, white

  my $status = $X->GrabPointer
    ($X->root,       # window
     0,              # owner events
     $X->pack_event_mask('ButtonPress','ButtonRelease'),
     'Synchronous',  # pointer mode
     'Asynchronous', # keyboard mode
     $X->root,       # confine window
     $cursor,        # crosshair cursor
     'CurrentTime');
  if ($status ne 'Success') {
    print "Cannot grab mouse pointer to select a window: $status\n";
    exit 1;
  }

  print "Click on a window to duplicate ...\n";

  my $ungrab_time;
  my $released = 0;
  local $X->{'event_handler'} = sub {
    my (%h) = @_;
    ### %h
    my $name = $h{'name'};
    if ($name eq 'ButtonPress') {
      $source = $h{'child'};
      $popup_time = $h{'time'};
    } elsif ($name eq 'ButtonRelease') {
      if ($source) {  # only after a ButtonPress, not if button already down
        $released = 1;
        $ungrab_time = $h{'time'};
      }
    }
  };
  # wait for button pressed to choose window, and then released so the
  # release event doesn't go to the chosen window
  while (! $source  || ! $released) {
    $X->AllowEvents ('SyncPointer', 'CurrentTime');
    $X->handle_input;
  }
  $X->UngrabPointer ($ungrab_time);
  print "... got it\n";
  ### source: sprintf '%X', $source

  # skip down past the window manager frame by looking for a WM_STATE property
  my @search = ($source);
  my $property = $X->atom('WM_STATE');
  for (;;) {
    my $child = shift @search;
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($child, $property, 'AnyPropertyType',
                         0,  # offset
                         0,  # length
                         0); # delete;
    if ($type) {
      if ($verbose) {
        print "Successfully skipped down through window manager frame\n";
      }
      $source = $child;
      last;
    }
    my ($root, $parent, @children) = $X->QueryTree ($child);
    push @search, @children;
  }

  $X->FreeCursor ($cursor);
  $X->CloseFont ($cursor_font);
}

if ($source eq 'None' || $source == $X->root) {
  print "Cannot duplicate root window\n";
}
if ($verbose) {
  printf "Source window %d (0x%X)\n", $source, $source;
}


#------------------------------------------------------------------------------

# use the Composite extension, if available, to keep the contents of $source
# if it's overlapped by other windows.
if ($X->init_extension('Composite')) {
  $X->CompositeRedirectWindow ($source, 'Automatic');
}

my %source_geom = $X->GetGeometry($source);
my %source_attr = $X->GetWindowAttributes($source);

# create new output window to show a duplicate of $source
# same depth, visual, colormap
my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $source_geom{'depth'},
                  $source_attr{'visual'},
                  0,0,              # x,y
                  100,100,          # w,h initial size
                  0,                # border
                  colormap         => $source_attr{'colormap'},
                  background_pixel => $X->black_pixel,
                  event_mask       => $X->pack_event_mask('Exposure'),
                 );
$X->ChangeProperty($window,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'Duplicate Window'); # window title
$X->ChangeProperty($window,
                   $X->atom('_NET_WM_USER_TIME'),
                   X11::AtomConstants::CARDINAL, # type
                   32,                           # format
                   'Replace',
                   pack('L',$popup_time));
$X->MapWindow ($window);

# select ConfigureNotify from $source, to know when it resizes
$X->ChangeWindowAttributes
  ($source,
   event_mask => $X->pack_event_mask('StructureNotify'));

# the damage object to monitor $source
# creating this gives DamageNotify events
my $damage = $X->new_rsrc;
$X->DamageCreate ($damage, $source, 'NonEmpty');

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $window,
              subwindow_mode => 'IncludeInferiors',
              # no "graphics exposures", don't want GraphicsExpose events if
              # a part of the $X->CopyArea is obscured
              graphics_exposures => 0);

sub event_handler {
  my (%h) = @_;
  my $name = $h{'name'};
  ### event_handler()
  ### $name
  if ($name eq 'ConfigureNotify') {
    # $source has resized
    ### height: $h{'height'}
    my $width = $h{'width'};    # of $source
    my $height = $h{'height'};
    # clear any excess if $source has shrunk
    $X->ClearArea ($window, $width,0, 0,0);  # to left of $width
    $X->ClearArea ($window, 0,$height, 0,0); # below $height
    # copy any extra if $source has expanded
    $X->CopyArea ($source, $window, $gc,
                  0,0,                       # src x,y
                  $h{'width'},$h{'height'},  # src w,h
                  0,0);                      # dst x,y

  } elsif ($name eq 'DamageNotify') {
    # $source has been drawn into
    my $rect = $h{'geometry'};
    my ($root_x, $root_y, $width, $height) = @$rect;
    ### $rect
    $X->DamageSubtract ($damage, 'None', 'None');
    $X->CopyArea ($source, $window, $gc,
                  0,0,         # src x,y
                  $width,$height,
                  0,0);        # dst x,y

  } elsif ($name eq 'Expose') {
    # our $window revealed, draw it
    $X->CopyArea ($source, $window, $gc,
                  $h{'x'},$h{'y'},           # src x,y
                  $h{'width'},$h{'height'},  # src w,h
                  $h{'x'},$h{'y'});          # dst x,y
  }
}

$X->{'event_handler'} = \&event_handler;
for (;;) {
  $X->handle_input;
}
exit 0;
