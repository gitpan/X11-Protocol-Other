# id values as numbers ?
# struct forms ?


# Copyright 2012 Kevin Ryde

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
package X11::Protocol::Ext::XVideo;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 16;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/share/doc/x11proto-video-dev/xv-protocol-v2.txt.gz
# /usr/include/X11/extensions/Xvproto.h
#
# http://cgit.freedesktop.org/xcb/proto/tree/src/xv.xml
#     xcb
#
# /so/xorg/xorg-server-1.10.0/Xext/xvdisp.c
#     server source
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;


#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     XVideoNotifyReason => ['Started',   # 0
                            'Stopped',   # 1
                            'Busy',      # 2
                            'Preempted', # 3
                            'HardError', # 4
                           ],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# events

my $XVideoNotify_event
  = [ 'xCxxLLLx16',
      ['reason','XVideoNotifyReason'],
      'time',
      'drawable'
      'port',
    ];
my $XVideoPortNotify_event
  = [ 'xxxxLLLlx12',
      'time',
      'port',
      'attribute', # atom
      'value',     # INT32
    ];

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['XVideoQueryExtension',  # 0
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;
    }],

   ['XVideoQueryAdaptors',  # 1
    \&_request_card32s,  # ($X, $window)
    sub {
      my ($X, $data) = @_;
      ### XVideoQueryAdaptors() reply ...

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      my ($num_adaptors) = unpack 'x8S', $data;
      ### $num_adaptors

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_adaptors) {
        ### $pos
        my ($port_base, $name_len, $num_ports, $num_formats, $type)
          = unpack 'LSSSC', substr($data,$pos,12);
        $pos += 12;

        my $name = substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);

        my @formats;
        foreach (1 .. $num_formats) {
          my %h;
          @h{'visual','depth'} = unpack 'LC', substr($data,$pos,8);
          push @formats, \%h;
          $pos += 8;
        }

        push @ret, { port_base => $port_base,
                     name      => $name,
                     num_ports => $num_ports,
                     formats   => \@formats,
                     type      => $type };
      }
      return @ret;
    } ],

   ['XVideoQueryEncodings',  # 2
    \&_request_card32s,  # ($X, $port)
    sub {
      my ($X, $data) = @_;
      ### XVideoQueryEncodings() reply length: length($data)

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      my ($num_encodings) = unpack 'x8S', $data;
      ### $num_encodings

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_encodings) {
        ### $pos
        my ($encoding, $name_len,
            $width,$height,
            $rate_numerator,$rate_denominator)
          = unpack 'LSSSxxLL', substr($data,$pos,20);
        $pos += 20;

        my $name = substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);

        push @ret, { encoding         => $encoding,
                     name             => $name,
                     width            => $width,
                     height           => $height,
                     rate_numerator   => $rate_numerator,
                     rate_denominator => $rate_denominator,
                   };
      }
      return @ret;
    }],

   ['XVideoGrabPort',  # 3
    sub {
      my ($X, $port, $time) = @_;
      return pack 'LL', $port, _num_time($time);
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'xC', $data; # ($status)
    }],

   ['XVideoUngrabPort',  # 4
    sub {
      my ($X, $port, $time) = @_;
      return pack 'LL', $port, _num_time($time);
    } ],

   do {
     my $put = sub {
       shift;
       # ($X, $port, $drawable, $gc,
       #  $vid_x,$vid_y,$vid_w,$vid_h,
       #  $drw_x,$drw_y,$drw_w,$drw_h)
       return pack 'LLLssSSssSS', @_;
     };

     (
      ['XVideoPutVideo',  # 5
       $put ],

      ['XVideoPutStill',  # 6
       $put ],

      ['XVideoGetVideo',  # 7
       $put ],

      ['XVideoGetStill',  # 8
       $put ],
     )
   },

   ['XVideoStopVideo',  # 9
    \&_request_card32s ],

   do {
     my $select = sub {
       shift; # ($X, $drawable, $onoff)
       return pack 'LCxxx', @_;
     };

     (
      ['XVideoSelectVideoNotify',  # 10
       $select ],

      ['XVideoSelectPortNotify',  # 11
       $select ],
     )
   },

   ['XVideoQueryBestSize',  # 12
    sub {
      shift; # ($X, $port, $vid_w,$vid_h, $drw_w,$drw_h, $motion)
      return pack 'LSSSSCxxx', @_;
    } ],

   ['XVideoSetPortAttribute',  # 13
    sub {
      shift; # ($X, $port, $atom, $value)
      return pack 'LLl', @_;
    } ],

   ['XVideoGetPortAttribute',  # 14
    sub {
      shift; # ($X, $port, $atom)
      return pack 'Ll', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data;
    }],

   ['XVideoQueryPortAttributes',  # 15
    \&_request_card32s,
    sub {
      my ($X, $data) = @_;
      my ($num_attributes, $text_len) = unpack 'x8LL', $data;

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_attributes) {
        my %h;
        (@h{'flags','min','max'}, my $name_len)
          = unpack 'LllL', substr($data,$pos,16);
        $pos += 16;

        $h{'name'} = unpack 'Z*', substr($data,$pos,$name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);

        push @ret, \%h;
      }
      return @ret;
    }],

   ['XVideoListImageFormats',  # 16
    \&_request_card32s,
    sub {
      my ($X, $data) = @_;
      my ($num_attributes, $text_len) = unpack 'x8LL', $data;

      use Data::HexDump::XXD;
      print scalar(Data::HexDump::XXD::xxd($data));
      print "\n";

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_attributes) {
        my %h;
        @h{ # hash slice
          qw(id
             type
             byte_order
             guid
             bpp
             num_planes

             depth

             red_mask
             green_mask
             blue_mask
             format

             y_sample_bits
             u_sample_bits
             v_sample_bits
             horz_y_period
             horz_u_period
             horz_v_period
             vert_y_period
             vert_u_period
             vert_v_period

             comp_order
             scanline_order
           )} = unpack 'LCCxxZ16CCxxCxxxLLLCxxxL9Z32C', substr($data,$pos,128);
        $pos += 128;

        push @ret, \%h;
      }
      return @ret;
    }],

   ['XVideoQueryImageAttributes',  # 17
    sub {
      shift; # ($X, $port, $image_id, $width, $height)
      return pack 'LLSS', @_;
    },
    sub {
      my ($X, $data) = @_;
      my ($num_planes, $data_size, $width, $height) = unpack 'x8LLSS', $data;
      return ($data_size, $width, $height,
              unpack "L$num_planes", substr($data,32));
    }],

   ['XVideoPutImage',  # 18
    sub {
      shift;
      # ($X, $port, $drawable, $gc, $id,
      #  $src_x,$src_y,$src_w,$src_h,
      #  $drw_x,$drw_y,$drw_w,$drw_h,
      #  $width,$height)
      return pack 'LLLLssSSssSSSS', @_;
    } ],

   # FIXME: args cf ShmPutImage ?
   ['XVideoShmPutImage',  # 19
    sub {
      shift;
      # ($X, $port, $drawable, $gc, $shmseg, $id, $offset
      #  $src_x,$src_y,$src_w,$src_h,
      #  $drw_x,$drw_y,$drw_w,$drw_h,
      #  $width,$height, $send_event)
      return pack 'LLLLLLssSSssSSSS', @_;
    } ],
  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XVideo new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'XVideoPort',     # 0
                            'XVideoEncoding', # 1

                            # FIXME: this one in new enough protocol ?
                            'XVideoControl',  # 2
                           );

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'XVideoNotify';
  $X->{'ext_events'}[$event_num] = $XVideoNotify_event;
  $event_num++;
  $X->{'ext_const'}{'Events'}[$event_num] = 'XVideoPortNotify';
  $X->{'ext_events'}[$event_num] = $XVideoPortNotify_event;

  return bless { }, $class;
}

#------------------------------------------------------------------------------
# generic

sub _request_empty {
  # ($X)
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
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

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XVideo - video modes

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

=item C<($server_major, $server_minor) = $X-E<gt>XVideoQueryVersion ()>

Return the DGA protocol version implemented by the server.

=item C<($dotclock, $modeline) = $X-E<gt>XVideoGetModeLine ($screen_num)>

Get the current mode of C<$screen_num> (integer 0 upwards).  The return is a
list of key/value pairs,

    dotclock   => integer
    hdisplay   => integer, horizontal visible pixels
    hsyncstart => integer, horizontal sync start
    hsyncend   => integer, horizontal sync end
    htotal     => integer, horizontal total pixels
    hskew      => integer
    vdisplay   => integer, vertical visible pixels
    vsyncstart => integer, vertical sync start
    vsyncend   => integer, vertical sync end
    vtotal     => integer, vertical total pixels
    flags      => integer

=item C<@fields = $X-E<gt>XVideoSwitchMode ($screen_num, $zoom)>

Switch to the next or previous mode on C<$screen_num> (integer 0 upwards).
If C<$zoom> is 1 (or more) to switch to the next mode, or 0 to switch to the
previous mode.

=item C<$X-E<gt>XVideoLockModeSwitch ($screen_num, $lock)>

Lock or unlock mode switching on C<$screen_num> (integer 0 upwards).  If
C<$lock> is non-zero then mode switching via either the keyboard or the
C<XVideoSwitchMode()> request is prevented.  If C<$lock> is zero
switching is allowed again.

=item C<$X-E<gt>XVideoGetAllModeLines ($screen_num)>



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
