# 1.0, 1.1 exercise GetBuffers

# 1.2 counters as 64-bit



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
package X11::Protocol::Ext::DRI2;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 19;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/share/doc/x11proto-dri2-dev/dri2proto.txt.gz
#
# /usr/include/X11/extensions/dri2proto.h
# /usr/include/X11/extensions/dri2tokens.h
#
# /so/xorg/xorg-server-1.10.0/hw/xfree86/dri2/dri2ext.c
#    Server source.
#
# /so/xfree4/unpacked/usr/share/doc/xserver-xfree86/README.DRI.gz
#
# /usr/share/xcb/dri2.xml
#    xcb (dri2 1.1)
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz

### DRI2.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 2;


#------------------------------------------------------------------------------
# 64-bits

{
  my $uv = ~0;
  my $bits = 0;
  while ($uv && $bits < 64) {
    $uv >>= 1;
    $bits++;
  }

  if ($bits >= 64) {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_card64 {
  my ($hi,$lo) = @_;
  ### _hilo_to_sv(): "$hi $lo"
  if ($hi & 0x8000_0000) {
    $hi -= 0x8000_0000;
    $lo += -(1<<63);
  }
  ### $hi
  ### $lo
  ### hi shift: $hi<<1
  ### result: ($hi << 32) + $lo
  return ($hi << 32) + $lo;
}
1;
HERE
  } else {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use Math::BigInt;
sub _hilo_to_card64 {
  my ($hi,$lo) = @_;
  my $sv = ($hi << 32) + $lo;
  my $sv = Math::BigInt->new($hi)->blsft(32)->badd($lo);
  if ($hi & 0x8000_0000) {
    $sv = -$sv;
  }
  return $sv;
}
1;
HERE
  }
}

sub _card64_to_hilo {
  my ($sv) = @_;
  return ($sv >> 32,          # hi
          $sv & 0xFFFF_FFFF); # lo
}


#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     DRI2Driver     => ['DRI', 'VDPAU'],
     DRI2Attachment => [qw(
                            FrontLeft
                            BackLeft
                            FrontRight
                            BackRight
                            Depth
                            Stencil
                            Accum
                            FakeFrontLeft
                            FakeFrontRight
                            DepthStencil
                            Hiz
                         )],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# events

my $BufferSwapComplete_event = [ 'xCxxL5',
                                 ['subtype','XFixesSelectionNotifySubtype'],
                                 'window',
                                 ['owner',['None']], # window
                                 'selection',        # atom
                                 'time',
                                 'selection_time',
                               ];

my $InvalidateBuffers_event = [ 'xCxxL5',
                                ['subtype','XFixesSelectionNotifySubtype'],
                                'window',
                                ['owner',['None']], # window
                                'selection',        # atom
                                'time',
                                'selection_time',
                              ];

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['DRI2QueryVersion',    # 0
    \&_request_card32s, # ($X, $client_major, $client_minor)
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
    sub {
      my ($X, $window, $driver_type) = @_;
      return pack 'LL', $window, $X->num('DRI2Driver',$driver_type);
    },
    sub {
      my ($X, $data) = @_;
      ### DRI2Connect() reply length: length($data)
      my ($driver_len, $device_len) = unpack 'x8LL', $data;
      ### $driver_len
      ### $device_len
      return (substr($data, 32,
                     $driver_len),
              substr($data, 32 + X11::Protocol::padding($driver_len),
                     $device_len));
    },
   ],

   ['DRI2Authenticate',  # 2
    \&_request_card32s,  # ($X, $window, $token)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # ($authenticated)
    },
   ],

   ['DRI2CreateDrawable',  # 3
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2DestroyDrawable',  # 4
    \&_request_card32s,  # ($X, $drawable)
   ],

   ['DRI2GetBuffers',  # 5
    sub {  # ($X, $drawable, $attach...)
      my $X = shift;
      my $drawable = shift;

      ### DRI2GetBuffers(), num_attach: scalar(@_)
      ### attaches: (map {$X->num('DRI2Attachment',$_)} @_)
      ### data: pack 'L*',$drawable,scalar(@_), map {$X->num('DRI2Attachment',$_)} @_

      return pack 'L*',
        $drawable,
          scalar(@_), # num attachments
            map {$X->num('DRI2Attachment',$_)} @_;
    },
    \&_reply_get_buffers ],

   ['DRI2CopyRegion',  # 6
    \&_request_card32s,  # ($X, $drawable, $region, $dest, $src)
    sub {  # ($X, $data)  empty
      return;
    },
   ],

   #------------------------------------
   # protocol 1.1

   ['DRI2GetBuffersWithFormat',  # 7
    sub {  # ($X, $drawable, $attach_format...)
      my $X = shift;
      my $drawable = shift;

      ### DRI2GetBuffers(), num_attach_formats: scalar(@_)

      return pack 'L*',
        $drawable,
          scalar(@_), # num attachments
            map {
              my ($attach, $format) = @$_;
              ($X->num('DRI2Attachment',$attach), $format)
            } @_;
    },
    \&_reply_get_buffers ],



   #------------------------------------
   # protocol 1.2

   ['DRI2SwapBuffers',  # 8
    sub {
      my ($X, $drawable, $target_msc, $divisor, $remainder) = @_;
      return pack('L*',
                  $drawable,
                  _card64_to_hilo($target_msc),
                  _card64_to_hilo($divisor),
                  _card64_to_hilo($remainder));
    },
    sub {
      my ($X, $data) = @_;
      return _hilo_to_card64 (unpack 'x8LL', $data); # swap hi/lo
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

sub _reply_get_buffers {
  my ($X, $data) = @_;
  ### _reply_get_buffers(), length: length($data)

  my ($width, $height, $num_buffers) = unpack 'x8LLL', $data;
  ### $width
  ### $height
  ### $num_buffers

  return ($width, $height, _unpack_buffers($X,$data,$num_buffers));
}
sub _unpack_buffers {
  my ($X, $data, $num_buffers) = @_;
  return map {
    # (attach, name, pitch, cpp, flags)
    [ unpack 'L*', substr($data,12+$_*20,20) ]
  } 1 .. $num_buffers;
}

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### DRI2 new()

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  return bless { }, $class;
}

#------------------------------------------------------------------------------
# generic

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}
sub _request_screen16 {
  shift;  # ($X, $screen)
  @_ == 1 or croak "Single screen number parameter expected";
  return pack 'Sxx', @_;
}

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
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

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::DRI2 - direct video memory access

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('DRI2')
   or print "DRI2 extension not available";

=head1 DESCRIPTION

The DRI2 extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('DRI2');

=head2 DRI2 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>DRI2QueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code in this module supports up to 1.2 and the intention would
be to automatically negotiate in C<init_extension()> if necessary.

=item C<($driver_name, $device_name) = $X-E<gt>DRI2Connect ($window, $driver_type)>

Get the driver and device filename to use on C<$window> (integer XID).
C<$driver_type> is one of

    "DRI"      0
    "VDPAU"    1

If C<$driver_type> is unknown or the client is not on the same machine as
the server then the returned C<$driver_name> and C<$device_name> are empty
strings "".

=item C<$bool = $X-E<gt>DRI2Authenticate ($window, $token_type)>

Ask the server to authenticate C<$token> so the client can access DRI memory
on the screen associated with C<$window> (an integer XID).  The return is 1
if successful or 0 if C<$token> is no good.

=item C<($width,$height,$buffer...) = $X-E<gt>DRI2GetBuffers ($drawable, $attach...)>

Get buffers for C<$drawable> (integer XID) at the given C<$attach> points.
Each C<$attach> argument is

    FrontLeft           0
    BackLeft            1
    FrontRight          2
    BackRight           3
    Depth               4
    Stencil             5
    Accum               6
    FakeFrontLeft       7
    FakeFrontRight      8
    DepthStencil        9     new in protocol 1.1
    Hiz                10

=item C<$X-E<gt>DRI2CopyRegion ($drawable, $region, $src_attach, $dst_attach)>

Copy C<$region> (integer XID of XFIXES Region type) from C<$src_attach> to
C<$dst_attach> buffers of C<$drawable> (integer XID).  The attach arguments
are per C<DRI2GetBuffers()> above.

=back

=head1 SEE ALSO

L<X11::Protocol>

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
