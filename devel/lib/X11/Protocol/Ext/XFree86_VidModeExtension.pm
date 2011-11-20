# ...



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
package X11::Protocol::Ext::XFree86_VidModeExtension;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 14;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/include/X11/extensions/xf86vm.h
# /usr/include/X11/extensions/xf86vmproto.h
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz

### XFree86_VidModeExtension.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------
# events

my $XF86VidModeNotify_event
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
   ['XF86VidModeQueryVersion',  # 0
    &_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XFree86_VidModeExtension'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XF86VidModeGetModeLine',  # 1
    \&_request_screen,
    sub {
      my ($X, $data) = @_;
      die;
    },
   ],

   ['XF86VidModeModModeLine',  # 2
    sub {
      shift;
      # ($X, $screen, 
      #  $hdisplay,
      #  $hsyncstart,
      #  $hsyncend,
      #  $htotal,
      #  $hskew,
      #  $vdisplay,
      #  $vsyncstart,
      #  $vsyncend,
      #  $vtotal,
      # $flags,
      # or 'LS9xxLx4' in 0.x protocol ...
      return pack 'LS9xxLx12x4', $screen, $enable;
    }],

   ['XF86VidModeSwitchMode',  # 3
    \&_request_screen,
    sub {
      my ($X, $data) = @_;
      die;
    },
   ],

   ['XF86VidModeGetMonitor',  # 4
    \&_request_screen,
    sub {
      my ($X, $data) = @_;
      die;
    },
   ],

   ['XF86VidModeLockModeSwitch',  # 5
    \&_request_screen,
   ],

   ['XF86VidModeGetAllModeLines',  # 6
    \&_request_screen,
   ],

   ['XF86VidModeAddModeLine',  # 7
    sub {
      my ($X, $screen) = @_;
      die;
    }],

   ['XF86VidModeDeleteModeLine',  # 8
    \&_request_screen,
   ],

   ['XF86VidModeValidateModeLine',  # 9
    sub {
      shift;  # ($X, $screen, $n)
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (result)
    } ],

   ['XF86VidModeSwitchToMode',   # 10
    \&_request_screen,
   ],

   ['XF86VidModeGetViewPort',   # 11
    \&_request_screen,
   ],

   ['XF86VidModeSetViewPort',   # 12
    \&_request_screen,
   ],

   #---------------------------------------------------------------------------
   # protocol 2.0

   ['XF86VidModeGetDotClocks',  # 13
    \&_request_screen,
   ],

   [ 'XF86VidModeSetClientVersion',  # 14
     sub {
       shift;  # ($X, $screen, $x, $y, $flags)
       return pack 'LSSL', @_;
     },
   ],

   [ 'XF86VidModeSetGamma', # 15
     \&_request_card32s ],  # ($X, $screen, $colormap)

   [ 'XF86VidModeGetGamma', # 16
     \&_request_card32s ],  # ($X, $screen, $mask)

   [ 'XF86VidModeGetGammaRamp', # 17
     sub {
       shift;  # ($X, $screen, $x, $y, $width, $height, $color)
       return pack 'LSSSSL', @_;
     } ],

   [ 'XF86VidModeSetGammaRamp',  # 18
     sub {
       shift;  # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y)
       return pack 'LS*', @_;
     } ],

   [ 'XF86VidModeGetGammaRampSize',  # 19
     sub {
       shift;
       # ($X, $screen, $src_x,$src_y, $width,$height, $dst_x,$dst_y, $key)
       return pack 'LS6L', @_;
     } ],

   [ 'XF86VidModeGetPermissions',  # 20
     \&_request_screen,
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
  ### XF86VidMode new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'XF86VidModeBadClock',           # 0
                            'XF86VidModeBadHTimings',        # 1
                            'XF86VidModeBadVTimings',        # 2
                            'XF86VidModeModeUnsuitable',     # 3
                            'XF86VidModeExtensionDisabled',  # 4
                            'XF86VidModeClientNotLocal',     # 5
                            'XF86VidModeZoomLocked',         # 6
                           );

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

X11::Protocol::Ext::XFree86_VidModeExtension - video modes

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XFree86-VidModeExtension')
   or print "XFree86-VidModeExtension extension not available";

=head1 DESCRIPTION

The XFree86-VidModeExtension extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XFree86-VidModeExtension');

=head2 XFree86-VidModeExtension 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XF86VidModeQueryVersion ()>

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
