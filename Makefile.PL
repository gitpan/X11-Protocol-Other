#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.004;
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'X11-Protocol-Other',
   ABSTRACT     => 'Miscellaneous helpers for X11::Protocol connections.',
   VERSION_FROM => 'lib/X11/Protocol/Other.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   PREREQ_PM    => {
                    'X11::Protocol' => 0,

                    # only for testing
                    'Test' => 0,
                   },
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/x11-protocol-other/index.html',
     },
     optional_features =>
     { maximum_devel =>
       { description => 'Stuff used variously for development.',
         requires => { 'Smart::Comments'     => 0,
                     },
       },
     },
   });
