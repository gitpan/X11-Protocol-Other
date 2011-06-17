#!/usr/bin/perl -w

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


# cf doio.c
#   Perl_do_ipcget() for shmget
#   Perl_do_shmio() for shmread,shmwrite
#   Perl_do_ipcctl() for shmget
#

package Test::Without::Shm;
use strict;
use Carp;
use POSIX ();

# uncomment this to run the ### lines
#use Smart::Comments;

my %modes = (not_implemented => 1,
             nomem           => 1,
             enabled         => 1);
my $current_mode = 'not_implemented';

sub mode {
  my ($class, $mode) = @_;
  $modes{$mode} or croak "No such $class mode: ",$mode;
  $current_mode = $mode;
}

sub import {
  my $class = shift;
  foreach (@_) {
    if ($_ eq '-not_implemented') {
      $current_mode = 'not_implemented';
    } elsif ($_ eq '-nomem') {
      $current_mode = 'nomem';
    } elsif ($_ eq '-enabled') {
      $current_mode = 'enabled';
    } else {
      croak 'Unrecognised Test::Without::Shm option: ',$_;
    }
  }
}

sub unimport {
  $current_mode = 'enabled';
}


*CORE::GLOBAL::shmget = \&Test_Without_Shm_shmget;
sub Test_Without_Shm_shmget ($$$) {
  my ($key, $size, $flags) = @_;
  ### Test-Without-Shm shmget() ...

  if ($current_mode eq 'not_implemented') {
    croak "shmread not implemented";
  }
  if ($current_mode eq 'nomem') {
    $! = POSIX::ENOMEM();
    return undef;
  }
  return CORE::shmget ($key, $size, $flags);
};

*CORE::GLOBAL::shmread = \&Test_Without_Shm_shmread;
sub Test_Without_Shm_shmread ($$$$) {
  my ($id,$var,$pos,$size) = @_;
  if ($current_mode eq 'not_implemented') {
    croak "shm I/O not implemented";
  }
  return CORE::shmread($id,$var,$pos,$size);
};

*CORE::GLOBAL::shmwrite = \&Test_Without_Shm_shmwrite;
sub Test_Without_Shm_shmwrite ($$$$) {
  my ($id,$str,$pos,$size) = @_;
  if ($current_mode eq 'not_implemented') {
    croak "shm I/O not implemented";
  }
  return CORE::shmwrite($id,$str,$pos,$size);
};

*CORE::GLOBAL::shmctl = \&Test_Without_Shm_shmctl;
sub Test_Without_Shm_shmctl ($$$) {
  my ($id,$cmd,$arg) = @_;
  if ($current_mode eq 'not_implemented') {
    croak "shmctl not implemented";
  }
  return CORE::shmctl($id,$cmd,$arg);
};

1;
__END__
