# Copyright 2011 Kevin Ryde


# cursor_name omitted or undef ?
# event masks ?


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
package X11::Protocol::Ext::XFIXES;
use X11::Protocol;
use strict;

use vars '$VERSION';
$VERSION = 3;

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/share/doc/x11proto-fixes-dev/fixesproto.txt.gz
#
# /usr/include/X11/extensions/Xfixes.h
# /usr/include/X11/extensions/xfixesproto.h
# /usr/include/X11/extensions/xfixeswire.h

### XFIXES.pm loads

#------------------------------------------------------------------------------
# symbolic constants


my %const_arrays
  = (
     XFixesWindowRegionKind => ['Bounding', 'Clip'],

     XFixesSaveSetMode      => ['Insert', 'Delete'],
     XFixesSaveSetTarget    => ['Nearest', 'Root'],
     XFixesSaveSetMap       => ['Map', 'Unmap'],

     XFixesSelectionNotifySubtype => [ 'SetSelectionOwner',
                                       'SelectionWindowDestroy',
                                       'SelectionClientClose' ],
     # Not sure about this one ...
     # XFixesSelectionEventMask => [ 'SetSelectionOwner',
     #                               'SelectionWindowDestroy',
     #                               'SelectionClientClose' ],

     XFixesCursorNotifySubtype => [ 'DisplayCursor' ],
     # Not sure about this one ...
     # XFixesCursorEventMask     => [ 'DisplayCursor' ],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# events

my $XFixesSelectionNotify_event = [ 'xCxxL5',
                                    ['subtype','XFixesSelectionNotifySubtype'],
                                    'window',
                                    ['owner',['None']], # window
                                    'selection',        # atom
                                    'time',
                                    'selection_time',
                                  ];

my $XFixesCursorNotify_event
  = [ sub {
        my $X = shift;
        my $data = shift;
        ### XFixesCursorNotify unpack: @_
        my ($subtype, $window, $cursor_serial, $time, $cursor_name)
          = unpack 'xCxxL4', $data;
        return (@_,  # base fields
                subtype => $X->interp('XFixesCursorNotifySubtype',$subtype),
                window  => _interp_none($X,$window), # probably not None though
                cursor_serial => $cursor_serial,
                time    => _interp_time($time),
                # "name" field only in XFIXES 2.0 up, probably pad garbage
                # in 1.0, so omit there.  Give it as "cursor_name" since
                # plain "name" is the event name.
                ($X->{'ext'}->{'XFIXES'}->[3]->{'major'} >= 2
                 ? (cursor_name => $cursor_name)
                 : ()));
      },
      sub {
        my ($X, %h) = @_;
        # "cursor_name" is optional
        return (pack('xCxxL4x12',
                     $X->num('XFixesCursorNotifySubtype',$h{'subtype'}),
                     _num_none($h{'window'}),
                     $h{'cursor_serial'},
                     _num_time($h{'time'}),
                     _num_none($h{'cursor_name'} || 0)),
                1); # "do_seq" put in sequence number
      } ];

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   [ 'XFixesQueryVersion',  # 0
     sub {
       my ($X, $major, $minor) = @_;
       ### XFixesQueryVersion request
       return pack 'LL', $major, $minor;
     },
     sub {
       my ($X, $data) = @_;
       ### XFixesQueryVersion reply: "$X"
       my @ret = unpack 'x8SS', $data;
       my $self;
       if ($self = $X->{'ext'}->{'XFIXES'}->[3]) {
         ($self->{'major'},$self->{'minor'}) = @ret;
       }
       return @ret;
     }],

   [ 'XFixesChangeSaveSet',  # 1
     sub {
       my ($X, $window, $mode, $target, $map) = @_;
       return pack ('CCCxL',
                    $X->num('XFixesSaveSetMode',$mode),
                    $X->num('XFixesSaveSetTarget',$target),
                    $X->num('XFixesSaveSetMap',$map),
                    $window);
     }],

   [ 'XFixesSelectSelectionInput',  # 2
     sub {
       my ($X, $window, $selection, $event_mask) = @_;
       return pack 'LLL', $window, $selection, $event_mask;
     }],

   [ 'XFixesSelectCursorInput',  # 3
     \&_request_xids ],

   [ 'XFixesGetCursorImage',  # 4
     \&_request_empty,
     sub {
       my ($X, $data) = @_;
       # (rootx,rooty, w,h, xhot,yhot, serial)
       my @ret = unpack 'x8ssSSSSL', $data;
       return (@ret,
               substr ($data, 32, 4*$ret[2]*$ret[3]));
     }],

   #---------------------------------------------------------------------------
   # version 2.0

   [ 'XFixesCreateRegion',   # 5
     \&_request_region_and_rectangles ],

   [ 'XFixesCreateRegionFromBitmap',   # 6
     \&_request_xids ],

   [ 'XFixesCreateRegionFromWindow',   # 7
     sub {
       my ($X, $region, $window, $kind) = @_;
       ### XFixesCreateRegionFromWindow: $region, $window, $kind
       return pack ('LLCxxx',
                    $region,
                    $window,
                    $X->num('XFixesWindowRegionKind',$kind));
     }],

   [ 'XFixesCreateRegionFromGC',   # 8
     \&_request_xids ],

   [ "XFixesCreateRegionFromPicture",   # 9
     \&_request_xids ],

   [ "XFixesDestroyRegion",   # 10
     \&_request_xids ],

   [ "XFixesSetRegion",   # 11
     \&_request_region_and_rectangles ],

   [ "XFixesCopyRegion",   #    12
     \&_request_xids ],

   [ "XFixesUnionRegion",   # 13
     \&_request_xids ],
   [ "XFixesIntersectRegion",   # 14
     \&_request_xids ],
   [ "XFixesSubtractRegion",   # 15
     \&_request_xids ],

   [ "XFixesInvertRegion",   # 16
     sub {
       shift; # $X
       # $src_region, $x, $y, $width, $height, $dst_region
       return pack 'LssSSL', @_;
     }],

   [ "XFixesTranslateRegion",   # 17
     sub {
       shift;
       return pack 'Lss', @_; # $region, $dx, $dy;
     }],

   [ "XFixesRegionExtents",   # 18
     \&_request_xids ],

   [ "XFixesFetchRegion",   # 19
     \&_request_xids,
     sub {
       my ($X, $data) = @_;
       ### XFixesFetchRegion reply: length($data)
       my @ret = ([ unpack 'x8ssSS', $data ]);
       for (my $pos = 8+8+4*4; $pos < length($data); $pos+=8) {
         push @ret, [ unpack 'ssSS', substr($data,$pos,8) ];
       }
       return @ret;
     }],

   [ "XFixesSetGCClipRegion",   # 20
     \&_request_xid_region_xy], # ($gc, $region, $x, $y)

   [ "XFixesSetWindowShapeRegion",   # 21
     sub {
       my ($X, $window, $shape_kind, $x, $y, $region) = @_;
       # use ShapeKind if SHAPE initialized, otherwise same Bounding and
       # Clip from XFixesWindowRegionKind
       my $kind_type = ($X->{'ext_const'}->{'ShapeKind'}
                        ? 'ShapeKind' : 'XFixesWindowRegionKind');
       return pack ('LCxxxssL',
                    $window,
                    $X->num($kind_type,$shape_kind),
                    $x,$y,
                    _num_none ($region));
     }],

   [ "XFixesSetPictureClipRegion",   # 22
     \&_request_xid_region_xy ],  # ($pict, $region, $x, $y)

   [ "XFixesSetCursorName",   # 23
     sub {
       my ($X, $cursor, $str) = @_;
       return pack 'LSxxa', $cursor, length($str), $str;
     }],

   [ "XFixesGetCursorName",   # 24
     \&_request_xids,
     sub {
       my ($X, $data) = @_;
       ### XFixesGetCursorName reply
       my ($atom, $len) = unpack 'x8LS', $data;
       return (_interp_none($X,$atom), substr($data,32,$len));
     }],

   [ "XFixesGetCursorImageAndName",   # 25
     \&_request_empty,
     sub {
       my ($X, $data) = @_;
       # (x,y, w,h, xhot,yhot, serial, atom, $namelen)
       my @ret = unpack 'x8ssSSSSLLLSxx', $data;
       my $namelen = pop @ret;
       my $atom = pop @ret;
       my $numpixels = $ret[2] * $ret[3];
       my $pixels = [ unpack "x32L$numpixels", $data ];
       my $name = substr ($data, 32 + 4*$numpixels, $namelen);
       return @ret, $pixels, _interp_none($X,$atom), $name;
     }],

   [ "XFixesChangeCursor",   # 26
     sub {
       my ($X, $src, $dst) = @_;
       return pack 'LL', $src, $dst;
     }],

   [ "XFixesChangeCursorByName",   # 27
     sub {
       my ($X, $src, $name) = @_;
       return pack 'LSxxa', $src, length($name), $name;
     }],


   #---------------------------------------------------------------------------
   # version 3.0

   [ 'XFixesExpandRegion',  # 28
     sub {
       shift; # $X
       return pack 'LLSSSS', @_; # $src, $dst, $left,$right, $top,$bottom
     }],


   #---------------------------------------------------------------------------
   # version 4.0

   ["XFixesHideCursor",  # 29
    \&_request_xids ],
   ["XFixesShowCursor",  # 30
    \&_request_xids ],

   #---------------------------------------------------------------------------
   # version 5.0

   ["XFixesCreatePointerBarrier",  # 31
    sub {
      my ($X, $barrier, $drawable, $x1,$y1, $x2,$y2, $directions, @devices) = @_;
      return pack ('LLssLxxS*',
                   $barrier, $drawable,  # CARD32
                   $x1,$y1, $x2,$y2,     # INT16
                   $X->num('XFixesBarrierDirections',$directions), # CARD32
                   # pad16
                   scalar(@devices),     # CARD16
                   @devices);            # CARD16
    }],

   ["XFixesDestroyPointerBarrier",  # 32
    \&_request_xids ],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XFIXES new()

  # Constants
  $X->{'ext_const'} ||= {};
  %{$X->{'ext_const'}} = (%{$X->{'ext_const'}},
                          %const_arrays);
  $X->{'ext_const_num'} ||= {};
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'}},
                              %const_hashes);

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'XFixesSelectionNotify';
  $X->{'ext_events'}[$event_num] = $XFixesSelectionNotify_event;
  $event_num++;
  $X->{'ext_const'}{'Events'}[$event_num] = 'XFixesCursorNotify';
  $X->{'ext_events'}[$event_num] = $XFixesCursorNotify_event;

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # the protocol spec says must query version with what we support
  my ($server_major, $server_minor) = $X->req('XFixesQueryVersion', 5, 0);
  return bless { major => $server_major,
                 minor => $server_minor,
               }, $class;
}

sub _request_empty {
  return '';
}

sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _request_xid_region_xy {
  my ($X, $gc, $region, $x, $y) = @_;
  return pack 'LLss', $gc, _num_none($region), ($x||0),($y||0);
}

sub _request_region_and_rectangles {
  shift; # $X
  my $region = shift;
  return pack('L',$region) . _pack_rectangles (@_);
}
sub _pack_rectangles {
  return join ('', map {pack 'ssSS', @$_} @_);
}

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}
sub _interp_none {
  my ($X, $xid) = @_;
  if ($X->{'do_interp'} && $xid == 0) {
    return 'None';
  } else {
    return $xid;
  }
}

sub _interp_time {
  my ($time) = @_;
  if ($time == 0) {
    return 'CurrentTime';
  } else {
    return $time;
  }
}
sub _num_time {
  my ($time) = @_;
  if ($time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    $href->{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}

1;
__END__

=for stopwords XFIXES XID reparent Unmap arrayref AARRGGBB GG pre-multiplied pixmap RENDER ShapeKind subwindow Ryde

=head1 NAME

X11::Protocol::Ext::XFIXES - miscellaneous "fixes" extension

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('XFIXES')
   or print "XFIXES extension not available";

=head1 DESCRIPTION

The XFIXES extension is a grab-bag of requests and events conceived as
"fixing" omissions or shortcomings in the core X11 protocol.

=head1 REQUESTS

The following are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('XFIXES');

=head2 XFIXES version 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XFixesQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more than).

The current code in this module supports up to 5.0 and automatically
negotiates within C<init_extension()>, so direct use of
C<XFixesQueryVersion> is not necessary.  Asking for higher than the code
supports might be a bad idea.

=item C<($atom, $str) = $X-E<gt>XFixesChangeSaveSet ($window, $mode, $target, $map)>

Insert or delete C<$window> (an XID) from the "save set" of resources to be
retained on the server when the client disconnects.  This is an extended
version of the core C<ChangeSaveSet> request.

C<$mode> is either "Insert" or "Delete".

C<$target> is how to reparent C<$window> on close-down, either "Nearest" or
"Root".  "Nearest" is what the core C<ChangeSaveSet> gives and means go to
the next non-client ancestor window.  "Root" means go to the root window.

C<$map> is either "Map" or "Unmap" to apply to C<$window> on close-down.
"Map" is what the core C<ChangeSaveSet> does.

=item $X-E<gt>XFixesSelectSelectionInput ($window, $selection, $event_mask)>

Select C<SelectionNotify> events ... (see L</"EVENTS"> below).

C<$event_mask> has three bits,

                            bitpos  bitval
    SetSelectionOwner         0      0x01
    SelectionWindowDestroy    1      0x02
    SelectionClientClose      2      0x04

To choose which of the respective event "subtypes" should be reported.
There's no pack function for these yet, so just give an integer, for
instance 0x07 for all three.

=item $X-E<gt>XFixesSelectCursorInput ($event_mask)>

Select C<XFixesCursorNotify> events ... (see L</"EVENTS"> below).

C<$event_mask> has only a single bit, 0x01, to select C<DisplayCursor>
events or not.  There's no pack function for this yet, just give integer 1
or 0.

=item ($root_x,$root_y, $width,$height, $xhot,$yhot, $serial, $pixels) = $X-E<gt>XFixesGetCursorImage ()>

Return the size and pixels of the current mouse pointer cursor.

C<$root_x>,C<$root_y> is the current mouse pointer location in root window
coordinates (similar to C<QueryPointer>).

C<$width>,C<$height> is the size of the cursor.  C<$xhot>,C<$yhot> is the
"hotspot" position within the cursor, which follows the pointer location.

C<$pixels> is a byte string of the cursor image pixels in RGBA format.  Each
pixel is 4 bytes R,G,B,A, then C<$width> many of those for each row, and
C<$height> many such rows.  Each component is 0 to 255 and the colours are
pre-multiplied by the alpha transparency factor.

    RGBARGBA...RGBA    $width pixels per row
    ...
    RGBARGBA...RGBA    and $height rows

=back

=head2 XFIXES version 2.0

A region object on the server represents a set of rectangles.

=over

=item C<$X-E<gt>XFixesCreateRegion ($region, $rect...)>

Create C<$region> (a new XID) as a region and set it to the union of the
given rectangles, or empty if none.  Each C<$rect> is an arrayref
C<[$x,$y,$width,$height]>.

    my $region = $X->new_rsrc;
    $X->XFixesCreateRegion ($region, [0,0,10,5], [100,100,1,1]);

=item C<$X-E<gt>XFixesCreateRegionFromBitmap ($region, $bitmap)>

Create a region initialized from the 1 bits of C<$bitmap> (a pixmap XID).

=item C<$X-E<gt>XFixesCreateRegionFromWindow ($region, $window, $kind)>

Create a region initialized from the shape of C<$window> (an XID).  C<$kind>
is either "Bounding" or "Clip" as per the SHAPE extension (see
L<X11::Protocol::Ext::SHAPE>).

It's not necessary to C<$X-E<gt>init_extension('SHAPE')> before using this
request, any shape handling is done on the server, resulting in whatever
rectangular or non-rectangular region.

=item C<$X-E<gt>XFixesCreateRegionFromGC ($region, $window)>

Create a region initialized from the clip mask of C<$gc> (an XID).

=item C<$X-E<gt>XFixesCreateRegionFromPicture ($region, $picture)>

Create a region initialized from a RENDER C<$picture> (an XID).

Picture objects are from the RENDER extension (see
L<X11::Protocol::Ext::RENDER>).  This request always exists, but is not
useful without RENDER.

=item C<$X-E<gt>XFixesDestroyRegion ($region)>

Destroy C<$region>.

=item C<$X-E<gt>XFixesSetRegion ($region, $rect...)>

Set C<$region> to the union of the given rectangles, or empty if none.  Each
C<$rect> is an arrayref C<[$x,$y,$width,$height]>, as per
C<XFixesCreateRegion> above.

=item C<$X-E<gt>XFixesCopyRegion ($dst, $src)>

Copy a region C<$src> to region C<$dst>.

=item C<$X-E<gt>XFixesUnionRegion ($src1, $src2, $dst)>

Set region C<$dst> to the union of regions C<$src1> and C<$src2>.

=item C<$X-E<gt>XFixesIntersectRegion ($src1, $src2, $dst)>

Set region C<$dst> to the intersection of regions C<$src1> and C<$src2>.

=item C<$X-E<gt>XFixesSubtractRegion ($src1, $src2, $dst)>

Set region C<$dst> to region C<$src1> subtract region C<$src2>.

=item C<$X-E<gt>XFixesInvertRegion ($src, $rect, $dst)>

Set region C<$dst> to the inverse of C<$src>, bounded by rectangle C<$rect>,
which means C<$rect> subtract C<$src>.  C<$rect> is an arrayref
C<[$x,$y,$width,$height]>.

=item C<$X-E<gt>XFixesTranslateRegion ($region, $dx, $dy)>

Move the area covered by C<$region> by an offset C<$dx> and C<$dy>.

=item C<$X-E<gt>XFixesRegionExtents ($dst, $src)>

Set region C<$dst> to the rectangular bounds of region C<$src>.  If C<$src>
is empty then C<$dst> is set to empty.

=item C<@rects = $X-E<gt>XFixesFetchRegion ($region)>

Return a list of rectangles which cover C<$region>.  Each returned element
is an arrayref C<[$x,$y,$width,$height]> and are in "YX-banded" order.

=item C<$X-E<gt>XFixesSetGCClipRegion ($gc, $region)>

Set the clip mask of C<$gc> (an XID) to C<$region> (an XID).

=item C<$X-E<gt>XFixesSetWindowShapeRegion ($window, $kind, $x_offset, $y_offset, $region)>

Set the shape mask of C<$window> (an XID) to C<$region>, at offset
C<$x_offset>,C<$y_offset> into the window.  C<$kind> is a ShapeKind, either
"Bounding" or "Clip" (see L<X11::Protocol::Ext::SHAPE>.)

It's not necessary to C<$X-E<gt>init_extension('SHAPE')> before using this
request.  If SHAPE is not available at all on the server then presumably
this request gives an error reply.

=item C<$X-E<gt>XFixesSetPictureClipRegion ($picture, $region)>

Set the clip mask of RENDER C<$picture> (an XID) to C<$region>.

Picture objects are from the RENDER extension (see
L<X11::Protocol::Ext::RENDER>).  The request always exists, but is not useful
without RENDER.

=item C<$X-E<gt>XFixesSetCursorName ($cursor, $str)>

Set a name for cursor object C<$cursor> (an XID).  The name string C<$str>
is interned as an atom within the server and therefore should consist only
of latin-1 characters.  (Perhaps in the future there will be some
enforcement or conversions here.)

=item C<($atom, $str) = $X-E<gt>XFixesGetCursorName ($cursor)>

Get the name of mouse pointer cursor C<$cursor> (an XID), as set by
C<XFixesSetCursorName>.

The returned C<$atom> (integer) is the name atom and C<$str> is the name
string (which is the atom's name).  If there's no name then C<$atom> is
string "None" (or 0 if no C<$X-E<gt>{'do_interp'}>) and C<$str> is empty "".

=item C<($x,$y, $width,$height, $xhot,$yhot, $serial, $pixels, $atom, $str) = $X-E<gt>XFixesGetCursorImageAndName ()>

Get the image and name of the current mouse pointer cursor.  The return is
the values of C<XFixesGetCursorImage> plus C<XFixesGetCursorName>, as
described above.

=item C<$X-E<gt>XFixesChangeCursor ($src, $dst)>

Change the contents of cursor C<$dst> (an XID) to the contents of cursor
C<$src> (an XID).

=item C<$X-E<gt>XFixesChangeCursorByName ($src, $dst_name)>

Change the contents of any cursors with name C<$dst_name> (a string) to the
contents of cursor C<$src>.

=back

=head2 XFIXES version 3.0

=over

=item C<$X-E<gt>XFixesExpandRegion ($src, $dst, $left,$right,$top,$bottom)>

Set region C<$dst> (an XID) to the rectangles of region C<$src>, with each
rectangle expanded by C<$left>, C<$right>, C<$top>, C<$bottom> many pixels
in the respective directions.

Notice that it doesn't matter how C<$src> is expressed as rectangles, the
effect is simply as if each pixel in C<$src> was individually expanded and
the union of the result then taken.

=back

=head2 XFIXES version 4.0

=over

=item C<$X-E<gt>XFixesHideCursor ($window)>

=item C<$X-E<gt>XFixesShowCursor ($window)>

Hide or show the mouse pointer cursor for C<$window> (an XID).  When the
pointer moves into C<$window> or any subwindow it's hidden.

This hide/show for each window is a per-client setting.  If more than one
client requests hiding then the cursor remains hidden until all of them
"show" again.  If a client disconnects or is killed then any hides it had
are undone.

=back

=head2 XFIXES version 5.0

=over

=item C<$X-E<gt>XFixesCreatePointerBarrier ($barrier, $drawable, $x1,$y1, $x2,$y2, $directions, @devices)>

Create C<$barrier> (a new XID) as a barrier object which prevents user mouse
pointer movement across a line between C<$x1,$y1> and C<$x2,$y2>.

The line must be horizontal or vertical, so either C<$x1==$x2> or
C<$y1==$y2>.  A horizontal barrier is across the top edge of the line
pixels, a vertical barrier is along the left edge of the line.

    my $barrier = $X->new_rsrc;
    $X->XFixesCreatePointerBarrier ($barrier, $X->root,
                                    100,100, 100,500,
                                    ['PositiveY','NegativeY']);

The user can move the mouse pointer to skirt around a given barrier line,
but by putting lines together a region can be constructed keeping the
pointer inside or outside, or even making a maze to trick the user!

Touchscreen pad input is not affected by barriers, and
C<$X-E<gt>WarpPointer> can still move the pointer anywhere.

=item C<$X-E<gt>XFixesDestroyPointerBarrier ($barrier)>

Destroy the given barrier (an XID).

=back

=head1 EVENTS

The following events have the usual fields

    name             "XFixes..."
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

=over

=item C<XFixesSelectionNotify>

C<XFixesSelectionNotify> is sent to the client when selected with
C<XFixesSelectSelectionInput> above.  It reports changes to the selection.
The event-specific fields are

    subtype         enum string
    window          XID
    owner           XID of owner window, or "None"
    selection       atom
    time            integer, server timestamp
    selection_time  integer, server timestamp

C<subtype> is one of

    SetSelectionOwner
    SelectionWindowDestroy
    SelectionClientClose

C<time> is when the event was generated, C<selection_time> is when the
selection was owned.

=item C<XFixesCursorNotify>

C<XFixesCursorNotify> is sent to the client when selected by
C<XFixesSelectCursorInput> above.  It reports when the mouse pointer cursor
displayed has changed.  It has the following event-specific fields,

    subtype         enum string, currently always "DisplayCursor"
    window          XID
    cursor_serial   integer
    time            integer, server timestamp
    cursor_name     atom or "None", XFIXES 2.0 up

C<subtype> is "DisplayCursor" when the displayed cursor has changed.  This
is the only subtype currently.

C<cursor_serial> is a serial number as obtained from
C<XFixesGetCursorImage>.  A client can use this to notice the cursor has
become an already-fetched image.

C<cursor_name> is the atom of the name given to cursor by
C<XFixesSetCursorName>, or string "None" if no name.  This is new in XFIXES
2.0 and is returned by the event unpack only if the server is 2.0 or higher.
In an event repack it's optional and is put in if given.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::SHAPE>,
L<X11::Protocol::Ext::RENDER>

=head1 HOME PAGE

http://user42.tuxfamily.org/x11-protocol-other/index.html

=head1 LICENSE

Copyright 2011 Kevin Ryde

X11-Protocol-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

X11-Protocol-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
