# Copyright 2011 Kevin Ryde

   # [ 'DbeAllocateBackBufferName',  # 1
   # [ 'DoubleBufferAllocateBackBufferName',  # 1

# visuals supporting dbe as a hash ?



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
package X11::Protocol::Ext::DOUBLE_BUFFER;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 5;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/share/doc/x11proto-xext-dev/dbe.txt.gz    # protocol
#
# /usr/share/doc/libxext-dev/dbelib.txt.gz       # xlib
#
# /usr/include/X11/extensions/dbe.h
# /usr/include/X11/extensions/dbeproto.h
#

### DOUBLE_BUFFER.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

my $reqs =
  [
   [ 'DbeGetVersion',  # 0
     sub {
       my ($X, $client_major, $client_minor) = @_;
       ### DbeGetVersion request
       return pack 'CCxx', $client_major, $client_minor;
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8CC', $data;
     }],

   [ 'DbeAllocateBackBufferName',  # 1
     sub {
       my ($X, $window, $buffer, $swap_action) = @_;
       ### DbeAllocateBackBufferName request
       return pack 'LLCxxx',
         $window, $buffer, $X->num('DbeSwapAction',$swap_action);
     } ],

   [ 'DbeDeallocateBackBufferName',  # 2
     \&_request_card32s ],  # ($buffer)

   [ 'DbeSwapBuffers',  # 3
     sub {
       my $X = shift;
       my $ret = pack 'L', scalar(@_)/2;  # number of pairs
       while (@_) {
         $ret .= pack 'LCxxx', shift, $X->num('DbeSwapAction',shift);
       }
       return $ret;
     }],

   [ 'DbeBeginIdiom',     # 4
     \&_request_empty ],
   [ 'DbeEndIdiom',       # 5
     \&_request_empty ],

   [ 'DbeGetVisualInfo',  # 6
     sub {
       my $X = shift;
       return pack 'L*', scalar(@_), @_;  # ($drawable, ...)
     },
     sub {
       my ($X, $data) = @_;
       my $num_screens = unpack 'x8L', $data;
       my $pos = 32;
       return map {
         my $num_visuals = unpack 'L', substr($data,$pos,4);
         $pos += 4;
         [ map {[ unpack 'LCCx', substr($data,($pos+=8)-8,8) ]}
           1 .. $num_visuals ]
       } 1 .. $num_screens;
     }],

   [ 'DbeGetBackBufferAttributes',  # 7
     \&_request_card32s,   # ($buffer)
     sub {
       my ($X, $data) = @_;
       return _interp_none($X, unpack('x8L',$data));
     }],

  ];

my $DbeSwapAction_array = ['Undefined', 'Background', 'Untouched', 'Copied'];
my $DbeSwapAction_hash
  = { X11::Protocol::make_num_hash($DbeSwapAction_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### DOUBLE_BUFFER new()

  # Constants
  $X->{'ext_const'}->{'DbeSwapAction'} = $DbeSwapAction_array;
  $X->{'ext_const_num'}->{'DbeSwapAction'} = $DbeSwapAction_hash;

  _ext_requests_install ($X, $request_num, $reqs);

  # Protocol spec says must negotiate version or the extension may or may
  # not work.
  my ($server_major, $server_minor) = $X->req('DbeGetVersion', 1, 0);
  ### $server_major
  ### $server_minor
  return bless { major => $server_major,
                 minor => $server_minor,
               }, $class;
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

sub _request_empty {
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _interp_none {
  my ($X, $xid) = @_;
  if ($X->{'do_interp'} && $xid == 0) {
    return 'None';
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords XID arrayrefs Ryde pixmap deallocated XIDs enum arrayref arrayrefs drawable's

=head1 NAME

X11::Protocol::Ext::DOUBLE_BUFFER - ...

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('DOUBLE-BUFFER')
   or print "DOUBLE-BUFFER extension not available";

=head1 DESCRIPTION

The DOUBLE-BUFFER extension lets a client draw into a "back buffer" for a
window and when done swap it to into the user-visible "front".  A back
buffer is a drawable and has the same size, depth, etc as the window proper.

Drawing off-screen then swapping to be visible is good for the frames of an
animation, or if some drawing is complex or poorly implemented and has
clears and redraws which would flash if done directly to the window.

Off-screen drawing can also be done with a pixmap and then copy it into the
window.  A back buffer can be implemented a little more efficiently and may
have hardware support.

The server might allow double buffering only on some visuals.
C<DbeGetVisualInfo> lists those which are supported, or alternatively just
try to create a back buffer for a desired window and watch for an error
reply.

=head1 REQUESTS

The following requests are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('DOUBLE-BUFFER');

=over

=item C<($server_major, $server_minor) = $X-E<gt>DbeGetVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not higher).

The current code in this module supports 1.0 and automatically negotiates
within C<init_extension()> so direct use of C<DbeGetVersion> is not
necessary.

=item C<$X-E<gt>DbeAllocateBackBufferName ($window, $buffer, $swap_action_hint)>

Create C<$buffer> (a new XID) as the back buffer on C<$window>.  If
C<$window> is already double buffered then C<$buffer> becomes a further
reference to the existing back buffer.  C<$buffer> is a drawable and can be
used with all the usual drawing operations.

    my $buffer = $X->new_rsrc;
    $X->DbeAllocateBackBufferName ($window, $buffer, 'Copied');

C<$swap_action_hint> is the most likely C<$swap_action> which will be used
with later C<DbeSwapBuffers> (below).

If C<$window> is later destroyed then C<$buffer> continues to exist and work
as a drawable, but 

=item C<$X-E<gt>DbeDellocateBackBufferName ($buffer)>

Release C<$buffer>.  The back buffer for a window is destroyed when the last
buffer reference to it in all clients is deallocated.

=item C<$X-E<gt>DbeSwapBuffers ($window1,$swap_action1, $window2,$swap_action2,...)>

Swap the front and back buffers on given C<$windows> (XIDs).  The back
buffer becomes visible and what was the front becomes the back.

  $X->DbeSwapBuffers ($window1, 'Background',
                      $window2, 'Untouched');

Only the underlying content is swapped, the C<$window> XID continues to be
the front visible part and any C<$buffer> XIDs on it continue to be the
back.

The contents of the newly swapped back buffer are controlled by
C<$swap_action> (an enum string) for each window,

    Undefined      undefined contents
    Background     cleared to the window background
    Untouched      left at current contents (ie. what was visible)
    Copied         contents of the old back buffer (so unchanged)

=item C<$X-E<gt>DbeBeginIdiom ($buffer)>

=item C<$X-E<gt>DbeEndIdiom ($buffer)>

Hint to the server that a sequence of drawing and/or swap operations between
Begin and End might be done atomically for higher performance.  If the
server doesn't recognise the sequence then it just runs as normal.

=item C<@infos = $X-E<gt>DbeGetVisualInfo ($drawable1, $drawable2, ...)>

For each C<$drawable>, return a list of the visuals IDs on its screen which
support double-buffering.  Each returned info is an arrayref containing
sub-arrayrefs,

    [ [$visual_id1, $depth, $perf_level],
      [$visual_id2, $depth, $perf_level],
      ... ]

So for example,

    my ($info_about_d1, $info_about_d2)
      = $X->DbeGetVisualInfo ($drawable1, $drawable2);

Or if enquiring about a single drawable's screen then just

    my $info = $X->DbeGetVisualInfo ($X->root);

In each case the info can then be iterated

    foreach my $elem (@$info) {
      my ($visual, $depth, $perflevel) = @$elem;
      # ...
    }

C<$perflevel> is an integer indicating how good the performance of double
buffering is on the visual.  A higher value means better performance, but
it's actual value has no meaning (and in particular cannot be compared
between different servers).

=item C<$window = $X-E<gt>DbeGetBackBufferAttributes ($buffer)>

Return the window (an XID) which C<$buffer> is working on, or "None" if its
window has been destroyed.

=back

=head1 SEE ALSO

L<X11::Protocol>

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
