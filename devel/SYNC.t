#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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




use lib 'devel/lib';
$ENV{'DISPLAY'} ||= ":0";







BEGIN { require 5 }
use strict;
use X11::Protocol;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 119)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

my ($major_opcode, $first_event, $first_error)
  = $X->QueryExtension('SYNC');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no SYNC on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("SYNC extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('SYNC')) {
  die "QueryExtension says SYNC avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# errors

{
  ok ($X->num('Error','Counter'),    $first_error);
  ok ($X->num('Error','Alarm'),      $first_error+1);
  ok ($X->num('Error',$first_error),   $first_error);
  ok ($X->num('Error',$first_error+1), $first_error+1);
  ok ($X->interp('Error',$first_error),   'Counter');
  ok ($X->interp('Error',$first_error+1), 'Alarm');
  {
    local $X->{'do_interp'} = 0;
    ok ($X->interp('Error',$first_error), $first_error);
    ok ($X->interp('Error',$first_error+1), $first_error+1);
  }
}


#------------------------------------------------------------------------------
# SyncTestType enum

ok ($X->num('SyncTestType','PositiveTransition'),   0);
ok ($X->num('SyncTestType','NegativeTransition'),   1);
ok ($X->num('SyncTestType','PositiveComparison'),   2);
ok ($X->num('SyncTestType','NegativeComparison'),   3);

ok ($X->interp('SyncTestType',0), 'PositiveTransition');
ok ($X->interp('SyncTestType',1), 'NegativeTransition');
ok ($X->interp('SyncTestType',2), 'PositiveComparison');
ok ($X->interp('SyncTestType',3), 'NegativeComparison');


#------------------------------------------------------------------------------
# SyncValueType enum

ok ($X->num('SyncValueType','Absolute'),   0);
ok ($X->num('SyncValueType','Relative'),   1);

ok ($X->interp('SyncValueType',0), 'Absolute');
ok ($X->interp('SyncValueType',1), 'Relative');


#------------------------------------------------------------------------------
# SyncCreateCounter / SyncDestroyCounter

sub big_leftshift {
  my ($b, $n) = @_;
  require Math::BigInt;
  $b = Math::BigInt->new($b);
  $b <<= $n;
  return $b;
}
{
  my $counter = $X->new_rsrc;
  $X->SyncCreateCounter ($counter, 123);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncCreateCounter');

  my $value = $X->SyncQueryCounter ($counter);
  ok ($value, 123);

  foreach my $value (0, 1, -1,
                     big_leftshift(1,32),
                     - big_leftshift(1,32),
                     big_leftshift(1,63) - 1,
                     - big_leftshift(1,63),
                    ) {
    $X->SyncSetCounter ($counter, $value);
    my $got_value = $X->SyncQueryCounter ($counter);
    ok ($got_value == $value, 1,
        "counter $value got $got_value");
  }

  $X->SyncDestroyCounter ($counter);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncDestroyCounter');
}

#------------------------------------------------------------------------------
# SyncCreateAlarm / SyncDestroyAlarm

{
  my $alarm = $X->new_rsrc;
  $X->SyncCreateAlarm ($alarm);

  $X->SyncDestroyAlarm ($alarm);
  $X->QueryPointer($X->root); # sync
  ok (1, 1, 'SyncCreateAlarm / SyncDestroyAlarm');
}

#------------------------------------------------------------------------------
# alarm parameters

{
  my $counter = $X->new_rsrc;
  $X->SyncCreateCounter ($counter, 123);
  my $alarm = $X->new_rsrc;
  $X->SyncCreateAlarm ($alarm, value => -123);

  { my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'value'} == -123, 1);
    ok ($h{'test_type'}, 'PositiveComparison');
    ok ($h{'value_type'}, 'Absolute');
    ok ($h{'delta'}, 1);
    ok ($h{'events'}, 1);
    ok ($h{'state'}, 'Inactive');
  }

  {
    $X->SyncChangeAlarm ($alarm,
                         test_type => 'NegativeComparison',
                         delta => -1);
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'test_type'}, 'NegativeComparison');
    ok ($h{'delta'} == -1, 1);
  }
  {
    $X->SyncChangeAlarm ($alarm,
                         counter    => $counter,
                         value_type => 'Relative');
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'counter'}, $counter);
  }
  {
    $X->SyncChangeAlarm ($alarm, value_type => 'Absolute');
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'value_type'}, 'Absolute');
    ok ($h{'events'}, 1);
  }
  {
    $X->SyncChangeAlarm ($alarm, events => 0);
    my %h = $X->SyncQueryAlarm ($alarm);
    ok ($h{'events'}, 0);
  }

  $X->SyncDestroyAlarm ($alarm);
  $X->SyncDestroyCounter ($counter);
  $X->QueryPointer($X->root); # sync
}

#------------------------------------------------------------------------------
# SyncCounterNotify event

{
  my $aref = $X->{'ext'}->{'SYNC'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, at least in 0.56
                   # name        => "SyncCounterNotify",
                   synthetic     => 1,
                   code          => $event_num,
                   sequence_number => 100,

                   counter       => 101,
                   wait_value    => -123,
                   counter_value => -256,
                   time          => $time,
                   count         => 6,
                   destroyed     => 1,
                  );
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'SyncCounterNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});

      ok ($output{'counter'},      $input{'counter'});
      ok ($output{'wait_value'},   $input{'wait_value'});
      ok ($output{'counter_value'},$input{'counter_value'});
      ok ($output{'time'},         $input{'time'});
      ok ($output{'count'},        $input{'count'});
      ok ($output{'destroyed'},    $input{'destroyed'});
    }
  }
}

#------------------------------------------------------------------------------
# SyncAlarmNotify event

{
  my $aref = $X->{'ext'}->{'SYNC'};
  my ($request_num, $event_num, $error_num, $obj) = @$aref;
  my $alarm_event_num = $event_num + 1;

  my $more;
  foreach $more (0, 1) {
    my $time;
    foreach $time ('CurrentTime', 103) {
      my %input = (# can't use "name" on an extension event, at least in 0.56
                   # name          => "SyncAlarmNotify",
                   synthetic       => 1,
                   code            => $alarm_event_num,
                   sequence_number => 100,

                   alarm         => 101,
                   counter_value => -123,
                   alarm_value   => -256,
                   time          => $time,
                   state         => 'Destroyed',
                  );
      my $data = $X->pack_event(%input);
      ok (length($data), 32);

      my %output = $X->unpack_event($data);
      ### %output

      ok ($output{'code'},      $input{'code'});
      ok ($output{'name'},      'SyncAlarmNotify');
      ok ($output{'synthetic'}, $input{'synthetic'});

      ok ($output{'alarm'},         $input{'alarm'});
      ok ($output{'counter_value'}, $input{'counter_value'});
      ok ($output{'alarm_value'},   $input{'alarm_value'});
      ok ($output{'time'},          $input{'time'});
      ok ($output{'state'},         $input{'state'});
    }
  }
}


#------------------------------------------------------------------------------

exit 0;
