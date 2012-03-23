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
$VERSION = 18;
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
#    Xlib
# /usr/share/xcb/sync.xml
#    xcb
#
# /so/xorg/xorg-server-1.10.0/Xext/sync.c
#    server source
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#
# X11R7.6 SYNC 3.0


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 3;
use constant CLIENT_MINOR_VERSION => 1;

#------------------------------------------------------------------------------
# 64-bits

# -2^64 + $hi*2^32 + $lo
# = 2^32 * (-2^32 + $hi) + $lo
#
# -2^64 + $hi*2^32 + $lo
# = -2^64 + ($hi-2^31+2^31)*2^32 + $lo
# = -2^64 + 2^63 + ($hi-2^31)*2^32 + $lo
# = -2^63 + ($hi-2^31)*2^32 + $lo
#
# Crib note: "<<" shift operator turns a negative into a positive, so have
# to shift $hi as positive then adjust.

{
  my $uv = ~0;
  my $bits = 0;
  while ($uv && $bits < 64) {
    $uv >>= 1;
    $bits++;
  }

  if ($bits >= 64) {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub _hilo_to_int64 {
  my ($hi,$lo) = @_;
  ### _hilo_to_int64(): "$hi $lo"
  if ($hi & 0x8000_0000) {
    $hi -= 0x8000_0000;
    $lo += -(1<<63);
  }
  ### $hi
  ### $lo
  ### hi shift: $hi<<1
  ### result: ($hi << 32) + $lo
  return ($hi << 32) + $lo;
}
1;
HERE
  } else {
     eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use Math::BigInt;
sub _hilo_to_int64 {
  my ($hi,$lo) = @_;
  my $sv = ($hi << 32) + $lo;
  my $sv = Math::BigInt->new($hi)->blsft(32)->badd($lo);
  if ($hi & 0x8000_0000) {
    $sv = -$sv;
  }
  return $sv;
}
1;
HERE
  }
}

sub _int64_to_hilo {
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
          = unpack 'xxxxLLLLLLSCx', $data;
        return
          (@_,
           counter       => $counter,
           wait_value    => _hilo_to_int64($wait_value_hi,$wait_value_lo),
           counter_value => _hilo_to_int64($counter_value_hi,$counter_value_lo),
           time          => _interp_time($time),
           count         => $count,
           destroyed     => $destroyed);
      },
      sub {
        my ($X, %h) = @_;
        return (pack('xxxxLLLLLLSCx',
                     $h{'counter'},
                     _int64_to_hilo($h{'wait_value'}),
                     _int64_to_hilo($h{'counter_value'}),
                     _num_time($h{'time'}),
                     $h{'count'},
                     $h{'destroyed'}),
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
          = unpack 'xxxxLLLLLLCx3', $data;
        return
          (@_,
           alarm         => $alarm,
           counter_value => _hilo_to_int64($counter_value_hi,$counter_value_lo),
           alarm_value   => _hilo_to_int64($alarm_value_hi,$alarm_value_lo),
           time          => _interp_time($time),
           state         => $X->interp('SyncAlarmState',$state));
      },
      sub {
        my ($X, %h) = @_;
        return (pack('xxxxLLLLLLCx3',
                     $h{'alarm'},
                     _int64_to_hilo($h{'counter_value'}),
                     _int64_to_hilo($h{'alarm_value'}),
                     _num_time($h{'time'}),
                     $X->num('SyncAlarmState',$h{'state'})),
                1); # "do_seq" put in sequence number
      } ];


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
                     _hilo_to_int64($resolution_hi,$resolution_lo),
                     $name ];
      }
      return @ret;
    }],

   ['SyncCreateCounter',  # 2
    sub {
      my ($X, $counter, $initial) = @_;
      return pack 'L3', $counter, _int64_to_hilo($initial);
    },
   ],

   ['SyncSetCounter',  # 3
    sub {
      my ($X, $counter, $value) = @_;
      return pack 'L3', $counter, _int64_to_hilo($value);
    },
   ],

   ['SyncChangeCounter',  # 4
    sub {
      my ($X, $counter, $value) = @_;
      return pack 'L3', $counter, _int64_to_hilo($value);
    },
   ],

   ['SyncQueryCounter',  # 5
    \&_request_card32s, # ($X, $counter)
    sub {
      my ($X, $data) = @_;
      return _hilo_to_int64 (unpack 'x8LL', $data);
    },
   ],

   ['SyncDestroyCounter',  # 6
    \&_request_card32s, # ($X, $counter)
   ],

   ['SyncAwait',  # 7
    \&_request_empty,
   ],

   ['SyncCreateAlarm',  # 8
    \&_request_alarm_parameters,
   ],

   ['SyncChangeAlarm',  # 9
    \&_request_alarm_parameters,
   ],

   ['SyncQueryAlarm',  # 10
    \&_request_card32s, # ($X, $alarm)
    sub {
      my ($X, $data) = @_;
      ### SyncQueryAlarm() reply ...
      use Data::HexDump::XXD;
      print scalar(Data::HexDump::XXD::xxd($data));
      print "\n";

      my ($counter, $value_type, $value_hi,$value_lo,
          $test_type, $delta_hi,$delta_lo,
          $events, $state)
        = unpack 'x8L7CC', $data;

      return (counter    => $counter,
              value      => _hilo_to_int64($value_hi,$value_lo),
              test_type  => $X->interp('SyncTestType',$test_type),
              value_type => $X->interp('SyncValueType',$value_type),
              delta      => _hilo_to_int64($delta_hi,$delta_lo),
              events     => $events,
              state      => $X->interp('SyncAlarmState',$state));
    } ],

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
      my ($X, $fence, $drawable, $initially_triggered) = @_;
      return pack 'LLCxxx', $drawable, $fence, $initially_triggered;
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
    sub {
      my ($X, $data) = @_;
      return unpack 'x8C', $data;
    } ],

   ['SyncAwaitFence',  # 19
    \&_request_card32s, # ($X, $fence,...)
   ],
  ];

{
  my @keys = ('counter',
              'value_type',
              'value',
              'test_type',
              'delta',
              'events');
  my %key_to_conversion = (value => \&_int64_to_hilo,
                           delta => \&_int64_to_hilo);
  my %key_to_interp = (value_type => 'SyncValueType',
                       test_type  => 'SyncTestType');

  sub _request_alarm_parameters {
    my ($X, $alarm, %h) = @_;
    my $mask = 0;
    my @args;
    foreach my $i (0 .. $#keys) {
      my $key = $keys[$i];
      next unless exists $h{$key};;

      my $arg = delete $h{$key};
      $mask |= (1 << $i);

      if (my $conversion = $key_to_conversion{$key}) {
        push @args, &$conversion($arg);
      } else {
        if (my $interp = $key_to_interp{$key}) {
          $arg = $X->num($interp,$arg);
        }
        push @args, $arg;
      }
    }
    if (%h) {
      croak "Unrecognised alarm parameter(s): ",join(',',keys %h);
    }
    ### $mask
    ### @args
    return pack 'L*', $alarm, $mask, @args;
  }
}


#------------------------------------------------------------------------------

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### Sync new()

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Events
  $X->{'ext_const'}{'Events'}[$event_num] = 'SyncCounterNotify';
  $X->{'ext_events'}[$event_num] = $SyncCounterNotify_event;
  $event_num++;
  $X->{'ext_const'}{'Events'}[$event_num] = 'SyncAlarmNotify';
  $X->{'ext_events'}[$event_num] = $SyncAlarmNotify_event;

  # spec says must initialize or behaviour undefined
  my ($major, $minor) = $X->req('SyncInitialize',
                                CLIENT_MAJOR_VERSION,
                                CLIENT_MINOR_VERSION);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'Counter',  # 0
                            'Alarm',    # 1

                            # Fence new in 3.1
                            (($major <=> 3 || $minor <=> 1) >= 0
                             ? ('Fence') : ()));   # 2

  return bless { major => $major,
                 minor => $minor,
               }, $class;
}


#------------------------------------------------------------------------------
# generic

sub _num_time {
  my ($time) = @_;
  if (defined $time && $time eq 'CurrentTime') {
    return 0;
  } else {
    return $time;
  }
}
sub _interp_time {
  my ($time) = @_;
  if ($time == 0) {
    return 'CurrentTime';
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

64-bit counters either client controlled or server controlled.

=item *

Alarms to wait for counter values.

=item *

Fences triggered by completion of screen rendering (new in SYNC 3.1).

=back

Counters and alarms allow different clients to synchronize their actions.
One client can create a counter and increment it, and other clients can
either wait on a target counter value, or create an alarm to receive events
for a target value.

Client counters change by explicit C<SyncChangeCounter()> or
C<SyncSetCounter()> requests.  What the value means, when it changes and by
how much is entirely up to client programs.

Pre-defined system counters are controlled by the server.  "SERVERTIME"
counter is the server timestamp (the C<time> field of events etc) in
milliseconds.  There might be other counters too, for example the X.org
server has "IDLETIME" in milliseconds.

Counter values are INT64 signed 64-bit values, so -2^63 to 2^63-1 inclusive.
On a 64-bit Perl values are returned as plain integers, or on a 32-bit Perl
they're returned as C<Math::BigInt> objects.

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('SYNC');

=over

=item C<($server_major, $server_minor) = $X-E<gt>SyncInitialize ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

This negotiation is done automatically by C<init_extension()>.  The current
code supports up to SYNC version 3.1.

=item C<@infos = $X-E<gt>SyncListSystemCounters ($client_major, $client_minor)>

Each returned info is an arrayref

    [ $counter, $resolution, $name ]

C<$counter> is the XID (integer) of the counter.

C<$resolution> is an estimate of the resolution of the counter.  For example
if resolution is 10 then it might increment by 10 or thereabouts each time.

C<$name> is a string name of the counter.

The name "SERVERTIME" is the server timestamp counter in milliseconds as
appearing in the C<time> field of events etc.

See F<examples/sync-info.pl> in the X11-Protocol-Other sources for a
complete program listing the system counters.

=item C<$X-E<gt>SyncCreateCounter ($counter, $value)>

Create C<$counter> (a new XID) as a counter with initial value C<$value>.

=item C<$X-E<gt>SyncSetCounter ($counter, $value)>

=item C<$X-E<gt>SyncChangeCounter ($counter, $add)>

Change C<$counter> (an XID) to the given C<$value>, or by adding the given
C<$add> amount.

System counters cannot be changed by clients.

=item C<$value = $X-E<gt>SyncQueryCounter ($counter)>

Return the current value of C<$counter> (an XID).

=item C<$X-E<gt>SyncDestroyCounter ($counter)>

Destroy C<$counter> (an XID).

Any clients waiting on C<$counter> are sent a C<SyncCounterNotify> with the
C<destroyed> field true.  Any alarms on C<$counter> become state "Inactive".
System counters cannot be destroyed, and a client's counters are destroyed
automatically on connection close.

=back

=head2 Alarms and Waiting

=over

=item C<$X-E<gt>SyncAwait ([$key=E<gt>$value,...],...)>

Block the current client until one of the given counter conditions is
satisfied.  Each condition is an arrayref of key/value pairs

    counter           the target counter (integer XID)
    value_type        "Absolute" or "Relative"
    value             target value (64-bit signed integer)
    test_type         "PositiveTransition", "NegativeTransition",
                      "PositiveComparison" or "NegativeComparison"
    event_threshold   possible difference (64-bit signed integer)

For example to wait on two counters

    $X->SyncAwait ([ counter    => $c1,
                     value_type => "Absolute",
                     value      => 1000,
                     test_type  => "PositiveComparison",
                     event_threshold => 100 ],
                   [ counter    => $c2,
                     value_type => "Absolute",
                     value      => 500,
                     test_type  => "NegativeTransition",
                     event_threshold => 100 ]);

C<test_type> is satisified by

    "PositiveComparison"    whenever counter >= value
    "NegativeComparison"    whenever counter <= value
    "PositiveTransition"    change from counter<value to counter>=value
    "NegativeTransition"    change from counter>value to counter<=value

C<value_type> is how C<value> is interpreted

    "Absolute"      target value is as given
    "Relative"      target value is counter current value + given value

For "Absolute" the C<counter> can be "None" and that's considered satisfied
immediately.  For "Relative" each C<counter> must be a valid counter.

If a counter is destroyed during C<SyncAwait()> then the wait finishes and a
C<CounterNotify> event with the C<destroyed> flag is generated.

When C<SyncAwait()> finishes the C<event_threshold> can generate
C<CounterNotify> events for the client.  The difference

    diff = counter - target value

is compared to the given C<event_threshold>

    if diff >= event_threshold for a Positive
    or diff <= event_threshold for a Negative
    then send CounterNotify

This is designed to alert the client that a counter has run on by more than
expected (perhaps due to lag, perhaps by a jump).

=item C<$X-E<gt>SyncCreateAlarm ($alarm, $key=E<gt>$value, ...)>

=item C<$X-E<gt>SyncChangeAlarm ($alarm, $key=E<gt>$value, ...)>

Create C<$alarm> (a new XID) as an alarm, or change the parameters of an
existing C<$alarm>.  The key/value parameters are similar to C<SyncAwait()>
above,

    counter       the target counter (integer XID)
    value_type    "Absolute" or "Relative"
    value         target value (64-bit signed integer)
    test_type     "PositiveTransition", "NegativeTransition",
                  "PositiveComparison" or "NegativeComparison"
    delta         step target value (64-bit signed, default 1)
    events        boolean (default true)

All the parameters have defaults, so an alarm can be created with no counter
etc just by

    my $alarm = $X->new_rsrc;
    $X->SyncCreateAlarm ($alarm);

C<counter> "None" or omitted makes the alarm "Inactive".

C<delta> is added to C<value> when the alarm is satisfied, to make it
unsatisfied again (repeatedly added if necessary).  For example the default
C<delta> of 1 means C<value> has 1 added until unsatisfied again, which
means set to counter+1.

If adding C<delta> this way would overflow an INT64, or if it's 0 for a
"Comparison" test (and thus no amount of adding will unsatisfy), then the
C<value> is unchanged and the alarm set "Inactive" instead.

C<delta> must be in the right direction for the C<test_type>, or a C<Match>
error results.

    "Positive"     must have delta >= 0
    "Negative"     must have delta <= 0

If C<events> is true then when the alarm is satisfied an C<AlarmNotify>
event is generated.  If the C<delta> caused the alarm to become "Inactive"
then the C<state> field in the event shows that.

The C<events> flag is a per-client setting.  Each client can individually
select or deselect events from an alarm with C<SyncChangeAlarm()>,

    $X->SyncChangeAlarm ($alarm, events => $bool);

The SYNC specification allows C<SyncChangeAlarm()> to apply the settings in
a server-dependent order and if an error results some might be updated and
others left unchanged.

generates an error (bad type, bad counter, etc) it might
have changes some of the attributes before generating the error.

=item C<@list = $X-E<gt>SyncQueryAlarm ($alarm)>

Return the current parameters of C<$alarm> (integer XID) in the form of a
key/value list like C<SyncCreateAlarm()> above.

In the X.org server circa 1.10, if C<value_type> is set to "Relative" it
reads back as "Absolute" and a C<value> which is the target
counter+relative_value.  Not sure what the spec says about this.

=item C<$X-E<gt>SyncDestroyAlarm ($alarm)>

Destroy C<$alarm> (an XID).

=item C<$X-E<gt>SyncSetPriority ($xid, $priority)>

=item C<$priority = $X-E<gt>SyncGetPriority ($xid)>

Get or set a client's scheduling priority level.  C<$xid> is any XID
belonging to the desired client, or "None" for the current client.
C<$priority> is a signed 32-bit integer and bigger numbers are higher
priority.  The default priority is 0.

Setting a client to high priority may help it do smooth animations etc.
A high priority client might have to be careful that it doesn't flood the
server with requests and end up starving other clients.

=back

=head2 SYNC 3.1

=over

=item C<$X-E<gt>SyncCreateFence ($drawable, $fence, $initially_triggered)>

Create C<$fence> (a new XID) as a fence on the screen of C<$drawable>.

=item C<$X-E<gt>SyncTriggerFence ($fence)>

Ask the server to set C<$fence> (XID) to triggered state when all drawing
requests currently in progress on the screen of C<$fence> have completed
(for both the current client and other clients).  If C<$fence> is already
triggered then do nothing.

If a simple server does all drawing directly to video memory with no queuing
or rendering pipeline then C<$fence> will be triggered immediately.  But if
the server or graphics card has some sort or rendering pipeline or queue
then C<$fence> is triggered only once the drawing requests issued up to now
have reached the actual screen.

=item C<$X-E<gt>SyncResetFence ($fence)>

Reset C<$fence> (an XID) from triggered to untriggered state.  A C<Match>
error results if C<$fence> is not currently in triggered state.

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
