# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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


# Window Manager Notes:
#
# ctwm does it's workspaces by moving windows or unmapping or something.
# There's no virtual root but it does draw the root window to a
# per-workspace colour on each change which overwrites anything put there in
# xsetroot style.
#
# evilwm desktop workspaces done by hiding/mapping windows.
#
# tvtwm comes with an ssetroot which looks at __SWM_VROOT.
#
# awesome does desktops by hiding/mapping and a task bar across the top.


# Maybe:
# X11::Protocol::XSetRoot->kill_current($X,$root)
# X11::Protocol::XSetRoot->kill_current(X=>$X,root=>$root)


# Maybe read /usr/include/X11/bitmaps/gray like xsetroot -grey.
# Or /usr/include/X11/bitmaps/root_weave which is the server default.
# Those files are bitmaps so foreground,background colours.
#
# bitmap_filename => '/blah...'
# bitmap_usr_include => 'gray'
# bitmap_include => 'gray'
# bitmap_type => 'gray','root_weave','default' builtins
# mod => x,y
# reverse_colors
# color => 
# background =>
# bitmap_foreground => 
# bitmap_background =>
#
#
# root=>
# virtual_root=> no look at root SWM_VROOT
#




BEGIN { require 5 }
package X11::Protocol::XSetRoot;
use strict;
use Carp;
use X11::AtomConstants;
use X11::Protocol::Other;
use X11::Protocol::WM;

use vars '$VERSION';
$VERSION = 27;

# uncomment this to run the ### lines
# use Smart::Comments;


# _XSETROOT_ID the same as xsetroot and other rootwin programs do.

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

  my $root = $option{'root'};
  my $screen_number = $option{'screen'};

  if (! defined $root) {
    if (defined $screen_number) {
      $root = $X->{'screens'}->[$screen_number]->{'root'};
    } else {
      $root = $X->{'root'};
    }
  }
  if (! defined $screen_number) {
    $screen_number = X11::Protocol::Other::root_to_screen($X,$root);

    # Secret undocumented allowance for root=>$xid being something not an
    # actual root window.  Maybe a window_to_screen() checking among the
    # roots and then QueryTree.
    #
    if (! defined $screen_number) {
      my ($actual_root) = $X->QueryTree ($root);
      $screen_number = X11::Protocol::Other::root_to_screen($X,$actual_root);
    }
  }
  ### $root

  my $visual = X11::Protocol::Other::window_visual($X,$root);
  my $visual_is_dynamic = X11::Protocol::Other::visual_is_dynamic($X,$visual);
  my $allocated;

  my @window_attributes;
  my $pixmap;
  if (defined ($pixmap = $option{'pixmap'})) {
    ### $pixmap
    $pixmap = _num_none($pixmap);
    @window_attributes = (background_pixmap => $pixmap);
    $allocated = $option{'pixmap_allocated_colors'};

  } else {
    my $screen_info = $X->{'screens'}->[$screen_number];
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
    @window_attributes = (background_pixel => $pixel);

    $allocated = $visual_is_dynamic
      && ! ($pixel == $screen_info->{'black_pixel'}
            || $pixel == $screen_info->{'white_pixel'}
            || _tog_cup_pixel_is_reserved($X,$screen_number,$pixel));
  }
  ### @window_attributes

  if ($allocated) {
    if ($visual_is_dynamic) {
      unless ($option{'X'}) {
        croak 'Need X connection to set background from allocated pixel or pixmap';
      }
    } else {
      $allocated = 0;
    }
  }

  # follow any __SWM_VROOT
  $root = (X11::Protocol::WM::root_to_virtual_root($X,$root) || $root);

  # GrabServer() so atomic get/set of _XSETROOT_ID.

  # After GetProperty() delete and kill of the old _XSETROOT_ID don't want
  # another client to be able to slip in a new value which ChangeProperty()
  # here would overwrite (and so leak resources).
  #
  # The QueryPointer() is under the grab too so that no-one else can
  # KillClient() on our new _XSETROOT_ID, not until after QueryPointer().
  #
  require X11::Protocol::GrabServer;
  my $grab = X11::Protocol::GrabServer->new ($X);

  _kill_current ($class, $X, $root);

  $X->ChangeWindowAttributes ($root, @window_attributes);
  if ($pixmap) { # and also don't free $pixmap==0 "None"
    ### FreePixmap: $pixmap
    $X->FreePixmap($pixmap);
  }
  $X->ClearArea ($root, 0,0,0,0); # whole window

  if ($allocated) {
    my $id_pixmap = $X->new_rsrc;
    ### save id_pixmap: sprintf('%#X', $id_pixmap)
    $X->CreatePixmap ($id_pixmap,
                      $root,
                      1,      # depth
                      1,1);  # width,height
    $X->ChangeProperty($root,
                       $X->atom('_XSETROOT_ID'),
                       X11::AtomConstants::PIXMAP(),
                       32,  # format
                       'Replace',
                       pack ('L', $id_pixmap));
    $X->SetCloseDownMode('RetainPermanent');
  }

  # Check for errors with a QueryPointer round trip, either if allocated
  # because the application will do nothing more, or if $display opened here.
  if ($allocated || defined $display) {
    ### sync with QueryPointer
    $X->QueryPointer($root);
  }
}

sub _tog_cup_pixel_is_reserved {
  my ($X, $screen_number, $pixel) = @_;
  ### _tog_cup_pixel_is_reserved(): $pixel

  if ($X->{'ext'}->{'TOG_CUP'}
      || $X->init_extension('TOG-CUP')) {
    my $c;
    foreach $c ($X->CupGetReservedColormapEntries($screen_number)) {
      if ($c->[0] == $pixel) {
        return 1;
      }
    }
  }
  return 0;
}


# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X)>
#
# =item C<X11::Protocol::XSetRoot-E<gt>kill_current ($X, $root)>
#
# Kill any existing C<_XSETROOT_ID> on the given C<$root> XID.  If C<$root>
# is C<undef> or omitted then the C<$X-E<gt>root> default is used.
#
# This is normally only used when changing or replacing the background in
# the way C<set_background()> above does.
#
sub _kill_current {
  my ($class, $X, $root) = @_;
  ### XSetRoot kill_current()
  $root ||= $X->{'root'};

  # Delete and kill _XSETROOT_ID.
  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty($root,
                        $X->atom('_XSETROOT_ID'),
                        0,  # AnyPropertyType
                        0,  # offset
                        1,  # length
                        1); # delete
    if ($type == X11::AtomConstants::PIXMAP() && $format == 32) {
      my $xid = unpack 'L', $value;
      ### $value
      ### kill id_pixmap: sprintf('%#X', $xid)

      # For safety check $xid!=0, since KillClient(0) would mean kill all
      # temporary clients (ie. all normal clients).
      if ($xid) {
        $X->KillClient($xid);
      }
    }
  }

  # Delete _XROOTPMAP_ID.
  #
  # Do this before KillClient so that _XROOTPMAP_ID is not left momentarily
  # as a non-existent XID.  Though anyone using _XROOTPMAP_ID must be
  # prepared for the XID to be destroyed at any time since it belongs to
  # another client.
  #
  $X->DeleteProperty($root, $X->atom('_XROOTPMAP_ID'));

  # Delete and kill ESETROOT_PMAP_ID.
  #
  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty($root,
                        $X->atom('ESETROOT_PMAP_ID'),
                        0,  # AnyPropertyType
                        0,  # offset
                        1,  # length
                        1); # delete
    if ($type == X11::AtomConstants::PIXMAP() && $format == 32) {
      my $xid = unpack 'L', $value;
      # For safety check $xid!=0, since KillClient(0) would mean kill all
      # temporary clients (ie. all normal clients).
      if ($xid) {
        $X->KillClient($xid);
      }
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

=for stopwords Ryde pixmap colormap RetainPermanent pre-defined lookup XID Pixmap XSetRoot recognised Esetroot

=head1 NAME

X11::Protocol::XSetRoot -- set root window background

=for test_synopsis my ($X, $pixmap_xid)

=head1 SYNOPSIS

 use X11::Protocol::XSetRoot;
 X11::Protocol::XSetRoot->set_background (color => 'green');

 # or given $X, but which then can't be used any more
 X11::Protocol::XSetRoot->set_background
                  (X       => $X,
                   pixmap  => $pixmap_xid,
                   pixmap_allocated_colors => 1);

=head1 DESCRIPTION

This module sets the X root window background in the style of the
C<xsetroot> program.

The simplest use is a named colour or 1 to 4 digit hex string like "#RRGGBB"
or "#RRRRGGGGBBBB".  Named colours are interpreted by the server's usual
C<AllocNamedColor()>.

    X11::Protocol::XSetRoot->set_background
                               (color => 'green');

    X11::Protocol::XSetRoot->set_background
                               (color => '#FF0000'); # red

A pattern can be set with a pixmap.  A complete background picture can be
set with a pixmap the size of the whole screen.

    # draw $pixmap with $X->black_pixel and $X->white_pixel,
    # then set it with
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap);

C<set_background()> takes ownership of the given C<$pixmap> and frees it
with C<FreePixmap()> once put into the window background.

Setting a pixmap drawn by an application is the main use for this module.
If you just want a solid colour then that can be done easily enough by
running the actual C<xsetroot> program.

=head2 Allocated Pixels

If a pixmap has pixels allocated with C<AllocColor()> etc then this should
be indicated with the C<pixmap_allocated_colors> option,

    # AllocColor colours, draw $pixmap with them, then
    #
    X11::Protocol::XSetRoot->set_background
                               (X      => $X,
                                pixmap => $pixmap,
                                pixmap_allocated_colors => 1);
    # don't use $X any more

The way colour retention is done means that the C<$X> connection cannot be
used any more in this case.  Likewise if the C<color> or C<pixel> options
are an allocated colour.

The easiest thing is to close an C<$X> connection immediately after a
C<set_background()>.  Perhaps there could be a return value to say whether a
retain was done and the connection cannot be used again.  Or perhaps if in
the future there's an explicit C<$X-E<gt>close> then that could be done here
and a closed connection would indicate it cannot be used.

Allocated colours in the root colormap are preserved using
C<SetCloseDownMode('RetainPermanent')> and a client XID in the
C<_XSETROOT_ID> property on the root window.  A subsequent C<xsetroot> or
compatible program does a C<KillClient()> on that XID to free the pixels.
Such a kill could happen any time after that property is set, perhaps
immediately.

For a static visual such as C<TrueColor> there's no colour allocation
(C<AllocColor()> is just a lookup) and in that case C<set_background()>
knows there's no need for C<RetainPermanent>.

Also, if the C<color> or C<pixel> options are the screen C<black_pixel> or
C<white_pixel> then there's no C<RetainPermanent> since those pixels are
permanent in the root colormap.  If the server has the TOG-CUP extension
(see L<X11::Protocol::Ext::TOG_CUP>) then the reserved pixels it lists are
treated similarly.

=head1 Virtual Root

C<XSetRoot> looks for C<__SWM_VROOT> using C<root_to_virtual_root()> from
C<X11::Protocol::WM> and acts on that when applicable.  Such a virtual root
is used by C<amiwm>, C<swm> and C<tvtwm> window managers and the
C<xscreensaver> program.

The enlightenment window manager uses a background window covering the root
window.  This stops most root window programs from working, including
XSetRoot here.

=head1 Esetroot

The C<Esetroot> program and various compatible programs such as C<fvwm-root>
put their pixmap in properties C<_XROOTPMAP_ID> and C<ESETROOT_PMAP_ID>.
These are deleted by C<set_background()> since any pixmap there will no
longer be the root pixmap.

C<set_background()> does a C<KillClient()> on the C<ESETROOT_PMAP_ID>.
C<Esetroot> uses C<RetainPermanent> to preserve the root pixmap and leaves
C<ESETROOT_PMAP_ID> ready to be killed to free that pixmap when replaced.

This C<_XROOTPMAP_ID> style allows client programs to read the root window
background to copy and manipulate for pseudo-transparency or other purposes.
There's nothing yet for C<set_background()> to store a pixmap this way.

=cut

# The C<xsetroot> method destroys the new root pixmap which in principle
# allows the server to apply it to the hardware in some way and never refer to
# it again.  In practice that might not occur, and the C<Esetroot> way has the
# advantage of letting clients fetch the root background.  In the future there
# could be an option for C<set_background()> here to use the C<Esetroot> style
# for pixmaps.  (For compatibility the C<xsetroot> style would have to be
# default.)

=pod

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
    pixmap   => XID of pixmap to display, or "None"
    pixmap_allocated_colors => boolean, default false

The server is given by an C<X> connection object, or a C<display> name to
connect to, or the default is the C<DISPLAY> environment variable.

The root window is given by C<root> or C<screen>, or the default is the
default screen in C<$X> either as set by C<$X-E<gt>choose_screen()> or from
the display name.

The background to show is given by a colour name, pixel value, or pixmap.
C<color> can be anything understood by the server C<AllocNamedColor()>, plus
1 to 4 digit hex

    blue              named colours
    #RGB              hex digits
    #RRGGBB
    #RRRGGGBBB
    #RRRRGGGGBBBB

C<pixel> is an integer pixel value in the root window colormap.  It's
automatically recognised as allocated or not (the screen pre-defined black
or white and TOG-CUP reserved pixels).

C<pixmap> is an XID integer.  C<set_background()> takes ownership of this
pixmap and will C<FreePixmap()> once installed.  "None" or 0 means no
pixmap, which gives the server's default root background (usually a black
and white weave pattern).

C<pixmap_allocated_colors> should be true if any of the pixels in C<pixmap>
were allocated with C<AllocColor()> etc, as opposed to just the screen
pre-defined black and white pixels (and any TOG-CUP reserved).

When an allocated pixel or a pixmap with allocated pixels is set as the
background the C<_XSETROOT_ID> mechanism described above means the C<$X>
connection could be killed by another C<xsetroot> at any time, perhaps
immediately, and so should not be used any more.  The easiest way is to make
C<set_background()> the last thing done on C<$X>.

Setting a C<pixel> or C<pixmap> can only be done on a C<$X> connection as
such, not with the C<display> option.  This is because retaining the colours
with the C<_XSETROOT_ID> mechanism can only be done from the client
connection which created the resources, not a new separate client
connection.

=back

=head1 FILES

F</etc/X11/rgb.txt> on the server, being the usual colour names database for
the C<color> option above.

=head1 SEE ALSO

L<xsetroot(1)>,
L<X11::Protocol>,
L<X11::Protocol::Ext::TOG_CUP>

L<Esetroot(1)>,
L<fvwm-root(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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
