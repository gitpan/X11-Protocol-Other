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
package X11::Protocol::Ext::TOG_CUP;
use strict;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 12;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;

# http://www.xfree86.org/current/specindex.html
# http://www.xfree86.org/current/tog-cup.html
#
# CVE-2007-6428
#     http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-6428
#     xfree86 and x.org before 1.4.1 GetReservedColormapEntries read
#     arbitrary memory
#


### TOG_CUP.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

my $reqs =
  [
   ["CupQueryVersion",  # 0
    sub {
      my ($X, $major, $minor) = @_;
      ### CupQueryVersion
      return pack 'SS', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],

   ["CupGetReservedColormapEntries",  # 1
    sub {
      my ($X, $screen) = @_;
      ### CupGetReservedColormapEntries
      return pack 'L', $screen;
    },
    sub {
      my ($X, $data) = @_;
      ### CupGetReservedColormapEntries reply
      my $num = unpack 'x8L', $data;
      # obey $num rather than the reply length
      return map {[unpack 'LSSSC', substr ($data, 28 + 12*$_, 12)]}
        1 .. $num;
    }],

   ["CupStoreColors",  # 2
    sub {
      my $X = shift;
      my $colormap = shift;
      return pack('L', $colormap) . join('', map {pack 'Lx8'} @_);
    }],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### TOG-CUP new()

  _ext_requests_install ($X, $request_num, $reqs);

  # Any need to negotiate a version?
  #  my ($major, $minor) = $X->req('CupQueryVersion', 1, 0);
  # if ($major != 1) {
  #   carp "Unrecognised TOG-CUP major version, got $major want 1";
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

=for stopwords Colormap colormap arrayref RGB Ryde

=head1 NAME

X11::Protocol::Ext::TOG_CUP - colormap utilization policy extension

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('TOG-CUP')
   or print "TOG-CUP extension not available";

=head1 DESCRIPTION

The TOG-CUP extension ...

=head1 REQUESTS

The following are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('TOG-CUP');

=over

=item C<($server_major, $server_minor) = $X-E<gt>CupQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more).

The current code supports up to 1.0.

Return the extension version number on the server.

=item C<@colors = $X-E<gt>CupGetReservedColormapEntries ($screen)>

Return a list of the colormap entries which are reserved in the default
colormap of screen number C<$screen> (integer 0 upwards).  Each returned
element is an arrayref

    [ $pixel, $red16, $blue16, $green16, $alloc_flags ]

C<$red16>, C<$blue16> and C<$green16> are RGB colour components in the range
0 to 65535.  C<$alloc_flags> is currently unused.

The core protocol fixed colours C<$X-E<gt>{'black_pixel'}> and
C<$X-E<gt>{'white_pixel'}> are included in the return, and there may be more
reserved colours.

=item C<@colors = $X-E<gt>CupStoreColors ($colormap, $pixel1, $pixel2, ...)>

Allocate the given pixels in C<$colormap> to the reserved colours from the
default colormap of the screen.  The pixels are read-only as per
C<AllocColors>.

The return is a list of arrayref elements the same as
C<CupGetReservedColormapEntries> above.

    [ $pixel, $red16, $blue16, $green16, $alloc_flags ]

Each C<$pixel> is the pixel stored, and the RGB parts are the colour stored
there.  C<$alloc_flags> bit 0x08 is set if the pixel was successfully
allocated.  Other bits in C<$alloc_flags> are unused.

=back

=head1 SEE ALSO

L<X11::Protocol>

Colormap Utilization Policy and Extension, Version 1.0,
C<http://www.xfree86.org/current/tog-cup.html>

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
