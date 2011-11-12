# mem address as 64-bit
# OperationNotSupported error name too generic?


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
package X11::Protocol::Ext::XFree86_DGA;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 13;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/include/X11/extensions/xf86dga1const.h
# /usr/include/X11/extensions/xf86dga1proto.h
#
# /usr/include/X11/extensions/xf86dgaconst.h
# /usr/include/X11/extensions/xf86dgaproto.h
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz

### XFree86_DGA.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (XDGAPixmapMode =>  ['Large','Small'],
    );
my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);


#------------------------------------------------------------------------------
# events

my $XF86GA_event
  = [ 'xCxxLsssSx16',
      'detail',
      'time',
      'dx',
      'dy',
      'screen',
      'state',
    ];


#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['XF86DGAQueryVersion',  # 0
    &_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XFree86_DGA'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XF86DGAGetVideoLL',  # 1
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L4', $data; # (offset,width,bank_size,ram_size)
    },
   ],

   ['XF86DGADirectVideo',  # 2
    sub {
      my ($X, $screen, $enable) = @_;
      return pack 'SS', $screen, $enable;
    }],

   ['XF86DGAGetViewPortSize',  # 3
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data; # (width,height)
    },
   ],

   ['XF86DGASetViewPort',  # 4
    sub {
      shift;  # ($X, $screen, $x, $y)
      return pack 'SxxLL', @_;
    },
   ],

   ['XF86DGAGetVidPage',  # 5
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (vidpage)
    },
   ],

   ['XF86DGASetVidPage',  # 6
    sub {
      shift;  # ($X, $screen, $vidpage)
      return pack 'SS', @_;
    },
   ],

   ['XF86DGAInstallColormap',  # 7
    sub {
      my ($X, $screen, $colormap) = @_;
      return pack 'SxxL', $screen, $colormap;
    }],

   ['XF86DGAQueryDirectVideo',  # 8
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (flags)
    },
   ],

   ['XF86DGAViewPortChanged',  # 9
    sub {
      shift;  # ($X, $screen, $n)
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (result)
    } ],

   #---------------------------------------------------------------------------
   # version ...

   undef,  # 10
   undef,  # 11

   ['XDGAQueryModes',   # 12
    \&_request_screen16,
   ],
   ['XDGASetMode',  # 13
    sub {
      shift;  # ($X, $screen, $mode, $pid)
      return pack 'L3', @_;
    },
   ],

   [ 'XDGASetViewport',  # 14
     sub {
       shift;  # ($X, $screen, $x, $y, $flags)
       return pack 'LSSL', @_;
     },
   ],

   [ 'XDGAInstallColormap', # 15
     \&_request_card32s ],  # ($X, $screen, $colormap)

   [ 'XDGASelectInput', # 16
     \&_request_card32s ],  # ($X, $screen, $mask)

   [ 'XDGAFillRectangle', # 17
     sub {
       shift;  # ($X, $screen, $x, $y, $width, $height, $color)
       return pack 'LSSSSL', @_;
     } ],

   [ 'XDGACopyArea',  # 18
     sub {
       shift;  # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y)
       return pack 'LS*', @_;  # x,y's are CARD16s, so unsigned
     } ],

   [ 'XDGACopyTransparentArea',  # 19
     sub {
       shift;
       # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y, $key)
       return pack 'LS6L', @_;  # x,y's are CARD16s, so unsigned
     } ],

   [ 'XDGAGetViewportStatus',  # 20
     \&_request_screen16 ],

   [ 'XDGASync',  # 21
     \&_request_screen16,
     sub {  # ($X, $data)  empty
       return;
     } ],

   [ 'XDGAOpenFramebuffer',  # 22
     \&_request_screen16,
     sub {
       my ($X, $data) = @_;
       return unpack 'x8L6', $data; # (mem1,mem2,size,offset,extra)
     } ],

   [ 'XDGACloseFramebuffer', # 23
     \&_request_screen16 ],

   [ 'XDGASetClientVersion', # 24
     sub {
       shift;
       # ($X, $client_major, $client_minor)
       return pack 'SS', @_;
     } ],

   [ 'XDGAChangePixmapMode',  # 25
     sub {
       shift;  # ($X, $screen, $x, $y, $flags)
       return pack 'LSSL', @_;
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8SS', $data; # (x,y)
     },
   ],

   [ 'XDGACreateColormap',  # 26
     sub {
       shift;  # ($X, $screen, $id, $mode, $alloc)
       return pack 'LLLCxxx', @_;
     } ],
  ];

sub _request_screen16 {
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
  ### XF86DGA new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'ClientNotLocal',        # 0
                            'NoDirectVideoMode',     # 1
                            'ScreenNotActive',       # 2
                            'DirectNotActivated',    # 3
                            'OperationNotSupported', # 4
                           );
  # ($server_major >= 2 ? (...) : ()));

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
sub _ext_const_error_install {
  my $X = shift;  # ($X, $errname1,$errname2,...)
  ### _ext_const_error_install: @_
  my $error_num = shift;
  my $aref = $X->{'ext_const'}{'Error'}  # copy
    = [ @{$X->{'ext_const'}{'Error'} || []} ];
  my $href = $X->{'ext_const_num'}{'Error'}  # copy
    = { %{$X->{'ext_const_num'}{'Error'} || {}} };
  my $i;
  foreach $i (0 .. $#_) {
    $aref->[$error_num + $i] = $_[$i];
    $href->{$_[$i]} = $error_num + $i;
  }
}

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XFree86_DGA - direct video memory access

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

=item C<($server_major, $server_minor) = $X-E<gt>XF86DGAQueryVersion ()>

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
