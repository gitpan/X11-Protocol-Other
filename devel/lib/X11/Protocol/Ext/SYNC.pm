# alarm parameters

# createfence arg order?



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
package X11::Protocol::Ext::SYNC;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 15;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
#use Smart::Comments;


# /usr/share/doc/x11proto-xext-dev/sync.txt.gz
#
# /usr/include/X11/extensions/syncproto.h
# /usr/include/X11/extensions/syncconst.h
# /usr/include/X11/extensions/syncstr.h
#
# /usr/include/X11/extensions/sync.h
#    Xlib.
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#
# X11R7.6 SYNC 3.0


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 3;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------

{
  my $uv = ~0;
  my $bits = 0;
  while ($uv && $bits < 64) {
    $uv >>= 1;
    $bits++;
  }

  if ($bits >= 64) {
     eval "#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_sv {
  my ($hi,$lo) = @_;
  return ($hi << 32) + $lo;
}
1;
HERE
  } else {
     eval "#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use Math::BigInt;
sub _hilo_to_sv {
  my ($hi,$lo) = @_;
  return Math::BigInt->new($hi)->blsft(32)->badd($lo);
}
1;
HERE
  }
}

sub _sv_to_hilo {
  my ($sv) = @_;
  return ($sv >> 32,          # hi
          $sv & 0xFFFF_FFFF); # lo
}


#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     SyncValueType  => ['Absolute', 'Relative' ],
     SyncTestType   => [ 'PositiveTransition','NegativeTransition',
                         'PositiveComparison','NegativeComparison' ],
     SyncAlarmState => ['Active', 'Inactive', 'Destroyed' ],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------

my $reqs =
  [
   ['SyncInitialize',  # 0
    sub {
      my ($X, $major, $minor) = @_;
      return pack 'CCxx', $major, $minor;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8CC', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack ..., $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'SYNC'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['SyncListSystemCounters',  # 1
    \&_request_empty,
    sub {
      my ($X, $data) = @_;
      ### SyncListSystemCounters reply(): length($data), $data
      my ($ncounters) = unpack 'x8L', $data;
      ### $ncounters
      my @ret;
      my $pos = 32;
      foreach (1 .. $ncounters) {
        ### at: $pos, substr($data,$pos)
        my ($counter, $resolution_hi, $resolution_lo, $name_len)
          = unpack 'LlLS', substr($data,$pos,14); # 4+8+2=14
        ### elem: [ $counter, $resolution_hi, $resolution_lo, $name_len ]
        $pos += 14;
        my $name = substr ($data, $pos, $name_len);
        $pos += $name_len;
        $pos += X11::Protocol::padding($pos);
        push @ret, [ $counter,
                     _hilo_to_sv($resolution_hi,$resolution_lo),
                     $name ];
      }
      return @ret;
    }],

   ['SyncCreateCounter',  # 2
    sub {
      my ($X, $counter, $initial) = @_;
      return pack 'LLL', _sv_to_hilo($initial);
    },
   ],

   ['SyncSetCounter',  # 3
    sub {
      my ($X, $counter, $value) = @_;
      return pack 'LLL', _sv_to_hilo($value);
    },
   ],

   ['SyncChangeCounter',  # 4
    sub {
      my ($X, $counter, $value) = @_;
      return pack 'LLL', _sv_to_hilo($value);
    },
   ],

   ['SyncQueryCounter',  # 5
    \&_request_card32s, # ($X, $counter)
    sub {
      my ($X, $data) = @_;
      return _hilo_to_sv (unpack 'lL', $data);
    },
   ],

   ['SyncDestroyCounter',  # 6
    \&_request_card32s, # ($X, $counter)
   ],

   ['SyncAwait',  # 7
    \&_request_empty,
   ],

   ['SyncCreateAlarm',  # 8
    sub {
      my ($X, $alarm) = @_;
      return pack 'L', $alarm;
    }],
   ['SyncChangeAlarm',  # 9
    sub {
      my ($X, $alarm) = @_;
      return pack 'L', $alarm;
    }],

   ['SyncQueryAlarm',  # 10
    \&_request_card32s, # ($X, $alarm)
   ],

   ['SyncDestroyAlarm',  # 11
    \&_request_card32s, # ($X, $alarm)
   ],

   ['SyncSetPriority',  # 12
    sub {
      my ($X, $xid, $priority) = @_;
      return pack 'Ll', $xid, $priority;
    }],
   ['SyncGetPriority',  # 13
    \&_request_card32s, # ($X, $xid)
    sub {
      my ($X, $data) = @_;
      return unpack 'x8l';
    }],

   #------------------------
   # version ...

   ['SyncCreateFence',  # 14
    sub {
      shift; # ($X, $drawable, $fence, $initially_triggered)
      return pack 'LLCxxx', @_;
    }],

   ['SyncTriggerFence',  # 15
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncResetFence',  # 16
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncDestroyFence',  # 17
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncQueryFence',  # 18
    \&_request_card32s, # ($X, $fence)
   ],

   ['SyncAwaitFence',  # 19
    \&_request_card32s, # ($X, $fence,...)
   ],
  ];


#------------------------------------------------------------------------------
# events

my $SyncCounterNotify_event
  = [ sub {
        my $X = shift;
        my $data = shift;

        my ($counter,
            $wait_value_hi, $wait_value_lo,
            $counter_value_hi,$counter_value_lo,
            $time,
            $count,
            $destroyed)
          = unpack 'xxxxLlLlLLSCx', $data;
        return
          (@_,
           counter       => $counter,
           wait_value    => _hilo_to_sv($wait_value_hi,$wait_value_lo),
           counter_value => _hilo_to_sv($counter_value_hi,$counter_value_lo),
           time          => $time,
           count         => $count);
      },
      sub {
        my ($X, %h) = @_;
        return (pack('xCxxLlLlLLSCx',
                     $h{'counter'},
                     _sv_to_hilo($h{'wait_value'}),
                     _sv_to_hilo($h{'counter_value'}),
                     $h{'time'},
                     $h{'count'}),
                1); # "do_seq" put in sequence number
      } ];

my $SyncAlarmNotify_event
  = [ sub {
        my $X = shift;
        my $data = shift;

        my ($alarm,
            $counter_value_hi,$counter_value_lo,
            $alarm_value_hi, $alarm_value_lo,
            $time,
            $state)
          = unpack 'xxxxLlLlLLCx3', $data;
        return
          (@_,
           counter       => $alarm,
           counter_value => _hilo_to_sv($counter_value_hi,$counter_value_lo),
           alarm_value   => _hilo_to_sv($alarm_value_hi,$alarm_value_lo),
           time          => $time,
           state         => $X->interp('SyncAlarmState',$state));
      },
      sub {
        my ($X, %h) = @_;
        return (pack('xxxxLlLlLLCx3',
                     $h{'alarm'},
                     _sv_to_hilo($h{'alarm_value'}),
                     _sv_to_hilo($h{'counter_value'}),
                     $h{'time'},
                     $X->num('SyncAlarmState',$h{'state'})),
                1); # "do_seq" put in sequence number
      } ];


#------------------------------------------------------------------------------

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
  ### Sync new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # spec says must initialize or behaviour undefined
  my ($major, $minor) = $X->req('SyncInitialize',
                                CLIENT_MAJOR_VERSION,
                                CLIENT_MINOR_VERSION);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'Counter',  # 0
                            'Alarm',    # 1

                            # Fence new in 3.1
                            (($major <=> 3 || $minor <=> 1) > 0
                             ? ('Fence') : ()));   # 2

  return bless { major => $major,
                 minor => $minor,
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

1;
__END__

=for stopwords SYNC XID Ryde

=head1 NAME

X11::Protocol::Ext::SYNC - client synchronization

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('SYNC')
   or print "SYNC extension not available";

=head1 DESCRIPTION

The SYNC extension adds

=over

=item *

64-bit client controlled and system counters.

=item *

Alarms to wait for counter values.

=item *

Fences triggered by completion of screen rendering.

=back

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('SYNC');

=over

=item C<($server_major, $server_minor) = $X-E<gt>SyncInitialize ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

This request is done automatically by C<init_extension()>.  The current code
supports up to SYNC version 3.1.

=item C<@infos = $X-E<gt>SyncListSystemCounters ($client_major, $client_minor)>

Each returned info is an arrayref

    [ $counter, $resolution, $name ]

C<$resolution> is an estimate of the resolution of the counter.  For example
if resolution is 10 then counter values less than 10 apart might end up
being treated as the same time.

A "SERVERTIME" system counter always exists and is the server timestamp
counter in milliseconds.

=item C<$X-E<gt>SyncCreateCounter ($counter, $value)>

Create C<$counter> (a new XID) as a counter with initial value C<$value>.

=item C<$X-E<gt>SyncSetCounter ($counter, $value)>

=item C<$X-E<gt>SyncChangeCounter ($counter, $add)>

Change C<$counter> (an XID) to the given C<$value>, or by adding the given
C<$add> amount.

System counters cannot be changed.  For other counters the change will
generate C<CounterNotify> events and unblock any clients if the new value if
what they're waiting for.

=item C<$value = $X-E<gt>SyncQueryCounter ($counter)>

Return the current value of C<$counter> (an XID).

=item C<$X-E<gt>SyncDestroyCounter ($counter)>

Destroy C<$counter> (an XID).

Any clients waiting on C<$counter> are sent a C<SyncCounterNotify> with the
C<destroyed> field true.  Any alarms on C<$counter> become state "Inactive".
System counters cannot be destroyed, and a client's counters are destroyed
automatically on connection close.

=item C<$X-E<gt>SyncAwait ($counter)>

Block the current client until one of its requested triggers is satisfied.

=back

=head2 Alarm Requests

=over

=item C<$X-E<gt>SyncCreateAlarm ($alarm, key =E<gt> $value, ...)>

Create C<$alarm> (a new XID) as an alarm ...

=item C<$X-E<gt>SyncChangeAlarm ($alarm, key =E<gt> $value, ...)>

Change C<$alarm> (an XID) ...

=item C<@something = $X-E<gt>SyncQueryAlarm ($alarm)>

Return the current parameters of C<$alarm> (an XID) ...

=item C<$X-E<gt>SyncDestroyAlarm ($alarm)>

Destroy C<$alarm> (an XID).

=item C<$X-E<gt>SyncSetPriority ($xid, $priority)>

=item C<$priority = $X-E<gt>SyncGetPriority ($xid)>

Get or set a client's scheduling priority level.  C<$xid> is any XID
belonging to the desired client, or "None" for the current client.
C<$priority> is a signed 32-bit integer and bigger numbers are higher
priority.

Setting a client to high priority may help it do smooth animations etc,
though a high priority client should be careful that it doesn't flood the
server with requests which end up starving other clients.

=back

=head1 SYNC 3.1

=over

=item C<$X-E<gt>SyncCreateFence ($drawable, $fence, $initially_triggered)>

Create C<$fence> (a new XID) as a fence on the screen of C<$drawable>.

=item C<$X-E<gt>SyncTriggerFence ($fence)>

Ask the server to set C<$fence> (an XID) to triggered state when all drawing
requests on the screen of C<$fence> have completed (for both the current
client and other clients).  If C<$fence> is already triggered then do
nothing.

=item C<$X-E<gt>SyncResetFence ($fence)>

Reset C<$fence> (an XID) from triggered to untriggered state.  An error
results if C<$fence> is not currently in triggered state.

=item C<$X-E<gt>SyncDestroyFence ($fence)>

Destroy C<$fence> (an XID).

=item C<$triggered = $X-E<gt>SyncQueryFence ($fence)>

Get the current triggered state of C<$fence> (an XID).  The return is 0 if
untriggered or 1 if triggered.

=item C<$X-E<gt>SyncAwaitFence ($fence, ...)>

Block the processing of requests from the current client until one or more
of the given C<$fence> list (XIDs) is in triggered state.  If once of the
fences is currently triggered then there's no block, request processing
resumes immediately.

=back

=head1 EVENTS

Each event has the usual fields

    name             "SyncCounterNotify" etc
    synthetic        true if from a SendEvent
    code             integer opcode
    sequence_number  integer

plus event-specific fields as described below.

=over

=item C<SyncCounterNotify>

A C<SyncCounterNotify> is generated when ...

The event-specific fields are

    time           integer, server timestamp
    wait_value     INT64
    counter_value  INT64
    destroyed      bool, 0 or 1
    count          integer, how many more SyncCounterNotify

=item C<SyncAlarmNotify>

A C<SyncAlarmNotify> is generated when ...

The event-specific fields are

    time           integer, server timestamp
    alarm_value    INT64
    counter_value  INT64
    state          Active, Inactive, or Destroyed

=back

=head1 ERRORS

Error types "Counter", "Alarm" and "Fence" are respectively a bad
C<$counter>, C<$alarm> or C<$fence> resource XID in a request.
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
