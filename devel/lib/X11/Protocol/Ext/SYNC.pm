# Copyright 2011 Kevin Ryde

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
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 11;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


#
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
# /usr/include/X11/extensions/xtestconst.h

### SYNC.pm loads

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 1;

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
      my ($ncounters) = unpack 'x8L', $data;
      my @ret;
      my $pos = 32;
      foreach (1 .. $ncounters) {
        my ($counter, $res_hi, $res_lo, $name_len)
          = unpack 'LLLS', substr($data,$pos,10);
        $pos += 10;
        my $name = substr ($data, $pos, $name_len);
        $pos += $name_len;
        push @ret, [$counter, $res_hi, $res_lo, $name];
      }
    }],

   ['SyncCreateCounter',  # 2
    \&_request_card32s, # my ($X, $counter, $initial_hi, $initial_lo)
   ],

   ['SyncSetCounter',  # 3
    \&_request_card32s, # my ($X, $counter, $value_hi, $value_lo)
   ],

   ['SyncChangeCounter',  # 4
    \&_request_card32s, # my ($X, $counter, $value_hi, $value_lo)
   ],

   ['SyncQueryCounter',  # 5
    \&_request_card32s, # ($X, $counter)
    sub {
      my ($X, $data) = @_;
      return unpack 'lL', $data;
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

  ];

my $SyncCounterNotify_event = [ 'xCxxLlLlLLSCx',
                                ['kind','XFixesSelectionNotifySubtype'],
                                'counter',
                                'wait_value_hi',
                                'wait_value_lo',
                                'counter_value_hi',
                                'counter_value_lo',
                                'time',
                                'count',
                                'destroyed',
                              ];

my $SyncAlarmNotify_event = [ 'xCxxLlLlLLCx3',
                              ['kind','XFixesSelectionNotifySubtype'],
                              'alarm',
                              'counter_value_hi',
                              'counter_value_lo',
                              'alarm_value_hi',
                              'alarm_value_lo',
                              'time',
                              'state',
                            ];

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

  # Errors
  _ext_const_error_install ($X, $error_num, 'Counter', 'Alarm');


  # Any need to negotiate the version before using?
  #  my ($major, $minor) = $X->req('SyncQueryVersion',
  #                                              CLIENT_MAJOR_VERSION,
  #                                              CLIENT_MINOR_VERSION);
  # if ($major != 1) {
  #   carp "Unrecognised Sync major version, got $major want 1";
  #   return 0;
  # }
  return bless {
                # major => $major,
                # minor => $minor,
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

The SYNC extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('SYNC');

=over

=item C<($server_major, $server_minor) = $X-E<gt>SyncInitialize ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

The current code supports up to 3.0 and the intention would be to
automatically negotiate in C<init_extension> if necessary.

=back

=head1 ERRORS

Error types "Counter" and "Alarm" are a bad C<$counter> or C<$alarm>
resource XID in a request.

=head1 SEE ALSO

L<X11::Protocol>

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
