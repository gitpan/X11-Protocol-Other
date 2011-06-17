# Copyright 2010, 2011 Kevin Ryde

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
package X11::Protocol::XSetRoot;
use strict;
use Carp;
use X11::AtomConstants;
use X11::Protocol::Other 3;  # v.3 for hexstr_to_rgb()

use vars '$VERSION';
$VERSION = 10;

# uncomment this to run the ### lines
#use Smart::Comments;

# _XSETROOT_ID the same as xsetroot and other rootwin programs do
sub set_background {
  my ($class, %option) = @_;
  ### XSetRoot set_background(): do { my %o = %option; delete $o{'X'}; %o }

  my $display;
  my $X = $option{'X'};
  if (! $X) {
    $display = $option{'display'};
    ### display: $display
    require X11::Protocol;
    $X = X11::Protocol->new (defined $display ? ($display) : ());
    $display ||= '';  # so not undef
  }
  ### X: "$X"

  my $screen_info;
  my $root = $option{'root'};
  if (! defined $root) {
    if (defined (my $screen_number = $option{'screen'})) {
      $screen_info = $X->{'screens'}->[$screen_number];
      $root = $screen_info->{'root'};
    } else {
      $root = $X->{'root'};
    }
  }
  ### $root
  my $allocated;

  my @change;
  my $pixmap;
  if (defined ($pixmap = $option{'pixmap'})) {
    ### $pixmap
    $pixmap = _num_none($pixmap);
    @change = (background_pixmap => $pixmap);
    $allocated = $option{'pixmap_allocated_colors'};

  } else {
    $screen_info ||= X11::Protocol::Other::root_to_screen_info($X,$root);
    my $pixel;
    if (defined ($pixel = $option{'pixel'})) {
      ### pixel: $pixel

    } elsif (defined (my $color = $option{'color'})) {
      ($pixel) = _alloc_named_or_hex_color($X,
                                           $screen_info->{'default_colormap'},
                                           $color);
      $option{'X'} = 1;
    } else {
      croak "No color, pixel or pixmap for background";
    }
    @change = (background_pixel => $pixel);

    $allocated = ($pixel != $screen_info->{'black_pixel'}
                  && $pixel != $screen_info->{'black_pixel'});
  }
  ### $root
  ### @change

  if ($allocated) {
    if (X11::Protocol::Other::visual_is_dynamic
        ($X, X11::Protocol::Other::window_visual($X,$root))) {
      unless ($option{'X'}) {
        croak 'Need X connection to set background from allocated pixel or pixmap';
      }
    } else {
      $allocated = 0;
    }
  }

  # atomic replacement of _XSETROOT_ID
  require X11::Protocol::GrabServer;
  my $grab = X11::Protocol::GrabServer->new ($X);

  _kill_current ($class, $X, $root);

  $X->ChangeWindowAttributes ($root, @change);
  if ($pixmap) { # and also don't free $pixmap==0 "None"
    ### FreePixmap: $pixmap
    $X->FreePixmap($pixmap);
  }
  $X->ClearArea ($root, 0,0,0,0);

  if ($allocated) {
    my $id_pixmap = $X->new_rsrc;
    ### save id_pixmap: sprintf('%#X', $id_pixmap)
    $X->CreatePixmap ($id_pixmap,
                      $root,
                      1,      # depth
                      1,1);  # width,height
    $X->ChangeProperty($root,
                       $X->atom('_XSETROOT_ID'),
                       X11::AtomConstants::PIXMAP,
                       32,  # format
                       'Replace',
                       pack ('L', $id_pixmap));
    $X->SetCloseDownMode('RetainPermanent');
  }

  # check for errors with a QueryPointer round trip, either if allocated
  # because the application will do nothing more, or if $display opened here
  if ($allocated || defined $display) {
    ### sync with QueryPointer
    $X->QueryPointer($root);
  }
}

# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X)>
#
# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X, $root)>
#
# Kill any existing C<_XSETROOT_ID> on the given C<$root> XID.  If
# C<$root> is C<undef> or omitted then the C<$X> default root is used.
#
# This is normally only wanted when replacing C<_XSETROOT_ID> in the way
# C<set_background> above does.
#
sub _kill_current {
  my ($class, $X, $root) = @_;
  ### XSetRoot kill_current()
  $root ||= $X->{'root'};

  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty($root,
                      $X->atom('_XSETROOT_ID'),
                      0,  # AnyPropertyType
                      0,  # offset
                      1,  # length
                      1); # delete
  if ($type == X11::AtomConstants::PIXMAP && $format == 32) {
    my $xid = unpack 'L', $value;
    ### $value
    ### kill id_pixmap: sprintf('%#X', $xid)
    if ($xid) { # watch out for $xid==0 for none maybe
      $X->KillClient($xid);
    }
  }
}

sub _alloc_named_or_hex_color {
  my ($X, $colormap, $str) = @_;
  {
    my @exact;
    if (@exact = X11::Protocol::Other::hexstr_to_rgb($str)) {
      my ($pixel, @actual) = $X->AllocColor($colormap, @exact);
      return ($pixel, @exact, @actual);
    }
  }
  return $X->AllocNamedColor($colormap, $str);
}

# or maybe $X->num('IDorNone',$xid)
sub _num_none {
  my ($xid) = @_;
  if ($xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}

1;
__END__

=for stopwords Ryde pixmap colormap RetainPermanent pre-defined lookup XID Pixmap

=head1 NAME

X11::Protocol::XSetRoot -- set root window background

=for test_synopsis my ($X, $pixmap_xid)

=head1 SYNOPSIS

 use X11::Protocol::XSetRoot;
 X11::Protocol::XSetRoot->set_background (color => 'green');

 # or given $X, which then can't be used any more
 X11::Protocol::XSetRoot->set_background
                            (X       => $X,
                             pixmap  => $pixmap_xid,
                             pixmap_allocated_colors => 1);

=head1 DESCRIPTION

This module sets the X root window background in the style of the
C<xsetroot> program.

The simplest use is a named colour, or a 1 to 4 digit hex string like
"#RRGGBB" or "#RRRRGGGGBBBB".  Named colours are per the server's usual
C<AllocNamedColor> etc.

    X11::Protocol::XSetRoot->set_background
                               (color => 'green');

    X11::Protocol::XSetRoot->set_background
                               (color => '#FF0000'); # red

A pattern can be set with a pixmap or a big pixmap the size of the whole
screen.

    # draw $pixmap with black_pixel and white_pixel ...
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap);

C<set_background> takes over ownership of the given C<$pixmap> and frees it
with C<FreePixmap> once put into the window background.  Setting an
application drawn pixmap is the main use for this module.  A solid colour
can be simply by running the actual C<xsetroot> program.

=head2 Allocated Pixels

If the pixmap has pixels allocated with C<AllocColor> etc then this should
be indicated with the C<pixmap_allocated_colors> option,

    # draw $pixmap with AllocColor colours
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap,
                                pixmap_allocated_colors => 1);
    # don't use $X any more

The way allocated colour retention works means the C<$X> connection cannot
be used any more in this case, or if the C<color> or C<pixel> options are an
allocated colour (anything except the X root colormap C<black_pixel> and
C<white_pixel>).

Allocated colours are preserved in the root colormap using
C<SetCloseDownMode> C<RetainPermanent> and a client XID recorded in the
C<_XSETROOT_ID> property on the root window.  A subsequent C<xsetroot> or
compatible program does a C<KillClient> to free the pixels.  This can happen
any time after setting, perhaps immediately.

If the root visual is static such as C<TrueColor> then an C<AllocColor> is
just a lookup, not an actual allocation.  On a static visual
C<set_background> skips the RetainPermanent and C<_XSETROOT_ID>.

The easiest thing is to close an C<$X> connection immediately after a
C<set_background>.  Perhaps there could be a return value to say whether a
retain was done and the connection cannot be used again.  Or if in the
future there's an explicit C<$X-E<gt>close> of some sort then that could be
used here, and would indicate whether the connection is still good.

=head1 FUNCTIONS

=over 4

=item C<X11::Protocol::XSetRoot-E<gt>set_background (key=E<gt>value, ...)>

Set the root window background to a pixmap or a pixel.  The key/value
parameters are

    X        => X11::Protocol object
    display  => string ":0:0" etc

    screen   => integer, eg. 0
    root     => XID of root window

    color    => string
    pixel    => integer pixel value
    pixmap   => XID of pixmap to display
    pixmap_allocated_colors => boolean, default false

The server is given by an C<X> connection object , or a C<display> name to
connect to, otherwise the C<DISPLAY> environment variable.

The root window is given by C<root> or C<screen>, or otherwise the current
"chosen" screen on C<$X>, or the screen part of the C<display> name.

The background to show is given by a colour name or pixel, or a pixmap.
C<color> can be anything understood by the server C<AllocNamedColor>, plus 1
to 4 digit hex like "#RGB" or "#RRRRGGGGBBBB".

C<pixel> is an integer pixel value in the root window colormap.  It's
automatically recognised as allocated or not -- anything except the screen
pre-defined black or white pixel value is allocated.

C<pixmap> is an XID integer.  C<set_background> takes ownership of this
pixmap and will C<FreePixmap> once installed.  "None" or 0 means no pixmap,
which gives the server's default root background (usually a black and white
weave pattern).

C<pixmap_allocated_colors> should be true if any of the pixels in C<pixmap>
were allocated with C<AllocColor> etc, as opposed to just the screen
pre-defined black and white pixels.

When an allocated pixel or a pixmap with allocated pixels is set as the
background the C<_XSETROOT_ID> mechanism described above means the C<$X>
connection could be killed by another C<xsetroot> at any time, so should not
be used any more.  The easiest thing is to make C<set_background> the last
thing done on C<$X>.

Setting a C<pixel> or C<pixmap> can only be done on an C<X> connection as
such, not from the C<display> option.  This is because retaining the colours
with the C<_XSETROOT_ID> mechanism can only be done from the client
connection which created them, not a new connection.

=back

=head1 FILES

F</etc/X11/rgb.txt> on the server, the usual colour names database for the
C<color> option here.

=head1 SEE ALSO

L<xsetroot(1)>

=head1 HOME PAGE

http://user42.tuxfamily.org/x11-protocol-other/index.html

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

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
