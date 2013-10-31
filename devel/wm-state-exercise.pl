#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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

use strict;
use FindBin;
use File::Spec;
my $script = File::Spec->catfile($FindBin::Bin,$FindBin::Script);
use X11::Protocol;
use X11::AtomConstants;
use X11::Protocol::WM;

if (@ARGV) {
  open STDOUT, '>>', '/tmp/wm-state-exercise.out' or die;
  open STDERR, '>>&', \*STDOUT;
  $| = 1;
  print "\n\n\n-------------------------------------------------------------\n";

  my $wm = $ARGV[0];
  my $pid = fork();
  if ($pid) {
    # parent
    sleep 5;
  } else {
    exec $wm or die $!;
  }

  my $display = $ENV{"DISPLAY"};
  my $window = $ENV{"WINDOWID"};
  my $X = X11::Protocol->new($display);
  my $root = $X->root;
  print "\n$wm $display window=$window\n";
  # system("xprop -root >>/tmp/wm-state-exercise.out");

  my @supported_atoms;
  my %supported_atoms;
  {
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($root,
                         $X->atom('_NET_SUPPORTED'),   # property
                         X11::AtomConstants::ATOM(),  # type
                         0,    # offset
                         999,  # length limit
                         0);   # delete
    if ($format == 32) {
      @supported_atoms = unpack('L*', $value);
      foreach my $atom (@supported_atoms) {
        $supported_atoms{$atom} = 1;
      }
    } else {
      print "no _NET_SUPPORTED\n";
    }
  }
  print "supported count ",scalar(@supported_atoms),"\n";
  print "supported: ",join(', ',map{$X->atom_name($_)} @supported_atoms),"\n";

  # _NET_WM_STATE_HIDDEN
  foreach my $state (qw(
                        _NET_WM_STATE_BELOW
                        _NET_WM_STATE_ABOVE
                        _NET_WM_STATE_MODAL
                        _NET_WM_STATE_STICKY
                        _NET_WM_STATE_MAXIMIZED_VERT
                        _NET_WM_STATE_MAXIMIZED_HORZ
                        _NET_WM_STATE_SHADED
                        _NET_WM_STATE_SKIP_TASKBAR
                        _NET_WM_STATE_SKIP_PAGER
                        _NET_WM_STATE_FULLSCREEN
                        _NET_WM_STATE_DEMANDS_ATTENTION
                       )) {
    print "$state\n";
    my $state_atom = $X->atom($state);
    if (! $supported_atoms{$state_atom}) {
      print "  not supported\n";
      next;
    }

    change(1, $state_atom); # add
    $X->flush;
    sleep 1;
    {
      my @states = get_wm_states();
      my $found = grep {$_==$state_atom} @states;
      if ($found) {
        print "  add ok\n";
      } else {
        print "  bad, add not set\n";
        print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
      }
    }

    change(0, $state_atom); # remove
    $X->flush;
    sleep 1;
    {
      my @states = get_wm_states();
      my $found = grep {$_==$state_atom} @states;
      if ($found) {
        print "  bad, remove still set\n";
        print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
      } else {
        print "  remove ok\n";
      }
    }

    change(1, $state_atom); # toggle-on
    $X->flush;
    sleep 1;
    {
      my @states = get_wm_states();
      my $found = grep {$_==$state_atom} @states;
      if ($found) {
        print "  toggle-on ok\n";
      } else {
        print "  bad, toggle-on not set\n";
        print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
      }
    }

    change(2, $state_atom); # toggle-off
    $X->flush;
    sleep 1;
    {
      my @states = get_wm_states();
      my $found = grep {$_==$state_atom} @states;
      if ($found) {
        print "  bad, toggle-off still set\n";
        print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
      } else {
        print "  toggle-off ok\n";
      }
    }
  }

  # kill $pid;
  print "exit\n";
  exit 0;

  sub change {
    my ($action, $atom) = @_;
    X11::Protocol::WM::_send_event_to_wm ($X, $root,
                                          name   => 'ClientMessage',
                                          window => $window,
                                          type   => $X->atom('_NET_WM_STATE'),
                                          format => 32,
                                          data   => pack('L5',
                                                         $action,
                                                         $atom,
                                                         0,   # state2
                                                         2)); # "user"
  }

  sub get_wm_states {
    my @states;
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window,
                         $X->atom('_NET_WM_STATE'),   # property
                         X11::AtomConstants::ATOM(),  # type
                         0,    # offset
                         999,  # length limit
                         0);   # delete
    if ($format == 32) {
      @states = unpack('L*', $value);
    }
    return @states;
  }
}


unlink '/tmp/wm-state-exercise.out';

foreach my $wm (qw(
                    /usr/bin/metacity
                    /usr/bin/jwm
                    /usr/bin/wmii
                    /usr/bin/fvwm2
                    /usr/bin/icewm
                    mwm
                    /usr/bin/olwm
                    /usr/bin/olvwm

                    /usr/bin/spectrwm
                    /usr/bin/windowlab
                    /usr/bin/amiwm

                    matchbox-window-manager
                    /usr/bin/awesome
                    evilwm
                    /usr/bin/openbox
                    tvtwm
                    /usr/bin/9wm
                    w9wm
                    /usr/bin/xfwm4
                    /usr/bin/sapphire
                    ctwm
                    /usr/bin/dwm
                    /usr/bin/startfluxbox
                    /usr/bin/flwm
                    /usr/bin/herbstluftwm
                    /usr/bin/i3
                    /usr/bin/larswm
                    /usr/bin/miwm
                    /usr/bin/oroborus
                    /usr/bin/wm2
                    /usr/bin/xmonad
                    /so/swm/sWM-1.3.6/bin/sWM
                    twm
                    vtwm
                 )) {
  # my $command = "xvfb-run -a xterm -e 'echo $wm >>/tmp/xx'";
  my $command = "xvfb-run -a xterm -e 'perl $script $wm'";
  print "$command\n";
  system ($command);
}
