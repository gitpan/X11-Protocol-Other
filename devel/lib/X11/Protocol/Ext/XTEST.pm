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

BEGIN { require 5 }
package X11::Protocol::Ext::XTEST;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 10;
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
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/share/doc/x11proto-input-dev/XIproto.txt.gz
# /usr/share/doc/x11proto-input-dev/XI2proto.txt.gz
# /usr/include/X11/extensions/XIproto.h
# /usr/include/X11/extensions/xtestconst.h

### XTEST.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

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
      return join('',@_);
    }],

   ['XTestGrabControl',  # 3
    sub {
      my ($X, $impervious) = @_;
      return pack 'Cx3', $impervious;
    }],
  ];

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

=head1 DESCRIPTION

The XTEST extension allows clients to generate synthetic keyboard and mouse
pointer button presses and movements.  Relevant press, release and motion
events are sent to all interested client just as if for user input.

It's designed to exercise library or server features which would otherwise
require user interaction.  The C<XTestGrabControl> allows this to be done
even during a C<GrabServer> by another client.

An C<XTestCompareCursor> allows the mouse pointer cursor to be checked (an
otherwise write-only window setting), mainly to see that an intended cursor
is shown by some sort of subroutine, library, etc.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XTEST');

=over

=item C<($server_major, $server_minor) = $X-E<gt>XTestGetVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code supports up to 2.1 and the intention would be to
automatically negotiate in C<init_extension> if/when necessary.

=item C<$is_same = $X-E<gt>XTestCompareCursor ($window, $cursor)>

Return true if the cursor set in the attributes of C<$window> is equal to
C<$cursor>.  C<$cursor> can be

=over

=item *

An XID of a cursor.

=item *

Sting "None" (or 0).

=item *

String "CurrentCursor" (or 1) for the currently displayed cursor.

=back

=item C<$X-E<gt>XTestFakeInput ($event, ...)>

Simulate user input on the server.  C<$event> should be a byte string packet
as from C<$X-E<gt>pack_event>.  The following core event types can be faked,

    KeyPress
    KeyRelease
    ButtonPress
    ButtonRelease
    MotionNotify

For example,

    $X->XTestFakeInput ($X->pack_event
                         (name    => 'ButtonPress',
                          detail  => 3, # button number
                          time    => 0,
                          root    => 0,
                          event   => 0,
                          child   => 'None',
                          root_x  => 0,
                          root_y  => 0,
                          event_x => 0,
                          event_y => 0,
                          state   => 0,
                          same_screen => 0));

Only some of the fields in the event data are used, though as of
C<X11::Protocol> 0.56, C<$X-E<gt>pack_event()> requires all fields (or Perl
warnings result).

    time            milliseconds delay before event

    Key/Button Press/Release
        detail      key code or button number

    MotionNotify
        detail      flag 0=absolute x,y, 1=relative x,y
        root        XID of root window, or "None"
        root_x      \ pointer position to move to
        root_y      /

The C<time> field is how long in milliseconds the server should wait before
playing the event.  0 or CurrentTime means no delay.

The use of C<pack_event()> in the arguments here allows future extension
events too, though it's a bit of a chore to make those packs just for the
plain core events.

Multiple event arguments can be given when a user input needs more than one
event packet to describe.  The core events are just one per request, but for
example the C<XInputExtension> C<DeviceMotionNotify> takes following
C<DeviceValuator> events for device axis values.

    $X->XTestFakeInput ($device_motion_event,
                        $device_valuator_event1,
                        $device_valuator_event2);

Note that the event fields received in a C<$X> event handler function cannot
be passed directly to C<XTestFakeInput> to replay it.  The C<time> field
should be cleared to zero as it's a delay not a timestamp, and the C<detail>
field of C<MotionNotify> should generally be cleared to zero (absolute
C<root_x>,C<root_y>) as it's a relative flag, not a hint flag.

Be careful when faking a C<ButtonPress>, it may be necessary to fake a
matching C<ButtonRelease> too.  On the X.org server circa 1.9.x 

=item C<$X-E<gt>XTestGrabControl ($impervious)>

Make the current client impervious to C<GrabServer> requests by others.

If C<$impervious> is 1 then the current client can continue to make requests
even when another client has grabbed the server.

If C<$impervious> is 0 then the current client behaves as normal.  Its
requests must wait during a C<GrabServer> by another client.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XInputExtension>

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
