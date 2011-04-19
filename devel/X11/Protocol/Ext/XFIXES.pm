# Copyright 2011 Kevin Ryde

# src/dst order
# event masks
# SelectionNotify subtype


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
use X11::Protocol 'make_num_hash';
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

my $reqs_version1 =
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
       return unpack 'x8SS', $data;
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
       # (x,y, w,h, xhot,yhot, serial, pad32,pad32, $pixels)
       return ((unpack 'x8ssSSSSL', $data),
               [ unpack 'x32L*', $data ]);
     }],
  ];

my @reqs_version2 =
  (
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
     \&_request_xid_region_xy],

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
     \&_request_xid_region_xy ],

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
  );

my @reqs_version3 =
  (
   [ 'XFixesExpandRegion',  # 28
     sub {
       shift; # $X
       return pack 'LLSSSS', @_; # $src, $dst, $left,$right, $top,$bottom
     }],
  );

my @reqs_version4 =
  (
   ["XFixesHideCursor",  # 29
    \&_request_xids ],
   ["XFixesShowCursor",  # 30
    \&_request_xids ],
  );

my @reqs_version5 =
  (
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
  );

my $WindowRegionKind_array = ['Bounding', 'Clip'];
my $WindowRegionKind_hash =
  { X11::Protocol::make_num_hash($WindowRegionKind_array) };

my $SaveSetMode_array = ['Insert', 'Delete'];
my $SaveSetMode_hash =
  { X11::Protocol::make_num_hash($SaveSetMode_array) };

my $SaveSetTarget_array = ['Nearest', 'Root'];
my $SaveSetTarget_hash =
  { X11::Protocol::make_num_hash($SaveSetTarget_array) };

my $SaveSetMap_array = ['Map', 'Unmap'];
my $SaveSetMap_hash =
  { X11::Protocol::make_num_hash($SaveSetMap_array) };

my $SelectionNotifySubtype_array = ['SetSelectionOwnerNotify',
                                    'SelectionWindowDestroyNotify',
                                    'SelectionClientCloseNotify' ];
my $SelectionNotifySubtype_hash =
  { X11::Protocol::make_num_hash($SelectionNotifySubtype_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XFIXES new()

  # Constants
  $X->{'ext_const'}->{'XFixesWindowRegionKind'} = $WindowRegionKind_array;
  $X->{'ext_const_num'}->{'XFixesWindowRegionKind'} = $WindowRegionKind_hash;

  $X->{'ext_const'}->{'XFixesSaveSetMode'} = $SaveSetMode_array;
  $X->{'ext_const_num'}->{'XFixesSaveSetMode'} = $SaveSetMode_hash;

  $X->{'ext_const'}->{'XFixesSaveSetTarget'} = $SaveSetTarget_array;
  $X->{'ext_const_num'}->{'XFixesSaveSetTarget'} = $SaveSetTarget_hash;

  $X->{'ext_const'}->{'XFixesSaveSetMap'} = $SaveSetMap_array;
  $X->{'ext_const_num'}->{'XFixesSaveSetMap'} = $SaveSetMap_hash;

  $X->{'ext_const'}->{'XFixesSelectionNotifySubtype'} = $SelectionNotifySubtype_array;
  $X->{'ext_const_num'}->{'XFixesSelectionNotifySubtype'} = $SelectionNotifySubtype_hash;

  $X->{'ext_const'}{'XFixesSelectionEventMask'}
    = ['SetSelectionOwnerNotifyMask',
       'SelectionWindowDestroyNotifyMask',
       'SelectionClientCloseNotifyMask' ];
  $X->{'ext_const_num'}{'XFixesSelectionEventMask'} =
    { make_num_hash($X->{'ext_const'}{'XFixesSelectionEventMask'}) };

  $X->{'ext_const'}{'XFixesCursorEventMask'}
    = ['DisplayCursorNotifyMask' ];
  $X->{'ext_const_num'}{'XFixesCursorEventMask'} =
    { make_num_hash($X->{'ext_const'}{'XFixesCursorEventMask'}) };

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'XFixesSelectionNotify';
  $X->{'ext_events'}[$event_num] =
    ['xCxxL5',
     'subtype',
     'window',
     ['owner',['None']], # window
     'selection',        # atom
     'time',
     'selection_time',
    ];

  $event_num++;
  $X->{'ext_const'}{'Events'}[$event_num] = 'XFixesCursorNotify';
  $X->{'ext_events'}[$event_num] = ['xCxxL3',  # version 1.0 without 'name'
                                    'subtype',
                                    'window',
                                    ['cursor',['None']]
                                    'time',
                                   ];

  # Requests
  _ext_requests_install ($X, $request_num, $reqs_version1);

  # protocol spec says must query version with what we support
  my ($major, $minor) = $X->req('XFixesQueryVersion', 5, 0);
  ### $major
  ### $minor
  if ($major >= 2) {
    $X->{'ext_events'}[$event_num] = ['xCxxL4',
                                      'subtype',
                                      'window',
                                      ['cursor',['None']]
                                      'time',
                                      ['name',['None']],  # new in 2.0
                                     ];

    my @reqs = @$reqs_version1;
    push @reqs, @reqs_version2;
    if ($major >= 3) { push @reqs, @reqs_version3 }
    if ($major >= 4) { push @reqs, @reqs_version4 }
    if ($major >= 5) { push @reqs, @reqs_version5 }
    _ext_requests_install ($X, $request_num, \@reqs);
  }

  return bless {
                # Any interest in holding the version number?
                # major => $major,
                # minor => $minor,
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

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;
  $X->{'ext_request'}{$request_num} = $reqs;
  my $i;
  foreach $i (0 .. $#$reqs) {
    $X->{'ext_request_num'}{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}

1;
__END__

=for stopwords XFIXES XID reparent Unmap arrayref AARRGGBB GG pre-multiplied pixmap RANDR ShapeKind subwindow Ryde

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
negotiates for anything up to that, so direct use of C<XFixesQueryVersion>
would be unusual.  Asking for higher than the code supports might be a bad
idea.

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

Select ... (see L</"EVENTS"> below).

=item $X-E<gt>XFixesSelectCursorInput ()>

Select C<CursorNotify> events (see L</"EVENTS"> below).

=item ($x,$y, $width,$height, $xhot,$yhot, $serial, $pixels) = $X-E<gt>XFixesGetCursorImage ()>

Return the pixels etc of the current mouse pointer cursor.

C<$pixels> is an arrayref of C<$width * $height> many pixels which is the
image data.  Each pixel is a 32-bit number with 8-bit hex parts "AARRGGBB",
where AA is an alpha transparency, and RR, GG, BB the red, green, blue
colours.  The colours are pre-multiplied by the alpha.

 # element is an arrayref [$red,$green,$blue,$alpha].  Each component is in the
 # range 0 to 255 and the colours are

=item C<($atom, $str) = $X-E<gt>XFixesGetCursorImage ()>

Get the image and name of the current mouse pointer cursor.

=back

=head2 XFIXES version 2.0

=over

=item C<$X-E<gt>XFixesCreateRegion ($region, $rect...)>

Create C<$region> (a new XID) as a region and set it to the union of the
given rectangles, or empty if no rectangles.  Each C<$rect> is an arrayref
C<[$x,$y,$width,$height]>.

    my $region = $X->new_rsrc;
    $X->XFixesCreateRegion ($region, [0,0,10,5], [100,100,1,1]);

=item C<$X-E<gt>XFixesCreateRegionFromBitmap ($region, $bitmap)>

Create a region initialized from the 1 bits of C<$bitmap> (a pixmap XID).

=item C<$X-E<gt>XFixesCreateRegionFromWindow ($region, $window, $kind)>

Create a region initialized from the shape of C<$window> (an XID).  C<$kind>
is either "Bounding" or "Clip".

=item C<$X-E<gt>XFixesCreateRegionFromGC ($region, $window)>

Create a region initialized from the clip mask of C<$gc> (an XID).

=item C<$X-E<gt>XFixesCreateRegionFromPicture ($region, $picture)>

Create a region initialized from a RANDR C<$picture> (an XID).

=item C<$X-E<gt>XFixesDestroyRegion ($region)>

Destroy C<$region>.

=item C<$X-E<gt>XFixesSetRegion ($region, $rect...)>

Set C<$region> to the union of the given rectangles.  Each C<$rect> is an
arrayref C<[$x,$y,$width,$height]>, as per C<XFixesCreateRegion> above.

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
is an arrayref C<[$x,$y,$width,$height]>.

=item C<$X-E<gt>XFixesSetGCClipRegion ($gc, $region)>

Set the clip mask of C<$gc> (an XID) to C<$region>.

=item C<$X-E<gt>XFixesSetWindowShapeRegion ($window, $kind, $x_offset, $y_offset, $region)>

Set the shape mask of C<$window> (an XID) to C<$region>, at offset
C<$x_offset>,C<$y_offset> in the window.  C<$kind> is a ShapeKind, either
"Bounding" or "Clip".

This requires the SHAPE extension (see L<X11::Protocol::Ext::SHAPE>).  The
request always exists, but presumably gives an error reply if SHAPE is not
available on the server.

=item C<$X-E<gt>XFixesSetPictureClipRegion ($picture, $region)>

Set the clip mask of RANDR C<$picture> (an XID) to C<$region>.

Picture objects are from the RANDR extension (see
L<X11::Protocol::Ext::RANDR>).  The request always exists, but is not useful
without RANDR.

=item C<$X-E<gt>XFixesSetCursorName ($cursor, $str)>

Set a name for cursor object C<$cursor> (an XID).  The name is interned as
an atom within the server.

=item C<($atom, $str) = $X-E<gt>XFixesGetCursorName ($cursor)>

Get the name of mouse pointer cursor C<$cursor> (an XID), as set by
C<XFixesSetCursorName>.

The returned C<$atom> (integer) is the name atom and C<$str> is the name
string (the atom's name).  If there's no name then C<$atom> is string "None"
(or 0 if no C<$X-E<gt>{'do_interp'}>) and C<$str> is empty "".

=item C<($x,$y, $width,$height, $xhot,$yhot, $serial, $pixels, $atom, $str) = $X-E<gt>XFixesGetCursorImageAndName ()>

Get the image and name of the current mouse pointer cursor.  The return is
the values of C<XFixesGetCursorImage> and of C<XFixesGetCursorName> as
described above.

=item C<$X-E<gt>XFixesChangeCursor ($src, $dst)>

Change the contents of cursor C<$dst> (an XID) to the contents of cursor
C<$src>.

=item C<$X-E<gt>XFixesChangeCursorByName ($src, $dst_name)>

Change the contents of any cursors with name C<$dst_name> (a string) to the
contents of cursor C<$src>.

=back

=head2 XFIXES version 3.0

=over

=item C<$X-E<gt>XFixesExpandRegion ($src, $dst, $left,$right,$top,$bottom)>

Set region C<$dst> (an XID) to the rectangles of region C<$src>, with each
rectangle expanded by C<$left>, C<$right>, C<$top>, C<$bottom> many pixels
each in the respective directions.

Notice that it doesn't matter in what way C<$src> is expressed as
rectangles, the effect is simply as if each pixel in C<$src> was
individually expanded, and the union of the result then taken.

=back

=head2 XFIXES version 4.0

=over

=item C<$X-E<gt>XFixesHideCursor ($window)>

=item C<$X-E<gt>XFixesShowCursor ($window)>

Hide or show the mouse pointer cursor when it's in C<$window> (an XID) or
any subwindow.

Hide/show for each window is a per-client setting.  If two or more clients
request hiding then the cursor remains hidden until all of them do a "show".
If a client disconnects or is killed then any hides it had in force are
undone.

=back

=head2 XFIXES version 5.0

=over

=item C<$X-E<gt>XFixesCreatePointerBarrier ($barrier, $drawable, $x1,$y1, $x2,$y2, $directions, @devices)>

Create a barrier which prevents user mouse pointer movement across a line
between C<$x1,$y1> and C<$x2,$y2>.  The line must be either horizontal or
vertical, so either C<$x1==$x2> or C<$y1==$y2>.  A horizontal barrier is
across the top edge of the given line pixels, a vertical barrier is the left
edge of the line.

    my $barrier = $X->new_rsrc;
    $X->XFixesCreatePointerBarrier ($barrier, $X->root,
                                    100,100, 100,500,
                                    ['PositiveY','NegativeY']);

=item C<$X-E<gt>XFixesDestroyPointerBarrier ($barrier)>

Destroy the given barrier (an XID).

=back

=head1 EVENTS

C<CursorNotify> is emitted when selected by C<XFixesSelectCursorInput> above
and has the following fields,

    subtype      always "DisplayCursor"
    window       XID
    cursor       XID
    time         server timestamp (integer)
    name         atom or "None" (XFIXES 2.0 up only)

Subtype C<DisplayCursor> means the cursor as displayed on the screen has
changed.    

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::Composite>,
L<X11::Protocol::Ext::DAMAGE>

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
