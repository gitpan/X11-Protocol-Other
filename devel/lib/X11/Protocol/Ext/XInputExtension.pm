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
package X11::Protocol::Ext::XInputExtension;
use strict;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 14;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;


# /usr/share/doc/x11proto-input-dev/XI2proto.txt.gz
# /usr/include/X11/extensions/XInput2.h
# /usr/include/X11/extensions/XI2proto.h
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz


# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     XInputExtensionDeviceUse => ['MasterPointer', 'MasterKeyboard',
                                  'SlavePointer', 'SlaveKeyboard',
                                  'FloatingSlave' ],
     XInputExtensionClass => ['Key', 'Button', 'Valuator'],
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   undef,  # 0

   ['XInputExtensionGetExtensionVersion',  # 1
    sub {
      my ($X, $name) = @_;
      ### XInputExtensionGetExtensionVersion() ...
      # my $ret =  pack ('Sxx' . X11::Protocol::padded($name),
      #              length($name), $name);
      # ### $ret
      # ### len: length($ret)
      return pack ('Sxx' . X11::Protocol::padded($name),
                   length($name), $name);
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XInputExtension'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   undef,  # ListInputDevices		2
   undef,  # OpenDevice			3
   undef,  # CloseDevice			4
   undef,  # SetDeviceMode			5
   undef,  # SelectExtensionEvent		6
   undef,  # GetSelectedExtensionEvents	7
   undef,  # ChangeDeviceDontPropagateList 8
   undef,  # GetDeviceDontPropagateList	9
   undef,  # GetDeviceMotionEvents		10
   undef,  # ChangeKeyboardDevice		11
   undef,  # ChangePointerDevice		12
   undef,  # GrabDevice			13
   undef,  # UngrabDevice			14
   undef,  # GrabDeviceKey			15
   undef,  # UngrabDeviceKey		16
   undef,  # GrabDeviceButton		17
   undef,  # UngrabDeviceButton		18
   undef,  # AllowDeviceEvents		19
   undef,  # GetDeviceFocus		20
   undef,  # SetDeviceFocus		21
   undef,  # GetFeedbackControl		22
   undef,  # ChangeFeedbackControl		23
   undef,  # GetDeviceKeyMapping		24
   undef,  # ChangeDeviceKeyMapping	25
   undef,  # GetDeviceModifierMapping	26
   undef,  # SetDeviceModifierMapping	27
   undef,  # GetDeviceButtonMapping	28
   undef,  # SetDeviceButtonMapping	29
   undef,  # QueryDeviceState		30
   undef,  # SendExtensionEvent		31
   undef,  # DeviceBell			32
   undef,  # SetDeviceValuators		33
   undef,  # GetDeviceControl		34
   undef,  # ChangeDeviceControl		35

   # -------------------------------------------------------------------------
   # XInputExtension version 1.5
   undef,  # ListDeviceProperties          36
   undef,  # ChangeDeviceProperty          37
   undef,  # DeleteDeviceProperty          38
   undef,  # GetDeviceProperty             39

   # -------------------------------------------------------------------------
   # XInputExtension version 2.0

   undef,  # XIQueryPointer                40
   undef,  # XIWarpPointer                 41
   undef,  # XIChangeCursor                42
   undef,  # XIChangeHierarchy             43
   undef,  # XISetClientPointer            44
   undef,  # XIGetClientPointer            45
   undef,  # XISelectEvents                46

   ['XInputExtensionQueryVersion',  # 47
    sub {
      shift; # ($X, $client_major, $client_minor)
      ### XInputExtensionQueryVersion() ...
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XInputExtension'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XInputExtensionQueryDevice',  # 48
    sub {
      my ($X, $deviceid) = @_;
      ### XInputExtensionQueryDevice() ...
      return pack 'Sxx', $deviceid;
    },
    sub {
      my ($X, $data) = @_;
      ### XInputExtensionQueryDevice reply ...

      my ($num_devices) = unpack 'x8S', $data;
      ### $num_devices

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_devices) {
        ### $pos
        ### data: substr($data,$pos)

        my ($deviceid, $use, $attachment, $num_classes, $name_len, $enabled)
          = unpack 'SSSSSC', substr ($data, $pos);
        $pos += 12;

        ### $deviceid
        ### $use
        ### $attachment
        ### $num_classes
        ### $name_len
        ### $enabled

        my $name = substr ($data, $pos, $name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);
        ### $name

        my @classes;
        foreach (1 .. $num_classes) {
          my ($type, $class_len, $sourceid, $num_whatever)
            = unpack 'SSSS', substr($data,$pos);
          $pos += $class_len*4;
          ### $type
          ### $class_len
          ### $sourceid
          ### $num_whatever

          push @classes, [ $X->interp('XInputExtensionClass', $type), 
                           $sourceid ];
        }

        push @ret, [ $deviceid,
                     $X->interp('XInputExtensionDeviceUse',$use),
                     $attachment,
                     $enabled,
                     $name,
                     \@classes ];
      }
      return @ret;
    }],

   undef,  # XISetFocus                    49
   undef,  # XIGetFocus                    50
   undef,  # XIGrabDevice                  51
   undef,  # XIUngrabDevice                52
   undef,  # XIAllowEvents                 53
   undef,  # XIPassiveGrabDevice           54
   undef,  # XIPassiveUngrabDevice         55
   undef,  # XIListProperties              56
   undef,  # XIChangeProperty              57
   undef,  # XIDeleteProperty              58
   undef,  # XIGetProperty                 59

   ['XInputExtensionGetSelectedEvents',  # 60
    \&_request_xids,
    sub {
      my ($X, $data) = @_;
      # pairs of
      # uint16_t    deviceid;       /**< Device id to select for        */
      # uint16_t    mask_len;       /**< Length of mask in 4 byte units */

      my ($num_masks) = unpack 'x8S', $data;
      my @ret;
      my $pos = 12;
      foreach (1 .. $num_masks) {
        my ($deviceid, $mask_len) = unpack 'SS', substr ($data, $pos);
        $pos += 4;
        my $mask = substr ($data, $pos, $mask_len); # FIXME ... numize bytes
        $pos += $mask_len;
        push @ret, $deviceid, $mask;
      }
      return @ret;
    }],

  ];

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}
sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XInputExtension new()

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'Device',                 # 0
                            'Event',                  # 1
                            'XInputExtensionMode',    # 2
                            'DeviceBusy',             # 3
                            'XInputExtensionClass');  # 4

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  return bless { }, $class;
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    if (defined $reqs->[$i]) {
      $href->{$reqs->[$i]->[0]} = [$request_num, $i];
    }
  }
}
sub _ext_const_error_install {
  my $X = shift;  # ($X, $errname1,$errname2,...)
  ### _ext_const_error_install: @_
  my $error_num = shift;
  my $aref = $X->{'ext_const'}{'Error'}  # copy
    = [ @{$X->{'ext_const'}{'Error'} || []} ];
  my $href = $X->{'ext_const_num'}{'Error'}  # copy
    = { %{$X->{'ext_const_num'}{'Error'} || {}} };
  my $i;
  foreach $i (0 .. $#_) {
    $aref->[$error_num + $i] = $_[$i];
    $href->{$_[$i]} = $error_num + $i;
  }
}

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XInputExtension - input devices beyond keyboard and pointer

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XInputExtension')
   or print "XInputExtension not available";

=head1 DESCRIPTION

The XInputExtension extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XInputExtension');

=head2 XInputExtension 1.0

=head2 XInputExtension 2.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XInputExtensionQueryVersion ($client_major, $client_minor)>

Return the XInputExtension protocol version implemented by the server.

=back

=head1 SEE ALSO

L<X11::Protocol>

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
