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

my %encode_modules =
  (
   # 1.00 for ksc5601-raw, probably
   'Encode' => 1.00,
   'Encode::HanExtra' => 0.06,  # 0.06 for cns11643-*
  );

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
     {
      maximum_interoperation =>
      { description => 'All the optional things which may be used.',
        requires => { %encode_modules,
                    },
        maximum_tests =>
        { description => 'Have "make test" do as much as possible.',
          requires => {
                       'Module::Util' => 0, # checking for HanExtra
                       %encode_modules,
                      },
        },
        maximum_devel =>
        { description => 'Stuff used variously for development.',
          requires => { 'Smart::Comments'     => 0,
                        'Devel::Comments'     => 0,
                      },
        },
      },
     },
   },

   MyMakeMakerExtras_Pod_Coverage => [ 'X11::Protocol::Other',
                                       'X11::Protocol::GrabServer',
                                       'X11::Protocol::WM',
                                     ],
  );
