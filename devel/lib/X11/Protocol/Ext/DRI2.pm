# mem address as 64-bit



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
package X11::Protocol::Ext::DRI2;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 11;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


#
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/include/X11/extensions/xtestconst.h

### DRI2.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

my $reqs =
  [
   ['DRI2QueryVersion',  # 0
    \&_request_card32s,  # ($X, $client_major, $client_minor)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8LL', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'DRI2'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['DRI2Connect',  # 1
    \&_request_screen,
    sub {
      my ($X, $data) = @_;
      my ($drivlen, $devlen) = unpack 'x8LL', $data;
      return (substr($data, 32,$drivlen),
              substr($data, 32+$drivlen, $devlen));
    },
   ],

   ['DRI2Authenticate',  # 2
    \&_request_card32s,  # ($X, $window, $magic)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (authenticated)
    },
   ],

   ['DRI2CreateDrawable',  # 3
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2DestroyDrawable',  # 4
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2GetBuffers',  # 5
    \&_request_card32s,  # ($X, $drawable, $count)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L3', $data; # (width,height,count)
    },
   ],

   ['DRI2CopyRegion',  # 6
    \&_request_card32s,  # ($X, $drawable, $region, $dest, $src)
    sub {  # ($X, $data)  empty
      return;
    },
   ],

   #------------------------------------
   # protocol 1.1

   ['DRI2GetBuffersWithFormat',  # 7
    sub {
      my ($X, $screen, $colormap) = @_;
      return pack 'SxxL', $screen, $colormap;
    }],

   #------------------------------------
   # protocol 1.2

   ['DRI2SwapBuffers',  # 8
    sub {
      my ($X, $drawable, $target_msc, $divisor, $remainder) = @_;
      return pack 'L*', $drawable,
        _hilo($target_msc), _hilo($divisor), _hilo($remainder);
    },
    sub {
      my ($X, $data) = @_;
      return _two(unpack 'x8LL', $data); # (swap)
    },
   ],

   ['DRI2GetMSC',  # 9
    \&_request_card32s,  # ($X, $drawable)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data;  # (result)
    } ],

   ['DRI2WaitMSC',   # 10
    sub {
      my ($X, $drawable, $target_msc, $divisor, $remainder) = @_;
      return pack 'L*', $drawable,
        _hilo($target_msc), _hilo($divisor), _hilo($remainder);
    },
   ],
   ['DRI2WaitSBC',  # 11
    sub {
      my ($X, $drawable, $target_sbc) = @_;
      return pack 'L*', $drawable, _hilo($target_sbc);
    },
   ],

   [ 'DRI2SwapInterval',  # 12
     \&_request_card32s,  # ($X, $drawable, $interval)
   ],
  ];

sub _request_screen {
  shift;  # ($X, $screen)
  return pack 'Sxx', @_;
},

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
  ### DRI2 new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  return bless { }, $class;
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

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::DRI2 - direct video memory access

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XFree86-DGA')
   or print "XFree86-DGA extension not available";

=head1 DESCRIPTION

The XFree86-DGA extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XFree86-DGA');

=head2 XFree86-DGA 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>DRI2QueryVersion ()>

Return the DGA protocol version implemented by the server.

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
