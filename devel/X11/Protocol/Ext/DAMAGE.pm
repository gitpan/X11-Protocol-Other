# Copyright 2011 Kevin Ryde


# geometry -> geometry ?
# area_x or arrayref rect ?




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
package X11::Protocol::Ext::DAMAGE;
use strict;

use vars '$VERSION';
$VERSION = 3;

# uncomment this to run the ### lines
#use Smart::Comments;

# /usr/share/doc/x11proto-damage-dev/damageproto.txt.gz
# 
#
# /usr/include/X11/extensions/Xdamage.h
# /usr/include/X11/extensions/damageproto.h
# /usr/include/X11/extensions/damagewire.h
#
# server side source:
#     http://cgit.freedesktop.org/xorg/xserver/tree/damageext/damageext.c
#


### DAMAGE.pm loads

my $reqs = [
            ["DamageQueryVersion",  # 0
             sub {
               my ($X, $major, $minor) = @_;
               ### DamageQueryVersion request
               return pack 'LL', $major, $minor;
             },
             sub {
               my ($X, $data) = @_;
               ### DamageQueryVersion reply
               return unpack 'x8LL', $data;

               # Any interest in holding onto the version?
               # my ($server_major, $server_minor) = 
               # my $self;
               # if ($self = $self->{'ext'}{'DAMAGE'}->[3]) {
               #   $self->{'major'} = $server_major;
               #   $self->{'minor'} = $server_minor;
               # }
               # return ($server_major, $server_minor);
             }],

            ["DamageCreate",  # 1
             sub {
               my ($X, $damage, $drawable, $level) = @_;
               ### DamageCreate
               return pack ('LLCxxx',
                            $damage,
                            $drawable,
                            $X->num('DamageReportLevel',$level));
             }],

            ["DamageDestroy",  # 2
             # ($damage)
             \&_request_xids ],

            ["DamageSubtract",  # 3
             # ($damage, $repair_region, $parts_region)
             \&_request_xids ],

            ["DamageAdd",  # 4
             # ($damage, $region)
             \&_request_xids ],
           ];

my $events =
  [ sub {
      my $X = shift;
      my $data = shift;
      ### DamageNotify unpack: @_[1..$#_]
      my ($level, $drawable, $damage, $time, $area, $geometry)
        = unpack 'xCxxL3a8a8', $data;
      ### fields: $level, $drawable, $damage, $time, $area, $geometry
      ### area: _unpack_rectangle($area)
      ### geometry: _unpack_rectangle($geometry)
      return (@_,  # base fields
              level    => $X->interp('DamageReportLevel',$level),
              drawable => $drawable,
              damage   => $damage,
              time     => _interp_time($time),
              area     => _unpack_rectangle($area),
              geometry => _unpack_rectangle($geometry),
             );
    }, sub {
      my ($X, %h) = @_;
      return (pack('xCxxL3ssSSssSS',
                   $X->num('DamageReportLevel',$h{'level'}),
                   $h{'drawable'},
                   $h{'damage'},
                   _num_time($h{'time'}),
                   @{$h{'area'}},      # [$x,$y,$w,$h]
                   @{$h{'geometry'}}), # [$x,$y,$w,$h]
              1); # "do_seq" put in sequence number
    } ];

  # ['xCxxL3ssSSssSS',
  #  ['level','DamageReportLevel'],
  #  'drawable',
  #  'damage',
  #  ['time',['CurrentTime']]
  #  'area_x',
  #  'area_y',
  #  'area_width',
  #  'area_height',
  #  'geometry_x',
  #  'geometry_y',
  #  'geometry_width',
  #  'geometry_height',
  # ];

my $DamageReportLevel_array = [ 'RawRectangles',
                                'DeltaRectangles',
                                'BoundingBox',
                                'NonEmpty' ];
my $DamageReportLevel_hash
  = { X11::Protocol::make_num_hash($DamageReportLevel_array) };

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### DAMAGE new()

  # Constants
  $X->{'ext_const'}->{'DamageReportLevel'} = $DamageReportLevel_array;
  $X->{'ext_const_num'}->{'DamageReportLevel'} = $DamageReportLevel_hash;

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'DamageNotify';
  $X->{'ext_events'}[$event_num] = $events;

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Must DamageQueryVersion to negotiate desired version, or at least X.org
  # server 1.9.x gives "Opcode" error if not.
  $X->req('DamageQueryVersion', 1, 1);
  return bless { }, $class;

  # Any interest in holding onto the version?
  #  my ($major, $minor) = $X->req('DamageQueryVersion', 1, 1);
  # return bless {
  #               major => $major,
  #               minor => $minor,
  #              }, $class;
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;
  $X->{'ext_request'}{$request_num} = $reqs;
  my $i;
  foreach $i (0 .. $#$reqs) {
    $X->{'ext_request_num'}{$reqs->[$i]->[0]} = [$request_num, $i];
  }
}

sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq 'None') {
    return 0;
  } else {
    return $xid;
  }
}

sub _unpack_rectangle {
  my ($data) = @_;
  return [ unpack 'ssSS', $data ];
}

sub _interp_time {
  my ($time) = @_;
  if ($time == 0) {
    return 'CurrentTime';
  } else {
    return $time;
  }
}
sub _num_time {
  my ($time) = @_;
  if ($time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}

1;
__END__

=for stopwords drawables pixmaps XFIXES DamageNotify XID subwindows enum unhandled GL arrayref umm pixmap Ryde

=head1 NAME

X11::Protocol::Ext::DAMAGE - drawing notifications

=head1 SYNOPSIS

 use X11::Protocol;
 $X = X11::Protocol->new;
 $X->init_extension('DAMAGE')
   or print "DAMAGE extension not available";

=head1 DESCRIPTION

The DAMAGE extension lets a client monitor changes to drawables (windows,
pixmaps, etc) arising from drawing operations, including drawing in
sub-windows which appears in the parent.

This can be used to replicate or post-process window contents in some way,
such as displaying a copy on another screen, or a magnified view, etc.  The
root window can be monitored to listen for changes on the whole screen.

Changes from drawing are conceived as "damage".  A server-side damage object
accumulates changed areas as rectangles, making a server-side "region" per
the XFIXES extension (version 2.0, see L<X11::Protocol::Ext::XFIXES>)

A DamageNotify event is delivered when damage accumulates in the object.
A reporting level controls the level of detail, ranging from just one event
on becoming non-empty, up to an event for every drawing operation.

Fetching the accumulated damage region (or part of it) is reckoned as a
"repair".  It doesn't change the drawable in any way, just picks out
accumulated areas from the damage object.  This fetch is atomic, so nothing
is lost if the client is a bit lagged etc.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $available = $X->init_extension('DAMAGE');

=head2 DAMAGE 1.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>DamageQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like, the returned
C<$server_major> and C<$server_minor> is what the server will do, which
might be less than requested (but not more).

The current code supports up to 1.1.  If asking for higher then be careful
that it's upwardly compatible.  The module code negotiates a version in
C<init_extension()> so C<DamageQueryVersion> is not needed normally.

=item C<$X-E<gt>DamageCreate ($damage, $drawable, $level)>

Create a new damage object in C<$damage> (a new XID) which monitors changes
to C<$drawable>.  If C<$drawable> is a window then changes to its subwindows
are included too.

C<$level> is an enum string controlling how often C<DamageNotify> events are
emitted (see L</"EVENTS"> below).

    RawRectangles      every change
    DeltaRectangles    when damage region expands
    BoundingBox        when damage bounding box expands
    NonEmpty           when damage first becomes non-empty

For example,

    # listening to every drawing operation on the whole screen
    my $damage = $X->new_rsrc;
    $X->DamageCreate ($damage, $X->root, 'RawRectangles');

=item C<$X-E<gt>DamageDestroy ($damage)>

Destroy C<$damage>.

=item C<$X-E<gt>DamageSubtract ($damage, $repair_region, $parts_region)>

Move the accumulated region in C<$damage> to C<$parts_region> (an XID), and
clear it from C<$damage>.

If C<$parts_region> is "None" then C<$damage> is cleared and the region
discarded.  This can be used if for example the entire C<$drawable> will be
copied or re-examined, so exactly which parts changed is not needed.

C<$repair_region> is what parts of C<$damage> to consider.  "None" means
move and clear everything in C<$damage>.  Otherwise C<$repair_region> is a
region XID and the parts of the damage region within the C<$repair_region>
are moved and cleared.  Anything outside is left in C<$damage>.

If anything is left in C<$damage> then a new C<DamageNotify> event is
immediately sent.  This is good for instance if you picked out a
C<$repair_region> corresponding to what you thought was the window size
(perhaps from the C<geometry> field of a C<DamageNotify> event), but it has
grown in the interim.

Region objects for use here are created with the XFIXES 2.0 extension (see
L<X11::Protocol::Ext::XFIXES>), which can be expected to be available
whenever DAMAGE is available.  If you're using "None" and "None" to clear
and discard the damage region then there's no need to
C<init_extension('XFIXES')>.

=back

=head2 DAMAGE 1.1

=over

=item C<$X-E<gt>DamageAdd ($drawable, $region)>

Report to any interested damage objects that changes have occurred in
C<$region> (a region XID) of C<$drawable>.

This is used by "direct rendering" clients which draw to the hardware or GL,
etc, rather than protocol drawing operations, so the server doesn't know
window etc contents have changed.

=back

=head1 EVENTS

C<DamageNotify> events are sent to the client which created the damage
object.  There's nothing to select the events, they're always generated for
any damage object.  The event has the usual fields

    name             "DamageNotify"
    synthetic        true if from a SendEvent
    code             integer
    sequence_number  integer

and event-specific fields

    damage           damage object XID
    drawable         XID, per DamageCreate
    level            enum, per DamageCreate
    more             boolean, if more DamageNotify on the way
    time             server timestamp (integer)
    area             arrayref [$x,$y,$width,$height]
    geometry         arrayref [$rootx,$rooty,$width,$height]

C<drawable> and C<level> are per the C<DamageCreate> which made the
C<damage> object.

C<more> is true if there's further C<DamageNotify> events on the way for
this damage object.  This can happen when the "level" means there's a set of
C<area> rectangles to report.

C<area> is a rectangle within C<drawable>, as a 4-element arrayref,

    [ $x, $y, $width, $height ]

and what it covers depends on the reporting level requested,

=over

=item *

C<RawRectangles> -- a rectangle around an arc, line, etc, drawing operation
which changed C<drawable>.

=item *

C<DeltaRectangles> -- an additional rectangle extending the damage region.
Only new rectangles are reported, not any of the existing damage region.
Reporting a region addition may require multiple C<DamageNotify> events.

=item *

C<BoundingBox> -- a bounding box around the damage region accumulated,
bigger than previously reported.

=item *

C<NonEmpty> -- umm, maybe the entire drawable.

=back

C<geometry> is the current size and position of the drawable as a 4-element
arrayref in root window coordinates.  For a pixmap, C<$root_x> and
C<$root_y> are 0.

    [ $root_x, $root_y, $width, $height ]

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Ext::XFIXES>

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
