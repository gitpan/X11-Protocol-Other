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
package X11::Protocol::Ext::MIT_SCREEN_SAVER;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 17;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/share/doc/x11proto-scrnsaver-dev/saver.txt.gz
#
# /usr/include/X11/extensions/saver.h
# /usr/include/X11/extensions/saverproto.h
#


# these not documented yet ... and not used as such
use constant CLIENT_MAJOR_VERSION => 1;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------

my $reqs =
  [
   [ 'MitScreenSaverQueryVersion',  # 0
     sub {
       my ($X, $client_major, $client_minor) = @_;
       ### MitScreenSaverQueryVersion request
       return pack 'CCxx', $client_major, $client_minor;
     },
     sub {
       my ($X, $data) = @_;
       return unpack 'x8SS', $data;
     }],

   [ 'MitScreenSaverQueryInfo',  # 1
     \&_request_card32s,
     sub {
       my ($X, $data) = @_;
       my ($state, $window, $til_or_since, $idle, $event_mask, $kind)
         = unpack 'xCx6LLLLC', $data;
       return ($X->interp('MitScreenSaverState',$state),
               _interp_none($X,$window),
               $til_or_since,
               $idle,
               $event_mask,
               $X->interp('MitScreenSaverKind',$kind));
     } ],

   [ 'MitScreenSaverSelectInput',  # 2
     \&_request_card32s ],  # ($X, $drawable, $event_mask)

   [ 'MitScreenSaverSetAttributes',  # 3
     sub {
       ### MitScreenSaverSetAttributes request
       # same args as $X->CreateWindow(), but pack format a bit different
       my ($X, $drawable,
           $class, $depth, $visual,
           $x, $y, $width, $height,
           $border_width,
           @values) = @_;

       # ChangeWindow
       my ($data) = &{$X->{'requests'}->[2]->[1]} ($X, $drawable, @values);
       ### $data

       return (pack ('LssSSSCCL',
                     $drawable,
                     $x, $y,
                     $width, $height,
                     $border_width,
                     $X->num('Class',$class),
                     $depth,
                     _num_visual($visual))
               . substr ($data, 4));
     } ],

   [ 'MitScreenSaverUnsetAttributes',     # 4
     \&_request_card32s ],  # ($X, $drawable)

  ];

sub _num_visual {
  my ($visual) = @_;
  if ($visual eq 'CopyFromParent') {
    return 0;
  } else {
    return $visual;
  }
}

#------------------------------------------------------------------------------

my $MitScreenSaverNotify_event
  = [ 'xCxxLLLCC',
      ['state','MitScreenSaverState'],
      'time',
      'root',
      'window',
      ['kind','MitScreenSaverKind'],
      'forced' ];

#------------------------------------------------------------------------------

my %const_arrays
  = (
     MitScreenSaverKind      => ['Blanked', 'Internal', 'External'],
     MitScreenSaverState     => ['Off', 'On', 'Cycle', 'Disabled'],

     # not sure about this one yet
     # MitScreenSaverEventMask => ['Notify', 'Cycle'],
    );
my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### MIT_SCREEN_SAVER new()

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'MitScreenSaverNotify';
  $X->{'ext_events'}[$event_num] = $MitScreenSaverNotify_event;

  _ext_requests_install ($X, $request_num, $reqs);

  # my ($server_major, $server_minor) = $X->req ('MitScreenSaverQueryVersion',
  #                                              CLIENT_MAJOR_VERSION,
  #                                              CLIENT_MINOR_VERSION);
  # ### $server_major
  # ### $server_minor
  return bless {
                # major => $server_major,
                # minor => $server_minor,
               }, $class;
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

sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub _interp_none {
  my ($X, $xid) = @_;
  if ($X->{'do_interp'} && $xid == 0) {
    return 'None';
  } else {
    return $xid;
  }
}

# Similar to Xlib XScreenSaverSaverRegister() maybe.
# Or plain funcs X11::Protocol::Ext::MIT_SCREEN_SAVER::register()
# set_screen_saver_id()
# get_screen_saver_id()
#
# {
#   package X11::Protocol;
# 
#   sub MitScreenSaverRegister {
#     my ($X, $screen, $type, $xid) = @_;
#     $X->ChangeProperty ($X->{'screen'}->[$screen]->{'root'},
#                         $X->atom('_SCREEN_SAVER_ID'),  # property
#                         $type,
#                         32,                            # format
#                         'Replace',
#                         $xid);
#   }
#   sub MitScreenSaverUnregister {
#     my ($X, $screen) = @_;
#     $X->DeleteProperty ($X->{'screen'}->[$screen]->{'root'},
#                         $X->atom('_SCREEN_SAVER_ID'));
#   }
#   sub MitScreenSaverGetRegistered {
#     my ($X, $screen, $type, $xid) = @_;
#     my ($value, $got_type, $format, $bytes_after)
#       = $X->GetProperty ($X->{'screen'}->[$screen]->{'root'},
#                          $X->atom('_SCREEN_SAVER_ID'),  # property
#                          $type,
#                          0,  # offset
#                          1,  # length
#                          0); # delete;
#     if ($format == 32) {
#       return unpack 'L', $value;
#     } else {
#       return undef;
#     }
#   }
# }

1;
__END__

=for stopwords XID arrayrefs Ryde enum pixmap closedown NotifyMask CycleMask XFree86 builtin

=head1 NAME

X11::Protocol::Ext::MIT_SCREEN_SAVER - external screen saver support

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('MIT-SCREEN-SAVER')
   or print "MIT-SCREEN-SAVER extension not available";

=head1 DESCRIPTION

The MIT-SCREEN-SAVER extension allows a client screen saver program to draw
the screen saver.  Any client can listen for screen saver activation too.

See the core C<SetScreenSaver> for the screen idle timeout, saver cycle
period, and the "Blank" or "Internal" builtin saving styles.  And see the
core C<ForceScreenSaver> to forcibly turn on the screen saver.

=head1 REQUESTS

The following requests are made available with an C<init_extension()> per
L<X11::Protocol/EXTENSIONS>.

    my $bool = $X->init_extension('MIT-SCREEN-SAVER');

=over

=item C<($server_major, $server_minor) = $X-E<gt>MitScreenSaverQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which will
be the closest to the client requested version that the server supports.

The code in this module supports 1.0.  The intention would be to
automatically negotiate within C<init_extension()> if/when necessary.

=item C<($state, $window, $til_or_since, $idle, $event_mask, $kind) = $X-E<gt>MitScreenSaverQueryInfo ($drawable)>

Return information about the screen saver on the screen of C<$drawable> (an
XID).

C<$state> is an enum string "Off", "On", or "Disabled".

C<$window> is the screen saver window, or "None".  It might exist always, or
might be created only for "External" kind or only when required, etc.  In
any case it's an override-redirect child of the root window but does not
appear in its C<QueryTree> children.

C<$til_or_since> is a time in milliseconds.  If C<$state> is "Off" then it's
how long until the saver will be activated due to idle.  Or if C<$state> is
"On" then how long in milliseconds since the saver was activated.  (But see
L</"BUGS"> below.)

C<$idle> is how long in milliseconds the screen has been idle.

C<$event_mask> is the current client's mask as set by
C<MitScreenSaverSelectInput()> below.

C<$kind> is an enum string for how the saver is being done now, or how it
will be done when next activated,

    "Blanked"     video output turned off
    "Internal"    server builtin saver
    "External"    external saver client

=item C<$X-E<gt>MitScreenSaverSelectInput ($drawable, $event_mask)>

Select C<MitScreenSaverNotify> events from the screen of C<$drawable> (an
XID).  C<$event_mask> has two bits,

                  bitpos  bitval
    NotifyMask	    0      0x01
    CycleMask       1      0x02

There's no pack function for these yet, so just give the integer bitvals,
for example 0x03 for both.

=item C<$X-E<gt>MitScreenSaverSetAttributes ($drawable, $class, $depth, $visual, $x, $y, $width, $height, $border_width, key =E<gt> value, ...)>

Setup the screen saver window on the screen of C<$drawable> (an XID).

The arguments are the same as the core C<CreateWindow>, except there's no
new XID to create and the parent window is always the root window on the
screen of C<$drawable>.

This setup makes the saver "External" kind on its next activation, but if
currently active then it's not changed.  The client can listen for
C<MitScreenSaverNotify> (see L</"EVENTS"> below) to know when the saver is
activated.  The saver window XID is reported in that Notify and exposures
can be selected on it to know when to drawn, unless perhaps a background
pixel or pixmap within this C<MitScreenSaverSetAttributes()> is enough.

Only one client at a time can setup a saver window like this.  If another
has done so then an Access error results.

=item C<$window = $X-E<gt>MitScreenSaverUnsetAttributes ($drawable)>

Unset the screen saver window.  If the client did not set it up then do
nothing.

This changes the saver from "External" kind back to the server builtin.  If
the screen saver is currently active then that happens immediately.

At client shutdown an Unset is done automatically, except for
C<RetainPermanent> closedown mode.

=back

=head1 EVENTS

C<MitScreenSaverNotify> events are sent to the client when selected by
C<MitScreenSaverSelectInput> above.  It reports when the screen saver state
changes.  The event has the usual fields

    name             "MitScreenSaverNotify"
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

and event-specific fields

    state         "Off", "On", "Cycle"
    time          server timestamp (integer)
    root          root window of affected screen (XID)
    window        the screen saver window (XID)
    kind          "Blanked", "Internal", "External"
    forced        integer 0 or 1

C<state> is "Off" if the saver has turned off or "On" if it turned on.
C<forced> is 1 if the change was due to a C<ForceScreenSaver> request rather
than user activity/inactivity.  On/Off events are selected by NotifyMask to
C<MitScreenSaverSelectInput()> above.

C<state> is "Cycle" if the saver cycling period has expired, which means
it's time to show something different.  This is selected by CycleMask to
C<MitScreenSaverSelectInput()> above.

C<kind> is the current saver kind, as described under
C<MitScreenSaverQueryInfo()> above.

=head1 BUGS

In XFree86 and X.org servers through to circa X.org 1.10, if the screen
saver is activated with a C<ForceScreenSaver> request then the
C<$til_or_since> from C<MitScreenSaverQueryInfo> is a big number, apparently
being a negative for the future time when it would have activated due to
idle.  There's no attempt to do anything about that here.

In these servers when the saver is "On" the idle timeout apparently
continues to fire too, so the "since" of C<$til_or_since> is only since the
last firing, as if screen saver was re-activated, not the time since first
activated, or something like that.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::DPMS>

L<xset(1)>, for setting the core screen saver parameters from the command
line.

L<xscreensaver(1)>

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
