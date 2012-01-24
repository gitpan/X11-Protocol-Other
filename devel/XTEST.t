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

my $test_count = (tests => 12)[1];
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
  = $X->QueryExtension('XTEST');
{
  if (! defined $major_opcode) {
    foreach (1 .. $test_count) {
      skip ('QueryExtension() no XTEST on the server', 1, 1);
    }
    exit 0;
  }
  MyTestHelpers::diag ("XTEST extension opcode=$major_opcode event=$first_event error=$first_error");
}

if (! $X->init_extension ('XTEST')) {
  die "QueryExtension says XTEST avaiable, but init_extension() failed";
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XTestGetVersion()

{
  my $client_major = 1;
  my $client_minor = 1;
  my @ret = $X->XTestGetVersion ($client_major, $client_minor);
  MyTestHelpers::diag ("server XTEST version ", join('.',@ret));
  ok (scalar(@ret), 2);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XTestCompareCursor()

{
  my $cursor_glyph = 4;

  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor");

  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # font
                         $cursor_font,  # mask font
                         $cursor_glyph,   # glyph number
                         $cursor_glyph+1, # and its mask
                         0,0,0,                    # foreground, black
                         0xFFFF, 0xFFFF, 0xFFFF);  # background, white

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->{'root'},     # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    0,0,              # x,y
                    1,1,              # width,height
                    0,                # border
                    cursor => $cursor);

  ok ($X->XTestCompareCursor ($window, $cursor),
      1);
  ok ($X->XTestCompareCursor ($window, "None"),
      0);
  ok ($X->XTestCompareCursor ($window, 0),
      0);
  $X->XTestCompareCursor ($window, "CurrentCursor");
  $X->XTestCompareCursor ($window, 1);

  $X->ChangeWindowAttributes
    ($window,
     cursor => 'None');

  ok ($X->XTestCompareCursor ($window, $cursor),
      0);
  ok ($X->XTestCompareCursor ($window, "None"),
      1);
  ok ($X->XTestCompareCursor ($window, 0),
      1);


  $X->CloseFont ($cursor_font);
  $X->DestroyWindow ($window);
  $X->FreeCursor ($cursor);
}
$X->QueryPointer($X->root); # sync


#------------------------------------------------------------------------------
# XTestGrabControl()

{
  my $X2 = X11::Protocol->new ($display);

  foreach my $impervious (undef, 1, 0, 1, 0) {
    ### $impervious
    if (defined $impervious) {
      $X->XTestGrabControl ($impervious);
    }
    my $want_impervious = ($impervious ? 1 : 0);
    $X->QueryPointer($X->root); # flush and sync


    $X2->GrabServer;
    $X2->QueryPointer($X->root); # sync

    my $reply;
    my $seq = $X->send('QueryPointer',$X->root);
    $X->add_reply ($seq, \$reply);
    $X->flush;

    $X2->QueryPointer($X->root); # sync

    while (fh_readable ($X->{'connection'}->fh)) {
      ### X handle_input ...
      $X->handle_input;
    }
    ### $reply
    my $got_impervious = (defined $reply ? 1 : 0);

    $X2->UngrabServer;
    $X2->QueryPointer($X->root); # sync
    $X->QueryPointer($X->root); # sync
    ### $reply

    ok ($got_impervious,
        $want_impervious,
        'impervious');
  }
}

sub fh_readable {
  my ($fh) = @_;
  require IO::Select;
  my $s = IO::Select->new;
  $s->add($fh);
  my @ready = $s->can_read(1);
  return scalar(@ready);
}



# #------------------------------------------------------------------------------
# # XTestNotify event
#
# {
#   my $aref = $X->{'ext'}->{'XTEST'};
#   my ($request_num, $event_num, $error_num, $obj) = @$aref;
#
#   my $more;
#   foreach $more (0, 1) {
#     my $time;
#     foreach $time ('CurrentTime', 103) {
#       my %input = (# can't use "name" on an extension event, at least in 0.56
#                    # name      => "XTestNotify",
#                    synthetic => 1,
#                    code      => $event_num,
#                    sequence_number => 100,
#                    damage   => 101,
#                    drawable => 102,
#                    level    => 'BoundingBox',
#                    more     => $more,
#                    time     => $time,
#                    area     => [-104,-105,106,107],
#                    geometry => [108,109,110,111]);
#       my $data = $X->pack_event(%input);
#       ok (length($data), 32);
#
#       my %output = $X->unpack_event($data);
#       ### %output
#
#       ok ($output{'code'},      $input{'code'});
#       ok ($output{'name'},      'XTestNotify');
#       ok ($output{'synthetic'}, $input{'synthetic'});
#       ok ($output{'damage'},    $input{'damage'});
#       ok ($output{'drawable'},  $input{'drawable'});
#       ok ($output{'level'},     $input{'level'});
#       ok ($output{'more'},      $input{'more'});
#       ok ($output{'time'},      $input{'time'});
#
#       ok ($output{'area'}->[0], $input{'area'}->[0]);
#       ok ($output{'area'}->[1], $input{'area'}->[1]);
#       ok ($output{'area'}->[2], $input{'area'}->[2]);
#       ok ($output{'area'}->[3], $input{'area'}->[3]);
#
#       ok ($output{'geometry'}->[0], $input{'geometry'}->[0]);
#       ok ($output{'geometry'}->[1], $input{'geometry'}->[1]);
#       ok ($output{'geometry'}->[2], $input{'geometry'}->[2]);
#       ok ($output{'geometry'}->[3], $input{'geometry'}->[3]);
#     }
#   }
# }


#------------------------------------------------------------------------------

exit 0;
