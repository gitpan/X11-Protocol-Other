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

my %modes = (notimp  => 1,
             nomem   => 1,
             enabled => 1);
my $current_mode = 'notimp';

sub mode {
  my ($class, $mode) = @_;
  $modes{$mode} or croak "No such $class mode: ",$mode;
  $current_mode = $mode;
}

sub import {
  my $class = shift;
  foreach (@_) {
    if ($_ eq '-notimp') {
      $current_mode = 'notimp';
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

  if ($current_mode eq 'notimp') {
    croak "shmget not implemented";
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
  if ($current_mode eq 'notimp') {
    croak "shm I/O not implemented";
  }
  return CORE::shmread($id,$var,$pos,$size);
};

*CORE::GLOBAL::shmwrite = \&Test_Without_Shm_shmwrite;
sub Test_Without_Shm_shmwrite ($$$$) {
  my ($id,$str,$pos,$size) = @_;
  if ($current_mode eq 'notimp') {
    croak "shm I/O not implemented";
  }
  return CORE::shmwrite($id,$str,$pos,$size);
};

*CORE::GLOBAL::shmctl = \&Test_Without_Shm_shmctl;
sub Test_Without_Shm_shmctl ($$$) {
  my ($id,$cmd,$arg) = @_;
  if ($current_mode eq 'notimp') {
    croak "shmctl not implemented";
  }
  return CORE::shmctl($id,$cmd,$arg);
};

1;
__END__

=for stopwords Ryde

=head1 NAME

Test::Without::Shm - simulate shmget() etc unavailable

=head1 SYNOPSIS

 perl -MTest::Without::Shm=-notimp ...

=head1 DESCRIPTION

B<In progress ...>

Override the core functions

    shmget
    shmread
    shmwrite
    shmctl

to pretend that System-V style shared memory is not implemented on the
system, or that there's not enough memory.

This can be used for testing to see that module code etc throws errors or
falls back as necessary or desired when shm is unavailable.

The functions are overridden with the C<CORE::GLOBAL> mechanism (see
L<CORE/OVERRIDING CORE FUNCTIONS>) so C<Test::Without::Shm> must be loaded
before any code which might call them.

=head1 IMPORTS

The C<Test::Without::Shm> import options are

=over

=item C<-notimp>

Make shm "not implemented", as if the system doesn't have the underlying
functions.  This makes the Perl level functions croak with "shmget not
implemented", or "shm I/O not implemented", etc.

=item C<-nomem>

Make C<shmget()> fail with C<ENOMEM> as if the system says there's not
enough memory to make a shm segment.

=back

=head1 FUNCTIONS

=over

=item C<Test::Without::Shm-E<gt>mode ($mode)>

Set the shm mode.  C<$mode> is ...

=back

=head1 SEE ALSO

L<perlfunc/shmget>,
L<CORE>,
L<shmget(2)>,
L<IPC::SysV>

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
