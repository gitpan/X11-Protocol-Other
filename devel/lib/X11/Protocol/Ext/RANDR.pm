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
package X11::Protocol::Ext::RANDR;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 17;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;

# /usr/share/doc/x11proto-randr-dev/randrproto.txt.gz
#
# /usr/include/X11/extensions/randr.h
# /usr/include/X11/extensions/randrproto.h
#
# /usr/include/X11/extensions/Xrandr.h
#     Xlib
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     RandrState => ['NewValue', 'Deleted'],
     RandrNotifySubtype => ['CrtcChangeNotify',
                            'OutputChangeNotify',
                            'OutputPropertyNotify'],
     RandrSubPixel => ['Unknown',
                       'HorizontalRGB',
                       'HorizontalBGR',
                       'VerticalRGB',
                       'VerticalBGR',
                       'None'],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# events

my $RandrScreenChangeNotify_event
  = [ 'xCxxLLLLSSSSS',
      'rotation',
      'time',
      'config_time',
      'root',
      'window',
      'size_id',
      ['subpixel','RandrSubPixel'],
      'width',
      'height',
      'width_mm',
      'height_mm',
    ];


# version 1.2
my $RandrNotify_event
  = [ sub {
        my $X = shift;
        my $data = shift;
        ### RandrNotify unpack: @_[1..$#_]
        my $subtype = unpack 'xC', $data;
        push @_, subtype => $X->interp('RandrNotifySubtype',$subtype);
        if ($subtype == 0) {
          # CrtcChange
          my ($time, $window, $crtc, $mode, $rotation, $x,$y, $width,$height)
            = unpack 'xxxxLLLLSxxssSS';
          return (@_,  # base fields
                  time     => $time,
                  window   => $window,
                  crtc     => $crtc,
                  mode     => $mode,
                  rotation => $rotation,
                  x        => $x,
                  y        => $y,
                  width    => $width,
                  height   => $height,

                 );
        } elsif ($subtype == 1) {
          # OutputChange
          my ($time, $config_time, $window, $output, $crtc, $mode,
              $rotation, $connection, $subpixel)
            = unpack 'xxxxLLLLLLSCC';
          return (@_,  # base fields
                  time        => $time,
                  config_time => $config_time,
                  window      => $window,
                  crtc        => $crtc,
                  mode        => $mode,
                  rotation    => $rotation,
                  connection  => $connection,
                  subpixel    => $X->interp('RandrSubPixel',$subpixel),
                 );
        } elsif ($subtype == 2) {
          # OutputProperty
          my ($window, $output, $atom, $time, $state)
            = unpack 'xxxxLLLLC';
          return (@_,  # base fields
                  window  => $window,
                  output  => $output,
                  atom    => $atom,
                  time    => $time,
                  state   => $X->interp('RandrState',$state),
                 );
        }
      },
      sub {
        my ($X, %h) = @_;
        my $subtype = $X->num('RandrNotifySubtype',$h{'subtype'});
        my $data;
        if ($subtype eq '0') {
          # CrtcChange
          $data = pack('xCxxLLLLSxxssSS',
                       $subtype,
                       $h{'time'},
                       $h{'window'},
                       $h{'crtc'},
                       $h{'mode'},
                       $h{'rotation'},
                       $h{'x'},
                       $h{'y'},
                       $h{'width'},
                       $h{'height'});
        } elsif ($subtype eq '1') {
          # OutputChange
          $data = pack('xCxxLLLLLLSCC'
                       $subtype,
                       $h{'time'},
                       $h{'config_time'},
                       $h{'window'},
                       $h{'output'},
                       $h{'crtc'},
                       $h{'mode'},
                       $h{'rotation'},
                       $h{'connection'},
                       $X->num('RandrSubPixel',$h{'subpixel'}));
        } elsif ($subtype eq '2') {
          # OutputProperty
          $data = pack('xCxxLLLLCx11';
                       $subtype,
                       $h{'window'},
                       $h{'output'},
                       $h{'atom'},
                       $h{'time'},
                       $X->num('RandrState',$h{'state'}),
        } else {
          croak "Unrecognised RandrNotify subtype $subtype";
        }
        return ($data,
                1); # "do_seq" put in sequence number
      } ];


#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['RandrQueryVersion',  # 0
    \&_request_card32s,  # ($X, $client_major, $client_minor)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8LL', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8LL', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'RANDR'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   undef, # 1 - OldGetScreenInfo

   ['RandrSetScreenConfig',  # 2
    sub {
      my ($X, $drawable, $time, $config_time, $size, $rotation, $rate) = @_;
      # FIXME: pack of rotate+reflect ?
      return pack 'LLLSSSxx',
        $drawable, $time, $config_time, $size, $rotation, $rate;
    },
    sub {
      my ($X, $data) = @_;
      my ($config_status, $time, $config_time, $root, $subpixel)
        = unpack 'xC8LL', $data;

      return ($X->interp('RandrConfigStatus',$config_status),
              $time,
              $config_time,
              $root,
              $subpixel);

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8LL', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'RANDR'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   undef, # 3 - OldScreenChangeSelectInput

   ['RandrSelectInput',  # 4
    sub {
      shift; # ($X, $window, $enable)
      return pack 'LSxx', @_;
    }],
  ];

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XFIXES new()

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  my ($server_major, $server_minor)
    = $X->req ('XFixesQueryVersion',
               CLIENT_MAJOR_VERSION, CLIENT_MINOR_VERSION);

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'RandrScreenChangeNotify';
  $X->{'ext_events'}[$event_num] = $RandrScreenChangeNotify_event;
  # version 1.2
  if (($server_major <=> 1 || $server_minor <=> 2) >= 0) {
    $event_num++;
    $X->{'ext_const'}{'Events'}[$event_num] = 'RandrNotify';
    $X->{'ext_events'}[$event_num] = $RandrNotify_event;

    # Errors
    _ext_const_error_install ($X, $error_num, 'Output','Crtc','Mode');
  }

  return bless { major => $server_major,
                 minor => $server_minor,
               }, $class;
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

sub _event_update_X {
  my ($X, %event) = @_;
  my $window;
  if ($event{'name'} eq 'ConfigureNotify') {
    $window = $event{'window'};
  } elsif ($event{'name'} eq 'RandrScreenChangeNotify') {
    my $window = $event{'root'};
  } else {
    return;
  }
  foreach my $p ($X, @{$X->{'screens'}}) {
    if ($window == $p->{'root'}) {
      $p->{'width_in_pixels'} = $event{'width'};
      $p->{'height_in_pixels'} = $event{'height'};
      if (exists $event{'width_mm'}) {
        $p->{'width_in_millimetres'} = $event{'width_mm'};
        $p->{'height_in_millimetres'} = $event{'height_mm'};
      }
    }
  }
}

1;
__END__

=for stopwords RANDR CurrentCursor hashref KeyPress KeyRelease keycode ButtonPress ButtonRelase MotionNotify CurrentTime umm XInputExtension XID Ryde

=head1 NAME

X11::Protocol::Ext::RANDR - synthetic user input

=for test_synopsis

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('RANDR')
   or print "RANDR extension not available";

 $X->RandrFakeInput ({ name   => 'ButtonPress',
                       detail => 3 });  # button 3

=head1 DESCRIPTION

The RANDR extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('RANDR');

=over

=item C<($server_major, $server_minor) = $X-E<gt>RandrQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code supports up to 1.0.  The intention is to automatically
negotiate in C<init_extension> if/when necessary.

=back

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XFree86_VidModeExtension>

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
