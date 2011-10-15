# pack_event ?





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
$VERSION = 12;
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
      return join('',map {_fake_input_pack($X,$_)} @_);
    }],

   ['XTestGrabControl',  # 3
    sub {
      my ($X, $impervious) = @_;
      return pack 'Cxxx', $impervious;
    }],
  ];

sub _fake_input_pack {
  my ($X, $href) = @_;

  # if (my $data = $href->{'data'}) {
  #   return $data;
  # } else {

  return $X->pack_event (# name - mandatory always

                         ($href->{'name'} eq 'MotionNotify'
                          ? (# default absolute root_x,root_y for motion
                             detail => 0)
                          : ( # detail - mandatory for Key/Button
                            )),

                         ($href->{'name'} eq 'MotionNotify'
                          ? ( # root_x,root_y - mandatory for MotionNotify
                            )
                          : ( # unused by Key/Button, zero for pack
                             root_x => 0, root_y => 0)),

                         time    => 0,   # default no delay
                         root    => 0,   # default current screen

                         # unused by XTestFakeInput, zero for the pack
                         event   => 0,   # window
                         child   => 0,   # window
                         event_x => 0,
                         event_y => 0,
                         state   => 0,
                         same_screen => 0,

                         %$href
                        );
}

#        For key events, this field is interpreted as the physical keycode. If
#        the keycode is less than min-keycode or greater than max-keycode, as
#        returned in the connection setup, then a Value error occurs. For button
#        events, this field is interpreted as the physical (or core) button,
# detail meaning it will be mapped to the corresponding logical button according
#        to the most recent SetPointerMapping request. If the button number is
#        less than one or greater than the number of physical buttons, then a
#        Value error occurs. For motion events, if this field is True , then
#        rootX and rootY are relative distances from the current pointer
#        location; if this field is False, then they are absolute positions.


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
                       detail => 3 });  # button 3

=head1 DESCRIPTION

The XTEST extension allows clients to synthesize user keyboard and mouse
pointer actions.  Press, release and motion events are sent to all
interested clients of the relevant window just as for user input.

XTEST is designed to exercise library or server features which would
otherwise require user interaction.  Only user input events are synthesized,
it's not general purpose event replaying.

Test input can continue even under a C<GrabServer> by using
C<XTestGrabControl>.  Mouse cursor display can be checked with
C<XTestCompareCursor>, to see that an intended cursor is applied by whatever
subroutine, library, etc.

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
automatically negotiate in C<init_extension> if/when necessary.

=item C<$is_same = $X-E<gt>XTestCompareCursor ($window, $cursor)>

Return true if the cursor attribute of C<$window> is equal to C<$cursor>.
C<$cursor> can be

=over

=item *

An XID (integer) of a cursor.

=item *

String "None" (or 0).

=item *

String "CurrentCursor" (or 1) for the currently displayed cursor.

=back

This can be used in two way.  Either give a particular C<$cursor> XID to
check if a C<$window> has that.  Or alternatively make a C<$window> with a
particular cursor and then pass "CurrentCursor" to see if that's the
displayed cursor.  The latter can be used for instance to check the cursor
shown under a C<GrabPointer>.

=item C<$X-E<gt>XTestFakeInput ({name=E<gt>...})>

Simulate user input.  The argument is a hashref of event fields for
C<$X-E<gt>pack_event> with defaults for fields not used by the fakery.

    name        string "ButtonPress" etc
    time        milliseconds delay before event, default 0

    for "ButtonPress"/"ButtonRelease",
    detail      physical button number (1 upwards)

    for "KeyPress"/"KeyRelease",
    detail      key code (integer)

    for "MotionNotify",
    root_x      \ pointer position to move to
    root_y      /
    root        XID of root window, default "None" for current
    detail      flag 0=absolute, 1=relative, default 0

For example physical button 3 press.

    $X->XTestFakeInput ({ name   => 'ButtonPress',
                          detail => 3 });

Note that the button number is the "physical" button, before the core
protocol C<SetPointerMapping> is applied.  Consult C<GetPointerMapping> to
see which (if any) physical button corresponds to a desired "logical" button
number.

Or a motion moving the pointer (similar to a C<WarpPointer>),

    $X->XTestFakeInput ({ name   => 'MotionNotify',
                          root_x => 123,
                          root_y => 456 });

For C<MotionNotify> the C<detail> field can be 1 to move relative to the
current mouse position,

    $X->XTestFakeInput ({ name   => 'MotionNotify',
                          root_x => 10,
                          root_y => -20,
                          detail => 1,   # relative motion
                        });  

For C<MotionNotify> the C<root> field is the root window XID (integer) to
move on.  The default is "None" (or 0) and means the screen the pointer is
currently on.

C<time> is how long in milliseconds the server should wait before playing
the event.  The default is 0 for no delay.  No further requests are
processed from the current client until the time elapses, which means a
sequence of C<XTestFakeInput> with delays executes serially, with cumulative
delay times.

Extension events can be faked once C<init_extension> has been done so
they're recognised by C<pack_event>.  It's up to the server or the relevant
extension which events are user input which can be faked.

Extension input may require more than one event packet to describe.  For
example the C<XInputExtension> event C<DeviceMotion> may need further
C<DeviceValuator> events.  Pass additional arguments to C<XTestFakeInput>
for those extra event packets,

    $X->XTestFakeInput ({ name   => 'DeviceMotion', ... },
                        { name   => 'DeviceValuator', ... },
                        { name   => 'DeviceValuator',  ... });  

In all cases an C<XTestFakeInput> request is a single user input, so for
instance a button press and button release must be two C<XTestFakeInput>
requests.

Generally the event fields from a C<$X> event handler cannot be passed
directly to C<XTestFakeInput> to replay it.  In particular,

=over

=item *

C<time> in an event is a timestamp, not a delay, so would want to be zeroed.

=item *

For C<MotionNotify>, C<detail> in an event is the hint mechanism, so would
want to be zeroed for the absolute/relative flag.

=item *

For C<ButtonPress> and C<ButtonRelease>, C<detail> in an event is a logical
button number, after the C<SetPointerMapping> transform, whereas
C<XFakeInput> takes a phyical number.  An inverse through the
C<GetPointerMapping> table would be needed.

=back

Be careful when faking a C<ButtonPress> as it may be important to fake a
matching C<ButtonRelease> too.  On the X.org server circa 1.9.x, after a
synthetic press the physical mouse buttons don't work to generate a release
and the button is left hung (presumably in the normal implicit pointer
grab).

=item C<$X-E<gt>XTestGrabControl ($impervious)>

Control the current client's behaviour under a C<GrabServer> by another
client.

If C<$impervious> is 1 then the current client can continue to make
requests, ie. it's impervious to server grabs by other clients.

If C<$impervious> is 0 then the current client behaves as normal, meaning
its requests must wait during any C<GrabServer> by another client.

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
