# Copyright 2011 Kevin Ryde


# param orders




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
package X11::Protocol::Ext::MIT_SHM;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 7;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/share/doc/x11proto-xext-dev/shm.txt.gz
#
# /usr/include/X11/extensions/shm.h
# /usr/include/X11/extensions/shmproto.h
# /usr/include/X11/extensions/shmstr.h
#
# /usr/share/doc/libxext-dev/
# /usr/include/X11/extensions/Xshm.h
#     Xlib
#

### MIT_SHM.pm loads

#------------------------------------------------------------------------------
# events

# "major_opcode", "minor_opcode" names as per GraphicsExposure and NoExpose
my $MitShmCompletion_event = [ 'xxxxLSCxLLx12',
                               'drawable',
                               'minor_opcode',
                               'major_opcode',
                               'shmseg',
                               'offset',
                             ];

#------------------------------------------------------------------------------

my $reqs =
  [
   [ 'MitShmQueryVersion',  # 0
     \&_request_empty,
     sub {
       my ($X, $data) = @_;
       my ($shared_pixmaps, $major, $minor, $uid, $gid, $pixmap_format)
         = unpack 'xCx6SSSSC', $data;
       return ($major, $minor, $uid, $gid,
               $shared_pixmaps,
               $X->interp('ImageFormat', $pixmap_format));
     }],

   [ 'MitShmAttach',  # 1
     sub {
       my ($X, $shmseg, $shmid, $readonly) = @_;
       return pack 'LLCxxx', $shmseg, $shmid, $readonly;
     } ],

   [ 'MitShmDetach',  # 2
     \&_request_card32s ],  # ($X, $shmseg)

   [ 'MitShmPutImage',  # 3
     sub {
       my $self = shift;
       my ($drawable, $gc, $depth,
           $total_width, $total_height,
           $src_x, $src_y,
           $src_width, $src_height,
           $dst_x, $dst_y,
           $format,
           $send_event,
           $shmseg, $offset) = @_;
       return pack("LLSSssSSssCCCxLL",
                   $drawable, $gc,
                   $total_width, $total_height,
                   $src_x, $src_y,
                   $src_width, $src_height,
                   $dst_x, $dst_y,
                   $depth,
                   $self->num('ImageFormat',$format),
                   $send_event,
                   $shmseg, $offset);
     }],

   [ 'MitShmGetImage',     # 4
     sub {
       my $self = shift;
       my ($drawable, $x, $y, $width, $height,
           $planemask, $format,
           $shmseg, $offset) = @_;
       $format = $self->num('ImageFormat', $format);
       return pack ('LssSSLCxxxLL',
                    $drawable, $x, $y, $width, $height,
                    $planemask, $format,
                    $shmseg, $offset);
     }, sub {
       my ($X, $data) = @_;
       ### $data
       my ($depth, $visual, $size) = unpack 'xCx6LL', $data;
       return ($depth, _interp_none($X,$visual), $size);
     } ],

   [ 'MitShmCreatePixmap',       # 5
     sub {
       my ($X, $pixmap, $drawable, $depth, $width, $height, $shmseg, $offset)
         = @_;
       return pack ('LLSSCxxxLL',
                    $pixmap, $drawable,
                    $width, $height, $depth,
                    $shmseg, $offset);
     } ],

  ];

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### MIT_SHM new()

  # Errors
  $X->{'ext_const'}->{'Error'}->[$error_num] = 'ShmSeg';
  $X->{'ext_const_num'}->{'Error'}->{'ShmSeg'} = $error_num;
  $X->{'ext_error_type'}->[$error_num] = 1; # bad resource

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'MitShmCompletion';
  $X->{'ext_events'}[$event_num] = $MitShmCompletion_event;

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

sub _request_empty {
  # ($X)
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}

sub _request_card32s {
  shift;  # ($X, $card32...)
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _interp_none {
  my ($X, $id) = @_;
  if ($X->{'do_interp'} && $id == 0) {
    return 'None';
  } else {
    return $id;
  }
}

1;
__END__

=for stopwords XID arrayrefs Ryde MIT-SHM GetImage PutImage SysV TCP localhost loopback Shm shmid shmseg shm pixmaps ImageFormat XYPixmap ZPixmap pixmap

=head1 NAME

X11::Protocol::Ext::MIT_SHM - ...

=for test_synopsis my ($X, $window, $bpp)

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('MIT-SHM')
   or print "MIT-SHM extension not available";

 use IPC::SysV;
 my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                     100000,  # bytes
                     IPC::SysV::IPC_CREAT() | 0666);

 my $shmseg = $X->new_rsrc;
 $X->MitShmAttach ($shmseg, $shmid, 0);

 my ($depth, $visual, $size) =  $X->MitShmGetImage
       ($window, 0,0, 16,16, ~0, 'ZPixmap', $shmseg, 0);
 my $image_bytes;
 shmread ($shmid, $image_bytes, 0, 16*16*$bpp) || die "$!";

 # $image_bytes is the top-left 16x16 pixels of the screen

=head1 DESCRIPTION

The MIT-SHM extension allows a client and server running on the same machine
to transfer image data through System-V shared memory segments.

The client creates a memory segment with C<shmget()> (see L<perlfunc/shmget>
and L<perlipc/"SysV IPC">) and asks the server to attach to it and then read
or write with equivalents to the core GetImage and PutImage.

The aim is to avoid sending large images through the I/O connection when on
the same machine.  Memory is faster, and may help avoid request size limits
for very big images.

Byte order, padding, etc, required or generated in images is specified by
the server C<$X-E<gt>{'image_byte_order'}>, C<$X-E<gt>{'pixmap_formats'}>,
etc, the same as for the core C<GetImage> and C<PutImage>.  It's up to the
client to adapt to the server's layout, which can be a bit of a chore.

=head2 Shm Permissions

A SysV shared memory segment has owner/group/other permission bits similar
to a file.  The server will only attach to segments which the requesting
client UID/GID has permission to read or write.

The server can usually determine a client's UID/GID for local I/O such as
Unix sockets (see L<X11::Protocol::Connection::UNIXSocket>, and
C<SO_PEERCRED> in L<socket(7)>), and perhaps TCP localhost loopback.
Failing that the server treats the client as an "other" and will only attach
to world-readable (or read-writable) segments.

If a PutImage comes from a world-readable file or is public anyway then
permissions 0644 on the memory segment will guarantee the server can read
it, no matter what UID/GID it can identify.  Remember to ask for read-only
in the C<MitShmAttach> in that case so the server doesn't demand writable
too.  But chances are if the connection is not a local transport with
identifiable UID/GID then the server is probably on a different machine
anyway and shared memory can't be used.

=head2 Shm from Perl

A shared memory segment can be created from Perl with C<shmget()> then read
or write its contents with C<shmread()> and C<shmwrite()>.  Those functions
attach and detach it each time with C<shmat()> and C<shmdt()> system calls,
which is fine for grabbing the lot, but will be a bit slow for lots of
little accesses.

C<IPC::SysV> offers a C<shmat()> to keep the block attached and C<memread()>
and C<memwrite()> to access it (see L<IPC::SysV>).  See L<IPC::SharedMem>
for an object-oriented wrapper around this too.

Incidentally, if C<shmget> is not available on the system then Perl's
C<shmget()> croaks, and it's always possible for it to return C<undef> when
not enough memory etc.  Between that, not being on the same machine, not
having identifiable perms, etc, there's a quite a few cases where a fallback
to plain I/O will be necessary.

=head1 REQUESTS

The following requests are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('MIT-SHM');

In the following C<$shmid> is the shared memory ID as obtained from the
kernel with C<shmget()>.  C<$shmseg> is an XID, allocated as usual by client
C<$X-E<gt>new_rsrc()>, on the server representing the server attachment to
the block.

=over

=item C<($server_major, $server_minor, $uid, $gid, $shared_pixmaps, $pixmap_format) = $X-E<gt>MitShmQueryVersion ()>

Return information about the MIT-SHM extension.  Unlike other extensions
there's no client version vs server version negotiation.

C<$server_major> and C<$server_minor> are the extension version number
implemented by the server.

C<$uid> and C<$gid> (integers) are the server's effective user ID and group
ID (C<geteuid()> and C<getegid()>).  Zero means root.

C<$shared_pixmaps> is non-zero if pixmaps in shared memory are supported
(see C<MitShmCreatePixmap> below).  C<$pixmap_format> (an ImageFormat) is
"XYPixmap" or "ZPixmap" for the layout required in a shared memory pixmap.

=item C<$X-E<gt>MitShmAttach ($shmseg, $shmid, $readonly)>

Attach the server to a given shared memory segment.  C<$shmseg> is a new XID
representing the attached memory.

    my $shmseg = $X->new_rsrc;
    $X->MitShmAttach ($shmseg, $shmid, 0); # read/write

C<$shmid> is the shared memory ID to attach, as obtained from C<shmget()>
(see L<perlfunc/shmget>).

C<$readonly> is 1 to have the server attach read-only, or 0 for read-write.
Read-only suffices for C<MitShmPutImage>, or read-write is needed for
C<MitShmGetImage> and C<MitShmCreatePixmap>.

=item C<$X-E<gt>MitShmDetach ($shmseg)>

Detach the server from shared memory C<$shmseg> (an XID) and release that
XID.

    $X->MitShmDetach ($shmseg);

=item C<$X-E<gt>MitShmPutImage ($drawable, $gc, $depth, $total_width, $total_height, $src_x, $src_y, $src_width, $src_height, $dst_x, $dst_y, $format, $send_event, $shmseg, $offset)>

Draw an image from C<$shmseg> (an XID) into C<$drawable>.  The parameters
are similar to the core C<PutImage>.

C<$depth> is the depth of the image.  For C<$format> "Bitmap" it must be 1
and the foreground and background colours of C<$gc> are then drawn.  For
C<$format> "XYPixmap" and "ZPixmap" it must be the depth of C<$drawable>.

C<$total_width>,C<$total_height> is the full size of the image in the shared
memory.  C<$src_x>,C<$src_y> and C<$src_width>,C<$src_height> are the
portion of it to draw.  C<$dst_x>,C<$dst_y> is where in C<$drawable> to put
it.

C<$format> is "Bitmap", "XYPixmap" or "ZPixmap" (an ImageFormat).

C<$send_event> is 1 to have an C<MitShmCompletionEvent> sent to the client
when drawing is finished (see L</"EVENTS"> below), or 0 if that's not
wanted.

C<$offset> is a byte offset into the shared memory where the image starts.

=item C<($depth, $visual, $size) = $X-E<gt>MitShmGetImage ($drawable, $x, $y, $width, $height, $planemask, $format, $shmseg, $offset)>

Copy an image from C<$drawable> to shared memory C<$shmseg> (an XID).  The
parameters are similar to the core C<GetImage>.

C<$x>,C<$y>, C<$width>,C<$height> are the part of C<$drawable> to get.
C<$planemask> is a bit mask for which bit planes of the pixels are wanted.

C<$format> is "XYPixmap" or "ZPixmap" for the layout to be written to the
shared memory, and C<$offset> is a byte offset into the memory where the
image should start.

The returned C<$depth> (an integer) is the depth of C<$drawable>.
C<$visual> (integer ID) is its visual for a window, or "None" for a pixmap.
C<$size> is how many bytes were written.

C<$shmseg> must be attached read-write in C<MitShmAttach> or an Access error
results.

=item C<$X-E<gt>MitShmCreatePixmap ($pixmap, $drawable, $depth, $width, $height, $shmseg, $offset)>

Create C<$pixmap> (a new XID) as a pixmap with contents in shared memory
C<$shmseg> (an XID).  When the client reads or writes that memory it changes
the pixmap contents.  The parameters are similar to the core
C<CreatePixmap>.

    my $pixmap = $X->new_rsrc;
    $X->MitShmCreatePixmap ($pixmap,         # new XID
                            $X->root,        # for the screen
                            $X->root_depth,  # depth
                            10,10,           # width,height
                            $shmseg,
                            0);      # byte offset into shm

C<MitShmQueryVersion> above reports whether shared memory pixmaps are
supported, and if so whether they're "XYPixmap" or "ZPixmap" layout.

C<$drawable> is used to determine the screen for C<$pixmap> and can be any
drawable on the screen.  C<$offset> is a byte offset into the shared memory
where the pixmap data will begin.

If any damage objects from the DAMAGE extension (see
L<X11::Protocol::Ext::DAMAGE>) monitoring the shared C<$pixmap> then changes
made through the shared memory generally don't produce C<DamageNotify>
events from those objects.  Listening for damage on a shared pixmap might be
unlikely, but explicit C<DamageAdd> (in Damage version 1.1) requests can
tell the server about changes, when ready, and if necessary.

=back

=head1 EVENTS

C<MitShmCompletionEvent> is sent to the client when requested in an
C<MitShmPutImage>, to say memory access for the put is finished.  The event
has the usual fields

    name             "MitShmCompletionEvent"
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

and event-specific fields

    drawable       XID, target as from request
    shmseg         XID, source as from request
    offset         integer, byte offset as from request
    major_opcode   integer, MIT-SHM extension start
    minor_opcode   integer, 3==MitShmPutImage

C<major_opcode> and C<minor_opcode> are the codes of the originating
C<MitShmPutImage>.  They're similar to the core C<GraphicsExposure> and
C<NoExposure> events, though here there's only one request
(C<MitShmPutImage>) which gives a completion event so they're hardly needed.

=head1 ERRORS

Error type "ShmSeg" is a bad C<$shmseg> resource XID in a request.

=head1 SEE ALSO

L<X11::Protocol>,
L<perlfunc/shmget>,
L<perlipc/"SysV IPC">),
L<IPC::SysV>,
L<IPC::SharedMem>

L<X11::Protocol::Ext::Damage>

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


# =head2 Multi-CPU Synchronization
# 
# Some older multi-CPU or multi-core systems had bizarre rules for explicit
# synchronization when sharing memory between different CPUs or cores.  Not
# certain if a shm client must do anything special.  Presumably the C<shmdt>
# system call in Perl's C<shmread>/C<shmwrite> would take care of any cache
# sync demanded in that case at least.
