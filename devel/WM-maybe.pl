# set_text_property()




# Copyright 2011, 2012 Kevin Ryde

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

# rootwin for ewmh virtual root?

use 5.004;
use strict;
use Carp;
use X11::Protocol::WM;
use X11::AtomConstants;

use vars '$VERSION';
$VERSION = 11;

# uncomment this to run the ### lines
use Devel::Comments;


BEGIN {
  eval 'utf8->can("is_utf8") && *is_utf8 = \&utf8::is_utf8'   # 5.8.1
    || eval 'use Encode "is_utf8"; 1'                         # 5.8.0
      || eval 'sub is_utf8 () { 0 }; 1'                       # 5.6 fallback
        || die 'Oops, cannot create is_utf8() subr: ',$@;
}
### \&is_utf8

# /usr/share/doc/xorg-docs/specs/ICCCM/icccm.txt.gz


#------------------------------------------------------------------------------
# get _NET_WM_ALLOWED_ACTIONS

# Return 'CLOSE' etc, or atom integer if unrecognised
# OR keep _NET_WM_ALLOWED_ACTION in case unprefixed name ?
sub _get_net_wm_allowed_actions {
  my ($X, $window) = @_;
  # ENHANCE-ME: atom name fetches in one round trip
  return map {_net_wm_allowed_action_interp($_)}
    get_net_wm_allowed_actions_atoms($X,$window);
}
sub _net_wm_allowed_action_interp {
  my ($X, $atom) = @_;
  # FIXME: robust_req() in case garbage atom
  my $name = $X->atom_name ($atom);
  if ($name =~ s/^_NET_WM_ALLOWED_ACTION_//) {
    return $name;
  } else {
    return $atom;
  }
}

# return atom integers
sub get_net_wm_allowed_actions_atoms {
  my ($X, $window) = @_;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_ALLOWED_ACTIONS'), # property
                       X11::AtomConstants::ATOM(),          # type
                       0,             # offset
                       999,           # max length, of CARD32
                       0);            # no delete
  if ($format == 32) {
    return unpack 'L*',$value;
  } else {
    return;
  }
}


# Set by the window manager.
#
# =item C<_set_net_wm_allowed_actions ($X, $window, $action...)>
#
sub _set_net_wm_allowed_actions {
  my $X = shift;
  my $window = shift;
  my $prop = $X->atom('_NET_WM_ALLOWED_ACTIONS');
  if (@_) {
    $X->ChangeProperty($window,
                       $prop,                    # property
                       X11::AtomConstants::ATOM, # type
                       32,                       # format
                       'Replace',
                       pack 'L*', map {_net_wm_allowed_action_to_atom($_)} @_);
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

sub _net_wm_allowed_action_to_atom {
  my ($X, $action) = @_;
  if (! defined $action || $action =~ /^\d+$/) {
    return $action;
  } else {
    return $X->atom ("_NET_WM_ACTION_$action");
  }
}


#------------------------------------------------------------------------------
# get WM_HINTS, to read back, or by wm

{
  my $format = 'LLLLLllLL';

  sub _get_wm_hints {
    my ($X, $window) = @_;
    my ($value, $type, $format, $bytes_after)
      = $X->GetProperty ($window,
                         X11::AtomConstants::WM_HINTS, # prop name
                         X11::AtomConstants::WM_HINTS, # type
                         0,             # offset
                         9,             # length($format), of CARD32
                         0);            # no delete
    if ($format == 32) {
      return _unpack_wm_hints ($X, $value);
    } else {
      return;
    }
  }

  # X11R2 Xlib had a bug were XSetWMHints() set a WM_HINTS property to only
  # 8 CARD32s, chopping off the window_group field.  In Xatomtype.h
  # NumPropWMHintsElements was 8 instead of 9.  Ignore any window_group bit
  # in the flags in that case, and don't return a window_group field.
  # (X11R2 source available at http://ftp.x.org/pub/X11R2/X.V11R2.tar.gz)
  #
  my @keys = ('input',
              'initial_state',
              'icon_pixmap',
              'icon_window',
              'icon_x',
              'icon_y',
              'icon_mask',
              'window_group',
              # 'message_hint',  # in the code, obsolete ...
              # 'urgency',       # in the code
             );
  sub _unpack_wm_hints {
    my ($X, $bytes) = @_;
    my ($flags, @values) = unpack ($format, $bytes);
    my $bit = 1;
    my @ret;
    my $i;
    foreach $i (0 .. $#keys) {
      my $value = $values[$i];
      if (! defined $value) {
        next;
      }
      if ($flags & $bit) {
        my $key = $keys[$i];
        if ($key eq 'initial_state') {
          $value = X11::Protocol::WM::_wmstate_interp($X, $value);
        }
        push @ret, $key, $value;
      }
      if ($i != 4) {
        $bit <<= 1;
      }
    }
    if ($flags & 128) {
      push @ret, message_hint => 1;
    }
    if ($flags & 256) {
      push @ret, urgency => 1;
    }
    return @ret;
  }
}

#------------------------------------------------------------------------------
# _NET_WM_STATE

# =item C<($state1, $state2, ..) = _get_net_wm_state ($X, $window)>
#
# Return the C<_NET_WM_STATE> property from C<$window>.
#
sub _get_net_wm_state_names {
  my ($X, $window) = @_;
  return atom_names($X, _get_net_wm_state_atoms($X,$window));
}
sub _get_net_wm_state_atomhash {
  my ($X, $window) = @_;
  return { map {$_=>1} _get_net_wm_state_atoms($X,$window) };
}
sub get_net_wm_state_atoms {
  my ($X, $window) = @_;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_STATE'),       # property
                       X11::AtomConstants::CARDINAL(),  # type
                       0,    # offset
                       999,  # length
                       0);   # delete
  if ($format == 32) {
    return unpack('L*', $value);
  } else {
    return;
  }
}
sub _net_wm_state_atom_interp {
  my ($X, $atom) = @_;
  if ($X->{'do_interp'}) {
    my $str = $X->atom_name ($atom);
    if ($str =~ s/^_NET_WM_STATE_//) {
      return $str;
    }
  }
  return $atom;
}


#------------------------------------------------------------------------------
# _NET_WM_NAME

# =item C<set_wm_name_and_net_wm_name ($X, $window, $name)>
#
sub set_wm_name_and_net_wm_name {
  my ($X, $window, $name) = @_;
  set_wm_name($X,$window,$name);

  my $prop = $X->atom('_NET_WM_NAME');
  if (defined $name) {
    if (is_utf8($name)) {
      require Encode;
      $name = Encode::encode('utf-8', $name); # default with substitution chars
    } else {
      $name = _latin1_to_utf8($name);
    }
    $X->ChangeProperty ($window,
                        $prop,                    # prop name
                        $X->atom('UTF8_STRING'),  # type
                        8,                        # format
                        'Replace',
                        $name);
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

sub _latin1_to_utf8 {
  my ($str) = @_;
  $str =~ s{([0x80-0xFF])}
           {my $ord = ord($1);
            $ord < 0xC0 ? "\xC2".$1 : "\xC3".chr($ord-0x40)
          }xe;
  return $str;
}

# =item C<_set_net_wm_name ($X, $window, $name)>
#
# Set the C<_NET_WM_NAME> property to C<$name>.  The name is per L</Text>
# above, and is converted to a utf-8 for the property as necessary.
#
# Generally speaking C<_NET_WM_NAME> is superfluous.  It does nothing that
# C<WM_NAME> doesn't already do.  But a few slack window managers might work
# better on non-ascii/non-latin1 names as utf8 in C<_NET_WM_NAME> than
# compound text in C<WM_NAME>.


# Set the C<_NET_WM_NAME> property on C<$window>.  This has the same purpose
# as C<WM_NAME> above, but is encoded as "UTF8_STRING".
#
# If C<$name> is a Perl 5.8 wide-char string then it's encoded to utf8.
# Otherwise C<$name> is a byte string and assumed to be utf8 already.
#
sub _set_net_wm_name {
  my ($X, $window, $name) = @_;
  _set_utf8_string_property ($X, $window, $X->atom('_NET_WM_NAME'), $name);
}

# C<_set_utf8_string_property ($X, $window, $prop, $str)>
#
# Set a "UTF8_STRING" property C<$prop> (an atom) on C<$window>.  In Perl
# 5.8 if C<$str> is a wide-char string then it's encoded as utf8, otherwise
# C<$str> is a byte string and is assumed to be utf8 already.  If C<$str> is
# C<undef> then the property is deleted.
#
sub _set_utf8_string_property {
  my ($X, $window, $prop, $str) = @_;
  if (defined $str) {
    $X->ChangeProperty($window,
                       $prop,
                       $X->atom('UTF8_STRING'),   # type
                       8,                         # byte format
                       'Replace',
                       _to_UTF8_STRING($str));
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}
sub _to_UTF8_STRING {
  my ($str) = @_;
  if (utf8->can('upgrade')) {
    utf8::upgrade($str);
    require Encode;
    return Encode::encode ('utf-8', $str); # default with substitution chars
  } else {
    return $str;
  }
}

#------------------------------------------------------------------------------
# set WM_CLASS  FindBin

# C<_set_wm_class_from_findbin ($X, $window)>
#
# Any good?
#
# Set the C<WM_CLASS> property on $window (an XID) using the C<FindBin>
# module C<$Script>, that being the name of the running Perl script.  Any
# .pl extension is stripped to give the "instance" name.  The "class" name
# has the first letter of each word upper-cased.
#
sub _set_wm_class_from_findbin {
  my ($X, $window) = @_;
  require FindBin;
  (my $instance = $FindBin::Script) =~ s/\.pl$//;
  (my $class = $instance) =~ s/\b(\w)/\U$1/g;
  X11::Protocol::WM::set_wm_class ($X, $window, $instance, $class);
}


#------------------------------------------------------------------------------

# =item C<_set_text_property ($X, $window, $str)>
#
# Set the given C<$prop> (an atom) property on C<$window> (an XID) using one
# of the text types "STRING" or "COMPOUND_TEXT".  If C<$str> is C<undef>
# then C<$prop> is deleted.
#
# In Perl 5.8 and up if C<$str> is a wide-char string then it's encoded to
# "STRING" (latin-1) if possible or to "COMPOUND_TEXT" if not.  Otherwise
# C<$str> is a byte string and assumed to be latin-1 "STRING".
#
sub _set_text_property {
  my ($X, $window, $prop, $str) = @_;
  my ($type, @strings);
  if (defined $str) {
    ($type, @strings) = _str_to_text_chunks ($X, $str);
  }
  _set_property_chunks ($X, $window, $prop, $type, 8, @strings);
}

sub _set_property_chunks {
  my ($X, $window, $prop, $type, $format, @chunks) = @_;
  ### _set_property_chunks()
  ### chunks: scalar(@chunks).' lens '.join(',',map{length}@chunks)
  if (@chunks) {
    my $append = 'Replace';
    while (@chunks) {
      $X->ChangeProperty($window,
                         $prop,
                         $type,
                         $format,
                         $append,
                         shift @chunks);
      $append = 'Append';
    }
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

sub _str_to_text {
  my ($X, $str) = @_;
  my $atom = X11::AtomConstants::STRING;
  if (is_utf8($str)) {
    require Encode;
    my $input = $str;
    my $bytes = Encode::encode ('iso-8859-1', $input, Encode::FB_QUIET());
    if (length($input) == 0) {
      $str = $bytes;  # latin-1
    } else {
      $atom = $X->atom('COMPOUND_TEXT');
      $input = $str;
      $str = Encode::encode ('x11-compound-text', $input, Encode::FB_WARN());
    }
  }
  return ($atom, $str);
}

sub _str_to_text_chunks {
  my ($X, $str) = @_;
  # 6xCARD32 of win,prop,type,format,mode,datalen then the text bytes
  my $maxlen = 4 * ($X->{'maximum_request_length'} - 6);
  ### $maxlen

  if (is_utf8($str)) {
    require Encode;
    my $input = $str;
    my $bytes = Encode::encode ('iso-8859-1', $input, Encode::FB_QUIET());
    if (length($input) == 0) {
      $str = $bytes;  # latin-1

    } else {
      my $codingfunc = sub { Encode::encode ('x11-compound-text', $input, Encode::FB_QUIET()) };
      $input = $str;
      &$codingfunc();
      my @ret;
      if (length($input) == 0) {
        @ret = ($X->atom('COMPOUND_TEXT'));
      } else {
        @ret = ($X->atom('UTF8_STRING'));
        $codingfunc = sub { Encode::encode ('utf-8', $input, Encode::FB_WARN()) };
      }
      my $pos = 0;
      $maxlen = int($maxlen/2) + 1;
      for (;;) {
        my $input_len = length($str) - $pos;
        last unless $input_len;
        if ($input_len > $maxlen) {
          $input_len = $maxlen;
        }
        for (;;) {
          $input = substr($str, $pos, $input_len);
          $bytes = &$codingfunc();
          if ($input_len == 1 || length($bytes) <= $maxlen) {
            last OUTER;
          }
          $input_len = int ($input_len / 2);
        }
        $pos += $input_len;
        push @ret, $bytes;
      }
      return @ret;
    }
  }

  ### use STRING
  my @ret = (X11::AtomConstants::STRING);
  my $pos = 0;
  while ($pos + $maxlen < length($str)) {
    push @ret, substr($str, $pos, $maxlen);
    $pos += $maxlen;
  }
  push @ret, substr ($str, $pos);
  return @ret;
}

#------------------------------------------------------------------------------
# append WM_PROTOCOLS

sub _append_wm_protocols {
  my $X = shift;
  my $window = shift;
  $X->ChangeProperty($window,
                     $X->atom('WM_PROTOCOLS'),    # key
                     X11::AtomConstants::ATOM, # type
                     32,                          # format
                     'Append',
                     pack('L*', map {_to_atom_id($X,$_)} @_));
}

# intern arguments in one round trip .
sub _atoms {
  my $X = shift;
  return map {$X->atom($_)} @_;
}

sub _atoms_parallel {
  my $X = shift;
  my @ret;
  my @names;
  my @seqs;
  my @data;
  for (;;) {
    while (@_ && @seqs < 100) {  # max 100 sliding window
      my $name = shift;
      push @names, $name;
      my $seq;
      my $atom = $X->{'atom'}->{$name};
      if (defined $atom) {
        push @data, $atom;
      } else {
        $seq = $X->send('InternAtom', $name, 0);
        ### send: $seq
        push @data, undef;
        $X->add_reply ($seq, \($data[-1]));
      }
      push @seqs, $seq;
    }

    @seqs || last;
    my $seq = shift @seqs;
    my $name = shift @names;
    my $data = shift @data;
    my $atom;
    if (defined $seq) {
      ### handle_input_for: $seq
      $X->handle_input_for ($seq);
      $X->delete_reply($seq);
      $atom = $X->unpack_reply ('InternAtom', $data);
      ### $atom
      $X->{'atom'}->{$name} = $atom;
    } else {
      $atom = $data;
    }
    push @ret, $atom;
  }
  return @ret;
}


#------------------------------------------------------------------------------
# get _NET_WM_USER_TIME

# for use by wm, might have to look at the defined user time window instead ...
sub get_net_user_time_window {
  my ($X, $window) = @_;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_WM_USER_TIME_WINDOW'),  # property
                       X11::AtomConstants::WINDOW,  # type
                       0,    # offset
                       1,    # length, 1 x CARD32
                       0);   # delete
  if ($format == 32) {
    return scalar (unpack 'L', $value);
  } else {
    return undef;
  }
}



1;
__END__
