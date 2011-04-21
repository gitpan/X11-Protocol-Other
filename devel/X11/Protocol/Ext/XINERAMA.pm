# Copyright 2011 Kevin Ryde

# PanoramiXGetState, PanoramiXGetScreenCount, PanoramiXGetScreenSize
# return window ?
#
# PanoramiXGetScreenSize



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
package X11::Protocol::Ext::XINERAMA;
use strict;

use vars '$VERSION';
$VERSION = 3;

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/include/X11/extensions/Xinerama.h
# /usr/include/X11/extensions/panoramiXext.h
#    Xlib.
# /usr/include/X11/extensions/panoramiXproto.h
#    Protocol structs etc.
#

### XINERAMA.pm loads

my $reqs =
  [
   ["PanoramiXQueryVersion",  # 0
    sub {
      my ($X, $major, $minor) = @_;
      ### PanoramiXQueryVersion
      return pack 'CCxx', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],

   ["PanoramiXGetState",  # 1
    \&_request_xids,
    sub {
      my ($X, $data) = @_;
      ### PanoramiXGetState reply
      ### state and window: unpack 'xCx6L', $data
      return unpack 'xC', $data;

      # my ($state, $window) = unpack 'xCx6LL', $data;
      # return $state;
    }],

   ["PanoramiXGetScreenCount",  # 2
    \&_request_xids,
    sub {
      my ($X, $data) = @_;
      ### PanoramiXGetScreenCount reply: unpack "C*", $data
      ### count and window: unpack 'xCx6L', $data
      return unpack 'xC', $data;
    }],

   ["PanoramiXGetScreenSize",  # 3
    sub {
      my ($X, $window, $screen) = @_;
      return pack 'LL', $window, $screen;
    },
    sub {
      my ($X, $data) = @_;
      ### PanoramiXGetScreenSize reply
      ### size,win,screen: unpack 'x8L4', $data
      return unpack 'x8LL', $data;
    }],

   ["XineramaIsActive",  # 4
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data;
    }],

   ["XineramaQueryScreens",  # 5
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      my $num = unpack 'x8L', $data;
      ### XineramaQueryScreens reply: unpack 'x8L*', $data
      map {[ unpack 'ssSS', substr($data, 32+8*$_, 8) ]} 0 .. $num-1;
    }],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XINERAMA new()

  _ext_requests_install ($X, $request_num, $reqs);

  # Any need to negotiate?
  # my ($major, $minor) = $X->req('XineramaQueryVersion', 2, 0);
  # ### $major
  # ### $minor

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
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords XINERAMA Xinerama XID arrayrefs Ryde

=head1 NAME

X11::Protocol::Ext::XINERAMA - ...

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('XINERAMA')
   or print "XINERAMA extension not available";

=head1 DESCRIPTION

The XINERAMA extension ...

=head1 REQUESTS

The following are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('XINERAMA');

=over

=item C<($server_major, $server_minor) = $X-E<gt>XineramaQueryVersion ($client_major, $client_minor)>

Return the extension version number on the server.

=item C<$bool = $X-E<gt>PanoramiXGetState ($window)>

Return non-zero if Xinerama is active for C<$window> (an XID).

=item C<$flag = $X-E<gt>PanoramiXGetScreenCount ($window)>

Return the number of  screens for C<$window> (an XID).

=item C<($width, $height) = $X-E<gt>PanoramiXGetScreenSize ($window, $screen)>

Return the size in pixels of screen number C<$screen> for C<$window> (an
XID).

=item C<$bool = $X-E<gt>XineramaIsActive ()>

Return non-zero if Xinerama is active on the C<$X> server.

=item C<@info = $X-E<gt>XineramaQueryScreens ()>

Return information about the Xinerama screens on the C<$X> server.  The
return is a list of arrayrefs giving the position and size in pixels of each
screen

    [ $x,$y, $width,$height ]

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
