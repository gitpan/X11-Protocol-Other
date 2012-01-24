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


# Usage: perl sync-info.pl
#
# Print some information from the SYNC extension.
#

use 5.004;
use strict;
use X11::Protocol;

my $X = X11::Protocol->new;
if (! $X->init_extension('SYNC')) {
  print "No SYNC on the server\n";
  exit 0;
}

my ($major, $minor) = $X->SyncInitialize (3, 1);
print "SYNC extension version $major.$minor\n";

my @system_infos = $X->SyncListSystemCounters;
my $system_count = scalar(@system_infos);
print "$system_count system counters\n";

foreach my $elem (@system_infos) {
  my ($counter, $resolution, $name) = @$elem;
  print "  $counter resolution=$resolution \"$name\"\n";
}

exit 0;
