# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
package X11::AtomConstants;
use strict;
use Exporter;
use vars '$VERSION', '@ISA', '@EXPORT_OK', '%EXPORT_TAGS';

$VERSION = 24;
@ISA = ('Exporter');
%EXPORT_TAGS = (all => \@EXPORT_OK);

# List generated by
# (shell-command "perl -n -e '/define XA_([^ ]*).*?([0-9]+)/ and print \"      $1\n\"' </usr/include/X11/Xatom.h" 'insert)

@EXPORT_OK =
  (qw(
      PRIMARY
      SECONDARY
      ARC
      ATOM
      BITMAP
      CARDINAL
      COLORMAP
      CURSOR
      CUT_BUFFER0
      CUT_BUFFER1
      CUT_BUFFER2
      CUT_BUFFER3
      CUT_BUFFER4
      CUT_BUFFER5
      CUT_BUFFER6
      CUT_BUFFER7
      DRAWABLE
      FONT
      INTEGER
      PIXMAP
      POINT
      RECTANGLE
      RESOURCE_MANAGER
      RGB_COLOR_MAP
      RGB_BEST_MAP
      RGB_BLUE_MAP
      RGB_DEFAULT_MAP
      RGB_GRAY_MAP
      RGB_GREEN_MAP
      RGB_RED_MAP
      STRING
      VISUALID
      WINDOW
      WM_COMMAND
      WM_HINTS
      WM_CLIENT_MACHINE
      WM_ICON_NAME
      WM_ICON_SIZE
      WM_NAME
      WM_NORMAL_HINTS
      WM_SIZE_HINTS
      WM_ZOOM_HINTS
      MIN_SPACE
      NORM_SPACE
      MAX_SPACE
      END_SPACE
      SUPERSCRIPT_X
      SUPERSCRIPT_Y
      SUBSCRIPT_X
      SUBSCRIPT_Y
      UNDERLINE_POSITION
      UNDERLINE_THICKNESS
      STRIKEOUT_ASCENT
      STRIKEOUT_DESCENT
      ITALIC_ANGLE
      X_HEIGHT
      QUAD_WIDTH
      WEIGHT
      POINT_SIZE
      RESOLUTION
      COPYRIGHT
      NOTICE
      FONT_NAME
      FAMILY_NAME
      FULL_NAME
      CAP_HEIGHT
      WM_CLASS
      WM_TRANSIENT_FOR
      LAST_PREDEFINED
    ));


# List generated by
# (shell-command "perl -n -e '/define XA_([^ ]*).*?([0-9]+)/ and print \"use constant $1 => $2;\n\"' </usr/include/X11/Xatom.h" 'insert)

use constant PRIMARY => 1;
use constant SECONDARY => 2;
use constant ARC => 3;
use constant ATOM => 4;
use constant BITMAP => 5;
use constant CARDINAL => 6;
use constant COLORMAP => 7;
use constant CURSOR => 8;
use constant CUT_BUFFER0 => 9;
use constant CUT_BUFFER1 => 10;
use constant CUT_BUFFER2 => 11;
use constant CUT_BUFFER3 => 12;
use constant CUT_BUFFER4 => 13;
use constant CUT_BUFFER5 => 14;
use constant CUT_BUFFER6 => 15;
use constant CUT_BUFFER7 => 16;
use constant DRAWABLE => 17;
use constant FONT => 18;
use constant INTEGER => 19;
use constant PIXMAP => 20;
use constant POINT => 21;
use constant RECTANGLE => 22;
use constant RESOURCE_MANAGER => 23;
use constant RGB_COLOR_MAP => 24;
use constant RGB_BEST_MAP => 25;
use constant RGB_BLUE_MAP => 26;
use constant RGB_DEFAULT_MAP => 27;
use constant RGB_GRAY_MAP => 28;
use constant RGB_GREEN_MAP => 29;
use constant RGB_RED_MAP => 30;
use constant STRING => 31;
use constant VISUALID => 32;
use constant WINDOW => 33;
use constant WM_COMMAND => 34;
use constant WM_HINTS => 35;
use constant WM_CLIENT_MACHINE => 36;
use constant WM_ICON_NAME => 37;
use constant WM_ICON_SIZE => 38;
use constant WM_NAME => 39;
use constant WM_NORMAL_HINTS => 40;
use constant WM_SIZE_HINTS => 41;
use constant WM_ZOOM_HINTS => 42;
use constant MIN_SPACE => 43;
use constant NORM_SPACE => 44;
use constant MAX_SPACE => 45;
use constant END_SPACE => 46;
use constant SUPERSCRIPT_X => 47;
use constant SUPERSCRIPT_Y => 48;
use constant SUBSCRIPT_X => 49;
use constant SUBSCRIPT_Y => 50;
use constant UNDERLINE_POSITION => 51;
use constant UNDERLINE_THICKNESS => 52;
use constant STRIKEOUT_ASCENT => 53;
use constant STRIKEOUT_DESCENT => 54;
use constant ITALIC_ANGLE => 55;
use constant X_HEIGHT => 56;
use constant QUAD_WIDTH => 57;
use constant WEIGHT => 58;
use constant POINT_SIZE => 59;
use constant RESOLUTION => 60;
use constant COPYRIGHT => 61;
use constant NOTICE => 62;
use constant FONT_NAME => 63;
use constant FAMILY_NAME => 64;
use constant FULL_NAME => 65;
use constant CAP_HEIGHT => 66;
use constant WM_CLASS => 67;
use constant WM_TRANSIENT_FOR => 68;
use constant LAST_PREDEFINED => 68;

1;
__END__

=for stopwords X11-Protocol-Other Ryde pre-defined Xlib PIXMAP

=head1 NAME

X11::AtomConstants -- predefined X11 atoms

=for test_synopsis my ($X, $window)

=head1 SYNOPSIS

 use X11::AtomConstants;
 $X->ChangeProperty($window,
                    X11::AtomConstants::WM_NAME,  # property
                    X11::AtomConstants::PIXMAP,   # type
                    8,                            # format
                    'Replace',
                    'My Window Title');

=head1 DESCRIPTION

This is the X11 pre-defined atoms as Perl constants.  For example C<PIXMAP>
is 20, the PIXMAP atom.

    my $atom_id = X11::AtomConstants::PIXMAP;  # $atom_id is 20
    my $name = $X->GetAtomName($atom_id);      # $name is "PIXMAP"

The C<LAST_PREDEFINED> constant is not an atom as such, but the last of the
predefined values, which happens to be C<WM_TRANSIENT_FOR>.

=cut

# List generated by
# (shell-command "perl -n -e '/define XA_([^ ]*).*?([0-9]+)/ and printf \"    %-20s  %2d\n\", $1, $2' </usr/include/X11/Xatom.h" 'insert)

=pod

    Constant             Value

    PRIMARY                1
    SECONDARY              2
    ARC                    3
    ATOM                   4
    BITMAP                 5
    CARDINAL               6
    COLORMAP               7
    CURSOR                 8
    CUT_BUFFER0            9
    CUT_BUFFER1           10
    CUT_BUFFER2           11
    CUT_BUFFER3           12
    CUT_BUFFER4           13
    CUT_BUFFER5           14
    CUT_BUFFER6           15
    CUT_BUFFER7           16
    DRAWABLE              17
    FONT                  18
    INTEGER               19
    PIXMAP                20
    POINT                 21
    RECTANGLE             22
    RESOURCE_MANAGER      23
    RGB_COLOR_MAP         24
    RGB_BEST_MAP          25
    RGB_BLUE_MAP          26
    RGB_DEFAULT_MAP       27
    RGB_GRAY_MAP          28
    RGB_GREEN_MAP         29
    RGB_RED_MAP           30
    STRING                31
    VISUALID              32
    WINDOW                33
    WM_COMMAND            34
    WM_HINTS              35
    WM_CLIENT_MACHINE     36
    WM_ICON_NAME          37
    WM_ICON_SIZE          38
    WM_NAME               39
    WM_NORMAL_HINTS       40
    WM_SIZE_HINTS         41
    WM_ZOOM_HINTS         42
    MIN_SPACE             43
    NORM_SPACE            44
    MAX_SPACE             45
    END_SPACE             46
    SUPERSCRIPT_X         47
    SUPERSCRIPT_Y         48
    SUBSCRIPT_X           49
    SUBSCRIPT_Y           50
    UNDERLINE_POSITION    51
    UNDERLINE_THICKNESS   52
    STRIKEOUT_ASCENT      53
    STRIKEOUT_DESCENT     54
    ITALIC_ANGLE          55
    X_HEIGHT              56
    QUAD_WIDTH            57
    WEIGHT                58
    POINT_SIZE            59
    RESOLUTION            60
    COPYRIGHT             61
    NOTICE                62
    FONT_NAME             63
    FAMILY_NAME           64
    FULL_NAME             65
    CAP_HEIGHT            66
    WM_CLASS              67
    WM_TRANSIENT_FOR      68

    LAST_PREDEFINED       68

=head1 EXPORTS

Nothing is exported by default, but the constants can be requested in usual
C<Exporter> style,

    use X11::AtomConstants 'PIXMAP';
    blah (atom => PIXMAP);

The C<:all> tag imports everything,

    use X11::AtomConstants ':all';
    blah (atom1 => POINT,
          atom2 => RECTANGLE);

Many atoms like C<STRING> or C<WEIGHT> have rather generic names and
importing them may be undesirable.  They can always be used with the full
package name,

    use X11::AtomConstants;
    blah (atom => X11::AtomConstants::PIXMAP);

=head1 SEE ALSO

L<X11::CursorFont>,
L<X11::Keysyms>,
L<X11::Protocol>,
L<X11::Protocol::Other>,
L<X11::Protocol::WM>

I<X Window System Protocol> specification (values in S<Appendix B>),
F</usr/share/X11/doc/hardcopy/XProtocol/proto.PS.gz>

F</usr/include/X11/Xatom.h>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013 Kevin Ryde

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
