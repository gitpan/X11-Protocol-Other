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
package X11::Protocol::Ext::XFree86_DGA;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 18;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# Version 1.0:
#   http://cvsweb.xfree86.org/cvsweb/xc/programs/Xserver/hw/xfree86/doc/man/Attic/XF86DGA.man?rev=3.10&hideattic=0&sortby=log&content-type=text/vnd.viewcvs-markup
#
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/hw/xfree86/doc/README.DGA
#
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86dga.h
#   /so/xfree/xfree86-3.3.2.3a/include/extensions/xf86dgastr.h
#
#   /usr/include/X11/extensions/xf86dga1const.h
#   /usr/include/X11/extensions/xf86dga1proto.h
#
#   /so/xf86dga/XF86DGA.man
#
#   /so/xfree/xfree86-3.3.2.3a/programs/Xserver/Xext/xf86dga.c
#       server code
#
# Version 2.0:
#   /usr/share/doc/xserver-xfree86/README.DGA.gz
#   /so/xfree4/unpacked/usr/share/doc/xserver-xfree86/README.DGA.gz
#
#   /usr/include/X11/extensions/xf86dgaconst.h
#   /usr/include/X11/extensions/xf86dgaproto.h
#
#   /so/xorg/xorg-server-1.10.0/hw/xfree86/dixmods/extmod/xf86dga2.c
#        server code
#
# Other:
#   /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz

### XFree86_DGA.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

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

# my $XF86DGA_event
#   = [ 'xCxxLsssSx16',
#       'detail',
#       'time',
#       'dx',
#       'dy',
#       'screen',
#       'state',
#     ];


#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   ['XF86DGAQueryVersion',  # 0
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      ### XF86DGAQueryVersion() reply ...
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
      return unpack 'x8L4', $data; # (address,width,bank_size,ram_size)
    },
   ],

   ['XF86DGADirectVideo',  # 2
    sub {
      my ($X, $screen, $enable) = @_;
      return pack 'SS', $screen, $enable;
    } ],

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
      shift;  # ($X, $screen, $num_pages)
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8L', $data; # (bool)
    } ],


   #---------------------------------------------------------------------------
   # version 2.0

   undef,  # 10
   undef,  # 11

   ['XDGAQueryModes',   # 12
    \&_request_screen16,
    sub {
      my ($X, $data) = @_;
      my ($num_modes) = unpack 'x8L', $data;
      my $pos = 32;

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      return map {my %h;
                  @h{qw(byte_order depth
                        num bpp
                        name_len vsync_num vsync_den flags
                        image_width image_height pixmap_width pixmap_height
                        bytes_per_scanline red_mask green_mask blue_mask
                        visual_class
                        viewport_width viewport_height viewport_xstep
                        viewport_ystep viewport_xmax viewport_ymax
                        viewport_flags
                      )}
                    = unpack 'CCSSSLLLLSSSSLLLLSxxSSSSSSL',
                      substr($data,$pos,72);
                  $pos += 72;
                  ### %h

                  my $name_len = delete $h{'name_len'};
                  $h{'name'} = unpack 'Z*', substr($data, $pos, $name_len);
                  $pos += $name_len;
                  ### $name_len
                  ### name: $h{'name'}

                  ($h{'num'}, \%h)
                } 1 .. $num_modes;
    } ],

   ['XDGASetMode',  # 13
    sub {
      shift;  # ($X, $screen, $mode, $pid)
      return pack 'L3', @_;
    },
   ],

   [ 'XDGASetViewport',  # 14
     sub {
       shift;  # ($X, $screen, $x, $y)
       return pack 'LSSL', @_;
     },
   ],

   [ 'XDGAInstallColormap', # 15
     sub {
       shift; # ($X, $screen, $colormap)
       return pack 'SxxL', @_;
     } ],

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

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XF86DGA new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  my $server_major = 1;  # as yet ...

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'XF86DGAClientNotLocal',        # 0
                            'XF86DGANoDirectVideoMode',     # 1
                            'XF86DGAScreenNotActive',       # 2
                            'XF86DGADirectNotActivated',    # 3
                            ($server_major >= 2
                             ? ('XF86DGAOperationNotSupported', # 4
                               ) : ()));

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

sub _request_empty {
  # ($X)
  ### _request_empty() ...
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    if (defined $reqs->[$i]) {
      $href->{$reqs->[$i]->[0]} = [$request_num, $i];
    }
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

The XFree86-DGA extension provides direct access to the video RAM of the
server display.  A client program running on the same machine can use this
to read or write directly instead of going through the X protocol.

Accessing video memory will require some system-dependent trickery.  Under
the Linux kernel for example video RAM is part of the F</dev/mem> physical
address space and it can be brought into program address space with an
C<mmap()>, or accessed with C<sysread()> and C<syswrite()>.  This normally
requires root permissions.

The requests offered here are only XFree86-DGA version 1.0 as yet.  They
don't say anything about the pixel layout etc in the memory, that has to be
divined separately.  (Version 2.0 has more for that.)

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $ext_available = $X->init_extension('XFree86-DGA');

=head2 XFree86-DGA 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XF86DGAQueryVersion ()>

Return the DGA protocol version implemented by the server.

=item C<$flags = $X-E<gt>XF86DGAQueryDirectVideo ($screen_num)>

Get flags describing direct video access on C<$screen_num> (integer 0
upwards).  The only flag bit is

    0x0001   direct video available

It's possible to have the extension but no direct video some screen (or all
screens even).  When not available the various requests below give errors of
type C<XF86DGANoDirectVideoMode>.

=item C<($address, $width, $bank_size_bytes, $ram_size_kbytes) = $X-E<gt>XF86DGAGetVideoLL ($screen_num)>

Return the location and size of the video memory for C<$screen_num> (integer
0 upwards).

C<$address> is a raw physical 32-bit address as an integer.  C<$width> is in
pixels.

C<$bank_size_bytes> is the size accessible at a given time, in bytes.
C<$ram_size_kbytes> is the total memory in 1024 byte blocks.  If
C<$ram_size_kbytes*1024> is bigger than C<$bank_size_bytes> then
C<$X-E<gt>XF86DGASetVidPage()> below must be used to switch among the banks.

=item C<$X-E<gt>XF86DGADirectVideo ($screen_num, $flags)>

Enable or disable direct video access on C<$screen_num> (integer 0 upwards).
C<$flags> is bits

    0x0002    enable direct video graphics
    0x0004    enable mouse pointer reporting as relative
    0x0008    enable direct keyboard event reporting

When direct video graphics is enabled (bit 0x0002) the server gives up
control to the client program.

If the graphics card doesn't have a direct video mode then an
C<XF86DGANoDirectVideoMode> error results, or if the screen is not active
(eg. switched away to a different virtual terminal) then
C<XF86DGAScreenNotActive>.

=item C<($width, $height) = $X-E<gt>XF86DGAGetViewPortSize ($screen_num)>

Get the size of the viewport on C<$screen_num> (integer 0 upwards).  This is
the part of the video memory actually visible on the monitor.  The memory
might be bigger than the monitor.

=item C<$X-E<gt>XF86DGASetViewPort ($screen_num, $x, $y)>

Set the coordinates of the top-left corner of the visible part of the video
memory on C<$screen_num> (integer 0 upwards).

This can be used when the video memory is bigger than the monitor.  It can
pan around within that bigger area, or can be used for double-buffering
displaying one part of memory while drawing to another.

=item C<$vidpage = $X-E<gt>XF86DGAGetVidPage ($screen_num)>

=item C<$X-E<gt>XF86DGASetVidPage ($screen_num, $vidpage)>

Get or set the video page (bank) on C<$screen_num> (integer 0 upwards).
C<$vidpage> is an integer 0 upwards.

This is used to access all the RAM when when the bank size is less than the
total memory size.

=item C<$vidpage = $X-E<gt>XF86DGAInstallColormap ($screen_num, $colormap)>

Set the colormap on C<$screen_num> to C<$colormap> (integer XID).

This can only be used while direct video is enabled (per
C<XF86DGADirectVideo()> above) or an error C<XF86DGAScreenNotActive> or
C<XF86DGADirectNotActivated> results.

=item C<$bool = $X-E<gt>XF86DGAViewPortChanged ($screen_num, $num_pages)>

Check whether a previous C<XF86DGASetViewPort()> on C<$screen_num> (integer
0 upwards) has completed, meaning a vertical retrace has occurred since that
viewport location was set.

This is used for double-buffering (or N-multi-buffering) to check a viewport
change has become visible.  C<$num_pages> should be 2 for double-buffering
and can be higher for multi-buffering.

=back

=head1 SEE ALSO

L<X11::Protocol>

README.DGA

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
