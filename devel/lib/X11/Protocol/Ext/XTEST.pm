# pack_event ?





# Copyright 2011, 2012 Kevin Ryde

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
package X11::Protocol::Ext::XTEST;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 16;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/share/doc/x11proto-xext-dev/xtest.txt.gz
#
# /usr/include/X11/extensions/xtestproto.h
# /usr/include/X11/extensions/xtestconst.h
#
# /usr/include/X11/extensions/xtestext1proto.h
# /usr/include/X11/extensions/xtestext1const.h
# /usr/include/X11/extensions/xtestext1.h
#
# /usr/include/X11/extensions/XTest.h
# /usr/share/doc/libxext-dev/xtest1.txt.gz
# lib/Xext/XTestExt1.c
#     Xlib
#
# Server side xtest.c
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/share/doc/x11proto-input-dev/XIproto.txt.gz
# /usr/share/doc/x11proto-input-dev/XI2proto.txt.gz
# /usr/include/X11/extensions/XIproto.h
# /usr/include/X11/extensions/xtestconst.h

### XTEST.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 2;

my $reqs =
  [
   ['XTestGetVersion',  # 0
    sub {
      my ($X, $major, $minor) = @_;
      return pack 'CxS', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'xCxxxxS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'xCxxxxS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XTEST'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XTestCompareCursor',  # 1
    sub {
      my ($X, $window, $cursor) = @_;
      return pack ('LL',
                   $window,
                   $cursor eq 'CurrentCursor' ? 1 : _num_none($cursor));
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'xC', $data;
    }],

   ['XTestFakeInput',  # 2
    sub {
      my $X = shift;
      if (ref $_[0] eq 'ARRAY') {
        return join('',map {_fake_input_pack($X,@$_)} @_);
      } else {
        return _fake_input_pack($X,@_);
      }
    } ],

   ['XTestGrabControl',  # 3
    sub {
      my ($X, $impervious) = @_;
      return pack 'Cxxx', $impervious;
    }],
  ];

sub _fake_input_pack {
  my $X = shift;
  my %h = @_;

  if ($h{'name'} =~ /^(MotionNotify|(Key|Button)(Press|Release))$/) {
    local $^W = 0; # avoid some undef warnings from pack_event() in 0.56
    return $X->pack_event (detail => 0,  # defaults
                           root_x => 0,
                           root_y => 0,
                           root   => 0,  # default current screen
                           time   => 0,  # default no delay

                           # unused by XTestFakeInput, zero for the pack
                           event   => 0,   # window
                           child   => 0,   # window
                           event_x => 0,
                           event_y => 0,
                           state   => 0,
                           same_screen => 0,

                           @_);
  } else {
    return $X->pack_event (@_);
  }
}

sub _num_time {
  my ($time) = @_;
  if (defined $time && $time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XTest new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Any need to negotiate the version before using?
  #  my ($major, $minor) = $X->req('XTestQueryVersion',
  #                                              CLIENT_MAJOR_VERSION,
  #                                              CLIENT_MINOR_VERSION);
  # if ($major != 1) {
  #   carp "Unrecognised XTest major version, got $major want 1";
  #   return 0;
  # }
  return bless {
                # major => $major,
                # minor => $minor,
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

1;
__END__

=for stopwords XTEST CurrentCursor hashref KeyPress KeyRelease keycode ButtonPress ButtonRelase MotionNotify CurrentTime umm XInputExtension XID Ryde

=head1 NAME

X11::Protocol::Ext::XTEST - synthetic user input

=for test_synopsis

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XTEST')
   or print "XTEST extension not available";

 $X->XTestFakeInput ({ name   => 'ButtonPress',
                       detail => 3 });  # physical button 3

=head1 DESCRIPTION

The XTEST extension allows

=over

=item *

Synthetic user keyboard and mouse pointer actions.

=item *

Displayed pointer cursor checking.

=item *

Test programs to continue during another client C<GrabServer>.

=back

This is designed to exercise library or server features which would
otherwise require user interaction.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XTEST');

=over

=item C<($server_major, $server_minor) = $X-E<gt>XTestGetVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code supports up to 2.1.  The intention would be to
automatically negotiate in C<init_extension()> if/when necessary.

=item C<$is_same = $X-E<gt>XTestCompareCursor ($window, $cursor)>

Return true if the cursor attribute of C<$window> is equal to C<$cursor>.
C<$cursor> can be

=over

=item *

XID (an integer) of a cursor.

=item *

"None" (or 0).

=item *

"CurrentCursor" (or 1) for the currently displayed cursor.

=back

This can be used to check that the cursor attribute of some C<$window> is a
desired setting, for example

    $desired_cursor = $X->new_rsrc;
    $X->CreateGlyphCursor ($desired_cursor, ...);

    $X->XTestCompareCursor ($window, $desired_cursor)
      or die "Oops, $window doesn't have desired cursor";

Or construct a window with a particular cursor and use "CurrentCursor" to
check the current display is as desired, for example to see a
C<GrabPointer()> is displaying what's intended,

    my $test_window = $X->new_rsrc;
    $X->CreateWindow ($test_window,
                      ...,
                      cursor => $desired_cursor);

    $X->XTestCompareCursor ($test_window, "CurrentCursor");
      or die "Oops, currently displayed cursor is not as desired";

=item C<$X-E<gt>XTestFakeInput (name=E<gt>...)>

=item C<$X-E<gt>XTestFakeInput ([name=E<gt>], [name=E<gt>]...)>

Simulate user input mouse button presses, movement, and key presses.

The argument fields are similar to C<$X-E<gt>pack_event()>, either as the
fields directly for a single event packed, or as one or more arrayrefs if an
input requires more than one packet (eg. C<XInputExtension>).

Each C<XTestFakeInput()> is a single user action, so for instance a button
press and button release must be two C<XTestFakeInput()> requests, not two
event packets in one request.

=over

=item Button Press and Release

The argument fields are

    name       "ButtonPress" or "ButtonRelease"
    detail     physical button number (1 upwards)
    time       milliseconds delay before event, default 0

For example physical button 3 press

    $X->XTestFakeInput (name   => 'ButtonPress',
                        detail => 3);

C<detail> is the physical button number, before the core protocol
C<SetPointerMapping()> translation is applied.  To simulate a "logical"
button number check C<GetPointerMapping()> to see which physical button, if
any, corresponds.

Be careful when faking a C<ButtonPress> as it may be important to fake a
matching C<ButtonRelease> too.  On the X.org server circa 1.9.x after a
synthetic press the physical mouse doesn't work to generate a release, and
the button is left hung (presumably in its normal implicit pointer grab).

=item Key Press and Release

The argument fields are

    name       "KeyPress" or "KeyRelease"
    detail     key code (integer)
    time       milliseconds delay before event, default 0

=item Mouse Pointer Movement

Mouse pointer motion can be induced (similar to a C<WarpPointer>) with

    name       "MotionNotify"
    root_x     \ pointer position to move to
    root_y     /
    root       XID of root window, default "None" for current
    detail     flag 0=absolute, 1=relative, default 0
    time       milliseconds delay before event, default 0

C<root> is the root window (integer XID) to move on.  The default "None" (or
0) means the screen the pointer is currently on.

    $X->XTestFakeInput (name   => 'MotionNotify',
                        root_x => 123,
                        root_y => 456);

C<detail> can be 1 to move relative to the current mouse position.

    $X->XTestFakeInput (name   => 'MotionNotify',
                        root_x => 10,
                        root_y => -20,
                        detail => 1); # relative motion

=item Other Events

Extension events can be faked after C<init_extension()> has been done so
they're recognised by C<$X-E<gt>pack_event()>.  But it's up to the server or
extension which events can actually be simulated.

If an extension input takes more than one event to describe then pass the
packets in multiple arrayrefs.  For example the C<XInputExtension> event
C<DeviceMotion> may need further C<DeviceValuator> events,

    $X->XTestFakeInput ([ name => 'DeviceMotion', ... ],
                        [ name => 'DeviceValuator', ... ],
                        [ name => 'DeviceValuator',  ... ]);  

=back

For all events C<time> is how long in milliseconds the server should wait
before playing the event.  The default is 0 for no delay.  No further
requests are processed from the current client during this time, so a
sequence of C<XTestFakeInput()> with delays will execute sequentially with
cumulative delays.

Generally the event fields from a C<$X> event handler cannot be passed
directly to C<XTestFakeInput> to replay it.  In particular,

=over

=item *

C<time> in an event is a timestamp, not a delay, so would have to be zeroed
(or adjusted to a relative time).

=item *

For C<MotionNotify>, C<detail> in an event is the hint mechanism, so would
have to be zeroed for the absolute/relative flag of C<XTestFakeInput()>.

=item *

For C<ButtonPress> and C<ButtonRelease>, C<detail> in an event is a logical
button number, after C<SetPointerMapping()> transformation, whereas
C<XFakeInput> takes a phyical number.  An invert through the
C<GetPointerMapping()> table would be needed.

=back

=item C<$X-E<gt>XTestGrabControl ($impervious)>

Control the current client's behaviour under a C<GrabServer()> by another
client.

If C<$impervious> is 1 then the current client can continue to make
requests, ie. it's impervious to server grabs by other clients.

If C<$impervious> is 0 then the current client behaves as normal, so its
requests wait during any C<GrabServer()> by another client.

Don't forget to C<$X-E<gt>flush()> when setting up to be impervious since of
course the request won't take effect while it's merely sitting in the output
buffer.

=back

=head1 BUGS

As of C<X11::Protocol> version 0.56, C<pack_event()> of key, button and
motion events will provoke warnings under C<perl -w>.  This affects all such
packs, including what XTEST here does.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XInputExtension>

=head1 HOME PAGE

http://user42.tuxfamily.org/x11-protocol-other/index.html

=head1 LICENSE

Copyright 2011, 2012 Kevin Ryde

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
