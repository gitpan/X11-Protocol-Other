# Copyright 2011 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

package X11::Protocol::WM;
use 5.004;
use strict;
use Carp;
use X11::AtomConstants;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 7;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(set_wm_hints
                set_wm_transient_for
                set_net_wm_window_type);

# uncomment this to run the ### lines
#use Smart::Comments;


# /usr/share/doc/xorg-docs/specs/ICCCM/icccm.txt.gz
# /usr/share/doc/xorg-docs/specs/CTEXT/ctext.txt.gz


#------------------------------------------------------------------------------
# WM_TRANSIENT

# $transient_for eq 'None' supported for generality, but not yet documented
# since not sure such a property value would be ICCCM compliant
sub set_wm_transient_for {
  my ($X, $window, $transient_for) = @_;
  _set_single_property ($X, $window,
                        X11::AtomConstants::WM_TRANSIENT_FOR,  # prop name
                        X11::AtomConstants::WINDOW,            # type
                        _num_none ($transient_for));
}

# =item C<$transient_for = X11::Protocol::WM::get_wm_transient_for ($X, $window)>
# not sure about this yet
# sub get_wm_transient_for {
#   my ($X, $window) = @_;
#   _get_single_property ($X, $window,
#                         X11::AtomConstants::WM_TRANSIENT_FOR, X11::AtomConstants::WINDOW);
# }


#------------------------------------------------------------------------------
# wmstate enum

{
  my %wmstate = (WithdrawnState => 0,
                 DontCareState  => 0, # no longer in ICCCM
                 NormalState    => 1,
                 ZoomState      => 2, # no longer in ICCCM
                 IconicState    => 3,
                 InactiveState  => 4, # no longer in ICCCM
                );
  sub _wmstate_num {
    my ($wmstate) = @_;
    if (defined $wmstate && defined (my $num = $wmstate{$wmstate})) {
      return $num;
    }
    return $wmstate;
  }
}

#------------------------------------------------------------------------------
# WM_HINTS

sub set_wm_hints {
  my $X = shift;
  my $window = shift;
  $X->ChangeProperty($window,
                     X11::AtomConstants::WM_HINTS, # prop name
                     X11::AtomConstants::WM_HINTS, # type
                     32,           # format
                     'Replace',
                     _pack_wm_hints($X, @_));
}

{
  my $format = 'LLLLLllLL';
  # The C<urgency> hint was called "visible" in X11R5.  The name "urgency"
  # is used here per X11R6.  The actual field sent and received is the same.
  #
  my %key_to_flag = (input         => 1,
                     initial_state => 2,
                     icon_pixmap   => 4,
                     icon_window   => 8,
                     icon_x        => 16,
                     icon_y        => 16,
                     icon_mask     => 32,
                     window_group  => 64,
                     # message       => 128, # in the code, obsolete
                     # urgency       => 256, # in the code
                    );

  # =item C< $bytes = _pack_wm_bytes ($X, key=E<gt>value...)>
  #
  # Pack a set of values into a byte string of C<WM_HINTS> type.  The
  # key/value arguments are per C<set_wm_hints> above and the result is the
  # raw bytes stored in a C<WM_HINTS> property.
  #
  # The C<$X> argument is not actually used currently, but is present in
  # case some of the values might use the C<$X-E<gt>interp> type lookup.
  #
  sub _pack_wm_hints {
    my ($X, %hint) = @_;
    my $flags = 0;
    if (delete $hint{'message'}) {
      $flags = 128;
    }
    if (delete $hint{'urgency'}) {
      $flags |= 256;
    }
    my $key;
    foreach $key (keys %hint) {
      my $bit = $key_to_flag{$key}
        || croak "Unknown WM_HINT field: ",$key;
      if (defined $hint{$key}) {
        $flags |= $key_to_flag{$key};
      }
    }
    return pack ($format,
                 $flags,
                 $hint{'input'} || 0,         # CARD32 bool
                 _wmstate_num($hint{'initial_state'}) || 0, # CARD32 enum
                 _num_none($hint{'icon_pixmap'}) || 0,   # PIXMAP
                 _num_none($hint{'icon_window'}) || 0,   # WINDOW
                 $hint{'icon_x'} || 0,        # INT32
                 $hint{'icon_y'} || 0,        # INT32
                 _num_none($hint{'icon_mask'}) || 0,     # PIXMAP
                 _num_none($hint{'window_group'}) || 0,  # WINDOW
                );
  }
}

#------------------------------------------------------------------------------
# _NET_WM_WINDOW_TYPE

sub set_net_wm_window_type {
  my ($X, $window, $window_type) = @_;
  _set_single_property ($X, $window,
                        $X->atom('_NET_WM_WINDOW_TYPE'),
                        X11::AtomConstants::ATOM,
                        _net_wm_window_type_to_atom ($X, $window_type));
}

# not documented yet ...
sub _net_wm_window_type_to_atom {
  my ($X, $window_type) = @_;
  if (! defined $window_type || $window_type =~ /^\d+$/) {
    return $window_type;
  } else {
    return $X->atom ("_NET_WM_WINDOW_TYPE_$window_type");
  }
}

# unless ($window_type =~ /^_NET_WM/) {
# }
# my ($akey, $atype) = _atoms ($X,
#                              '_NET_WM_WINDOW_TYPE',
#                              "_NET_WM_WINDOW_TYPE_$window_type");
#  a type stringcan be an atom integer, a full atom name like
# "_NET_WM_WINDOW_TYPE_NORMAL", or just the type part "NORMAL".  The types in
# the EWMH spec are


#------------------------------------------------------------------------------
# helpers

sub _set_single_property {
  my ($X, $window, $prop, $type, $value) = @_;
  if (defined $value) {
    $X->ChangeProperty ($window,
                        $prop,  # prop name
                        $type,  # type
                        32,     # format
                        'Replace',
                        pack ('L', $value));
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

# or maybe $X->num('IDorNone',$xid)
#          $X->num('XID',$xid)
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}

1;
__END__


# =item C<$window_type = X11::Protocol::WM::get_net_wm_window_type_atom ($X, $window)>
#
# C<get_net_wm_window_type_atom> returns C<$window_type> as an atom (integer).
#
# not documented ...
sub _get_net_wm_window_type_atom {
  my ($X, $window) = @_;
  _get_single_property ($X, $window,
                        $X->atom('_NET_WM_WINDOW_TYPE'),
                        X11::AtomConstants::ATOM);
}

# not documented ...
sub _get_single_property {
  my ($X, $window, $prop, $type) = @_;
  my ($value, $got_type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $prop,
                       $type,
                       0,  # offset
                       1,  # length, 1 x CARD32
                       0); # delete
  if ($format == 32) {
    $ret = scalar(unpack 'L', $value);
    if ($type == X11::AtomConstants::WINDOW || $type == X11::AtomConstants::PIXMAP) {
      if ($ret == 0 && $X->{'do_interp'}) {
        $ret = 'None';
      }
    }
    return $ret;
  } else {
    return undef;
  }
}




=for stopwords Ryde XID NETWM enum NormalState IconicState ICCCM ClientMessage iconify EWMH multi-colour

=head1 NAME

X11::Protocol::WM -- window manager things for client programs

=head1 SYNOPSIS

 use X11::Protocol::WM;

=head1 DESCRIPTION

This is some window manager related functions for use by client programs.
There's a lot a client can get or set, but only a few here yet.

=head1 FUNCTIONS

=head2 WM Hints

=over 4

=item C<X11::Protocol::WM::set_wm_hints ($X, $window, key=E<gt>value, ...)>

Set the C<WM_HINTS> property on C<$window> (an XID).  For example,

    X11::Protocol::WM::set_wm_hints
        ($X, $my_window,
         input         => 1,
         initial_state => 'NormalState',
         icon_pixmap   => $my_pixmap);

The key/value parameters are as follows.

    input             integer 0 or 1
    initial_state     enum string or number
    icon_pixmap       pixmap XID (integer), depth 1
    icon_window       window XID (integer)
    icon_x            integer coordinate
    icon_y            integer coordinate
    icon_mask         pixmap XID (integer)
    window_group      window XID (integer)
    urgency           boolean

C<input> should be 1 if the client wants the window manager to give
C<$window> the keyboard input focus using C<SetInputFocus> (or if you ask
for C<WM_TAKE_FOCUS> in C<WM_PROTOCOLS> then with a ClientMessage instead).
C<input> should be 0 if the window manager should not give the focus, either
because C<$window> is output-only, or if you put C<WM_TAKE_FOCUS> in
C<WM_PROTOCOLS> then because the client will C<SetInputFocus> to itself on a
suitable button press etc.

C<initial_state> can be a string or number.  "NormalState" or "IconicState"
are allowed by the ICCCM as a desired initial state.

    NormalState       1
    IconicState       3

C<icon_pixmap> should be a bitmap (depth 1).  The window manager will choose
suitable contrasting colours.  C<$icon_window> can be used for a
multi-colour icon, either with a suitable background or drawn on-demand
(Expose events etc).  The window manager might set a C<WM_ICON_SIZE>
property on the root window for good icon sizes but there's nothing in this
module to retrieve that yet.

C<urgency> true means the window is important and the window manager should
draw the user's attention to it in some way.  The client can change this at
any time to reflect current importance.

=cut

    # message            boolean (obsolete)

    # WithdrawnState     0
    # NormalState        1
    # ZoomState          2
    # IconicState        3
    # InactiveState      4

=back

=head2 WM Transient For

=over

=item C<X11::Protocol::WM::set_wm_transient_for ($X, $window, $transient_for)>

Set the C<WM_TRANSIENT_FOR> property on C<$window> (an XID).
C<$transient_for> is another window XID, or C<undef> if C<$window> is not
transient for anything.

"Transient for" means C<$window> is some sort of dialog or menu related to
the C<$transient_for> window.  The window manager will generally iconify
C<$window> together with its C<$transient_for>, etc.

=back

=head2 Net WM Window Type

=over

=item C<X11::Protocol::WM::set_net_wm_window_type ($X, $window, $window_type)>

Set the C<_NET_WM_WINDOW_TYPE> property on C<$window> (an XID).
C<$window_type> can be a  type string as follows from the EWMH,

    NORMAL
    DIALOG
    DESKTOP
    DOCK
    TOOLBAR
    MENU
    UTILITY
    SPLASH

C<$window_type> can also be an integer atom such as
C<$X-E<gt>atom('_NET_WM_WINDOW_TYPE_DIALOG')>.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use X11::Protocol::WM 'set_wm_hints';
    set_wm_hints ($X, $window, input => 1, ...);

Or just called with full package name

    use X11::Protocol::WM;
    X11::Protocol::WM::set_wm_hints ($X, $window, input => 1, ...);

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Other>

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
