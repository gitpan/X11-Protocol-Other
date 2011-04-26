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
package X11::Protocol::ChooseWindow;
use strict;
use Carp;

use vars '$VERSION';
$VERSION = 5;

# uncomment this to run the ### lines
use Smart::Comments;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub choose {
  my $class = shift;
  my $self = $class->new (@_);
  $self->run;
}

sub start {
  my ($self) = @_;

  $self->{'window'} = 0;
  $self->{'button_released'} = 0;
  my $X = $self->{'X'};

  my $cursor = $self->{'cursor'};
  my $free_cursor;
  if (! $cursor) {
    my $cursor_font = $X->new_rsrc;
    $X->OpenFont ($cursor_font, "cursor");
    my $cursor_glyph = $self->{'cursor_glyph'};
    if (! defined $cursor_glyph) {
      $cursor_glyph = 34;   # default "crosshair"
    }
    $cursor = $X->new_rsrc;
    $X->CreateGlyphCursor ($cursor,
                           $cursor_font,  # font
                           $cursor_font,  # mask font
                           $cursor_glyph,    # glyph number
                           $cursor_glyph+1,  # and its mask
                           0,0,0,                    # foreground, black
                           0xFFFF, 0xFFFF, 0xFFFF);  # background, white
    $free_cursor = 1;
    $X->CloseFont ($cursor_font);
  }

  my $root = $self->{'root'} || $X->{'root'};
  my $time = $self->{'time'} || $self->{'event'}->{'time'} || 'CurrentTime';
  $self->{'ungrab_time'} = $time;

  # my $time = $self->{'time'};
  # if (! defined $time) {
  #   $time = $self->{'event'}->{'time'};
  #   if (! defined $time) {
  #     $time = 'CurrentTime';
  #   }
  # }

  my $status = $X->GrabPointer
    ($X->root,       # window
     0,              # owner events
     $X->pack_event_mask('ButtonPress','ButtonRelease'),
     'Synchronous',  # pointer mode
     'Asynchronous', # keyboard mode
     $X->root,       # confine window
     $cursor,        # crosshair cursor
     $time);
  $self->{'ungrab_time'} = $time;
  if ($free_cursor) {
    $X->FreeCursor ($cursor);
  }
  if ($status ne 'Success') {
    croak "Cannot grab mouse pointer to select a window: $status\n";
  }

  $X->AllowEvents ('SyncPointer', 'CurrentTime');
}

sub handle_event {
  my ($self, %h) = @_;
  ### %h
  my $name = $h{'name'};

  if ($name eq 'ButtonPress') {
    $self->{'window'} = $h{'child'};
    $self->{'choose_time'} = $h{'time'};

  } elsif ($name eq 'ButtonRelease') {
    # wait for button pressed to choose window, and then released so the
    # release event doesn't go to the chosen window
    if ($self->{'window'}) {  # only after ButtonPress, not button already down
      $self->{'button_released'} = 1;
      $self->{'ungrab_time'} = $h{'time'};
    }
  }
}

sub is_done {
  my ($self) = @_;
  return $self->{'window'} && $self->{'button_released'};
}

sub DESTROY {
  my ($self) = @_;
  my $ungrab_time = $self->{'ungrab_time'};
  if (defined $ungrab_time) {
    my $X = $self->{'X'};
    eval { $X->UngrabPointer ($ungrab_time) };
  }
}

sub handle_input {
  my $self = shift;
  my $X = $self->{'X'};

  my $old_event_handler = $X->{'event_handler'};
  local $X->{'event_handler'} = sub {
    my (%h) = @_;
    $self->handle_event (@_);
    goto $old_event_handler;
  };
  $X->handle_input;

  if ($self->is_done) {
    my $ungrab_time = delete $self->{'ungrab_time'};
    if (defined $ungrab_time) {
      $X->UngrabPointer ($ungrab_time);
    }
  } else {
    $X->AllowEvents ('SyncPointer', 'CurrentTime');
  }
}

sub run {
  my $self = shift;
  %$self = (%$self, @_);
  $self->start;

  do {
    $self->handle_input;
  } until ($self->is_done);

  return $self->{'window'};
}

1;
__END__

=for stopwords drawables pixmaps XFIXES DamageNotify XID subwindows enum unhandled GL arrayref umm pixmap Ryde

=head1 NAME

X11::CursorFont - cursor font glyph names

=for test_synopsis my ($X)

=head1 SYNOPSIS

 use X11::CursorFont '%CURSOR_GLYPH';

 my $cursor_font = $X->new_rsrc;
 $X->OpenFont ($cursor_font, "cursor");

 my $cursor = $X->new_rsrc;
 $X->CreateGlyphCursor ($cursor,
                        $cursor_font,  # font
                        $cursor_font,  # mask font
                        $CURSOR_GLYPH{'crosshair'},     # glyph
                        $CURSOR_GLYPH{'crosshair'} + 1, # and its mask
                        0,0,0,                    # foreground, black
                        0xFFFF, 0xFFFF, 0xFFFF);  # background, white

=cut
