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


# Usage: perl xfixes-cursor-image.pl
#
# This is an example of getting the mouse pointer cursor image with XFIXES.
#
# XFixesGetCursorImage() retrieves the cursor image.  CursorNotify events
# report when it changes.  That's normally due to moving into a window with
# a "cursor" attribute, but can also be a pointer grab, or even an animated
# cursor from the RENDER extension.
#
# The only painful thing is that GetCursorImage gives 8-bit RGBA, so it's
# necessary to allocate colours etc to display that in a window.  In the
# code here its drawn to a pixmap, then that pixmap put up under Expose.
#
# XFixesGetCursorImage() isn't done in the "event_handler" code, since it's
# a round-trip request and waiting for the reply might read new events and
# call the event_handler recursively.  If badly lagged and continually
# getting CursorNotify or whatever then that could be a very deep recursion,
# or make a mess of the drawing code.  So the event_handler just notes a
# fresh get is required and that's done in the main $X->handle_input() loop.
#
# With only the core X protocol there's no real way to get the current
# cursor or its image.  The windows cursor attribute can't be read back with
# GetWindowAttributes(), and all the area copying things, including
# GetImage(), ignore the cursor.
#
# Things Not Done:
#
# The display window is a fixed 63x63 and the image positioned so the
# hotspot is always at 31,31.  This fits a cursor of up to 32x32.  A real
# program might centre the hotspot in the current window size (listening to
# ConfigureNotify), and might make the pixmap only the size of the cursor
# then draw it at the right place.
#
# The ChangeGC() plus PolyPoint() for each pixel is a bit wasteful.  Better
# would be to send all the pixels in one PutImage(), but building the
# server's required bit units, byte order and padding is bit like hard work.
#
# The alpha channel in the cursor image is only mapped to a pixel drawn or
# not.  It might be combined with the grey window background without too
# much trouble.  What's the right multiplication?
#

use strict;
use X11::Protocol;
use X11::AtomConstants;

# uncomment this to run the ### lines
#use Smart::Comments;

my $X = X11::Protocol->new;
if (! $X->init_extension('XFIXES')) {
  print "XFIXES extension not available on the server\n";
  exit 1;
}

my $colormap = $X->default_colormap;

# rgb8_to_pixel() takes colour components 0 to 255 and returns a pixel value
# suitable for $window and $pixmap.  Black and white pixel values from the
# $X screen info can be pre-loaded, other colours have to be allocated.
#
my %allocated_pixels = ('0.0.0'       => $X->black_pixel,
                        '255.255.255' => $X->white_pixel);
sub rgb8_to_pixel {
  my ($red, $green, $blue) = @_;
  my $key = "$red.$green.$blue";
  my $pixel = $allocated_pixels{$key};
  if (! defined $pixel) {
    ($pixel) = $X->AllocColor ($colormap,
                               $red * 0x101, $green * 0x101, $blue * 0x101);
    $allocated_pixels{$key} = $pixel;
  }
  return $pixel;
}

# grey
my ($background_pixel) =$X->AllocColor ($colormap, 0x9000,0x9000,0x9000);

my $window = $X->new_rsrc;
$X->CreateWindow ($window,
                  $X->root,         # parent
                  'InputOutput',    # class
                  $X->root_depth,   # depth
                  'CopyFromParent', # visual
                  0,0,              # x,y
                  63,63,            # w,h initial size
                  0,                # border
                  background_pixel => $background_pixel,
                  event_mask       => $X->pack_event_mask('Exposure'),
                 );
$X->ChangeProperty($window,
                   X11::AtomConstants::WM_NAME,  # property
                   X11::AtomConstants::STRING,   # type
                   8,                            # byte format
                   'Replace',
                   'Current Cursor'); # window title

my $pixmap = $X->new_rsrc;
$X->CreatePixmap ($pixmap,
                  $window,
                  $X->root_depth,
                  63,63);  # width,height

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $pixmap,
              # don't need NoExpose when copying from $pixmap
              graphics_exposures => 0);


my $want_get_image = 1;
my $current_cursor_serial = -1;

$X->{'event_handler'} = sub {
  my (%h) = @_;
  ### event_handler: \%h

  if ($h{'name'} eq 'XFixesCursorNotify') {
    if ($h{'cursor_serial'} != $current_cursor_serial) {
      $want_get_image = 1;
    }

  } elsif ($h{'name'} eq 'Expose') {
    $X->CopyArea ($pixmap, $window, $gc,
                  0,0,    # src x,y
                  63,63,  # src w,h
                  0,0);   # dst x,y
  }
};

$X->XFixesSelectCursorInput ($window, 1);
$X->MapWindow($window);

for (;;) {
  $X->handle_input;

  if ($want_get_image) {
    my ($root_x,$root_y, $width,$height, $xhot,$yhot, $serial, $cursor_pixels)
      = $X->XFixesGetCursorImage;
    $current_cursor_serial = $serial;

    $X->ChangeGC ($gc, foreground => $background_pixel);
    $X->PolyFillRectangle ($pixmap, $gc, [0,0, 63,63]);

    my $pos = 0;
    foreach my $y (0 .. $height-1) {
      foreach my $x (0 .. $width-1) {

        my $argb = unpack 'L', substr($cursor_pixels,$pos,4);
        my $alpha = ($argb >> 24) & 0xFF;
        my $red   = ($argb >> 16) & 0xFF;
        my $green = ($argb >> 8)  & 0xFF;
        my $blue  =  $argb        & 0xFF;
        $pos += 4;

        if ($alpha >= 128) {
          my $pixmap_pixel = rgb8_to_pixel($red, $green, $blue);
          $X->ChangeGC ($gc, foreground => $pixmap_pixel);
          $X->PolyPoint ($pixmap, $gc, 'Origin',
                         # hotspot at position x=31,y=31 in the display
                         $x + 31-$xhot,
                         $y + 31-$yhot);
        }
      }
    }
    $X->CopyArea ($pixmap, $window, $gc,
                  0,0,    # src x,y
                  63,63,  # src w,h
                  0,0);   # dst x,y

    # print "Cursor size ${width}x${height}\n";
  }
}

exit 0;
