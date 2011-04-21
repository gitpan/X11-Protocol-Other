# Copyright 2011 Kevin Ryde

#  arrow_mask in hash too ?


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
package X11::CursorFont;
use strict;
use vars '$VERSION', '@ISA', '%CURSOR_GLYPH', '%CURSOR_NAME', '@EXPORT_OK';

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = ('%CURSOR_GLYPH', '%CURSOR_NAME');

$VERSION = 3;

# cf XmuCursorNameToIndex()

%CURSOR_GLYPH
  = (
     # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and print \"     $1 => $2,\n\"' </usr/include/X11/cursorfont.h" 'insert)

     X_cursor => 0,
     arrow => 2,
     based_arrow_down => 4,
     based_arrow_up => 6,
     boat => 8,
     bogosity => 10,
     bottom_left_corner => 12,
     bottom_right_corner => 14,
     bottom_side => 16,
     bottom_tee => 18,
     box_spiral => 20,
     center_ptr => 22,
     circle => 24,
     clock => 26,
     coffee_mug => 28,
     cross => 30,
     cross_reverse => 32,
     crosshair => 34,
     diamond_cross => 36,
     dot => 38,
     dotbox => 40,
     double_arrow => 42,
     draft_large => 44,
     draft_small => 46,
     draped_box => 48,
     exchange => 50,
     fleur => 52,
     gobbler => 54,
     gumby => 56,
     hand1 => 58,
     hand2 => 60,
     heart => 62,
     icon => 64,
     iron_cross => 66,
     left_ptr => 68,
     left_side => 70,
     left_tee => 72,
     leftbutton => 74,
     ll_angle => 76,
     lr_angle => 78,
     man => 80,
     middlebutton => 82,
     mouse => 84,
     pencil => 86,
     pirate => 88,
     plus => 90,
     question_arrow => 92,
     right_ptr => 94,
     right_side => 96,
     right_tee => 98,
     rightbutton => 100,
     rtl_logo => 102,
     sailboat => 104,
     sb_down_arrow => 106,
     sb_h_double_arrow => 108,
     sb_left_arrow => 110,
     sb_right_arrow => 112,
     sb_up_arrow => 114,
     sb_v_double_arrow => 116,
     shuttle => 118,
     sizing => 120,
     spider => 122,
     spraycan => 124,
     star => 126,
     target => 128,
     tcross => 130,
     top_left_arrow => 132,
     top_left_corner => 134,
     top_right_corner => 136,
     top_side => 138,
     top_tee => 140,
     trek => 142,
     ul_angle => 144,
     umbrella => 146,
     ur_angle => 148,
     watch => 150,
     xterm => 152,
    );

my @CURSOR_NAME
  = (
     # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and do { print qq{     q{$1},\n}; print qq{     q{$1_mask},\n} }' </usr/include/X11/cursorfont.h" 'insert)

     q{X_cursor},
     q{X_cursor_mask},
     q{arrow},
     q{arrow_mask},
     q{based_arrow_down},
     q{based_arrow_down_mask},
     q{based_arrow_up},
     q{based_arrow_up_mask},
     q{boat},
     q{boat_mask},
     q{bogosity},
     q{bogosity_mask},
     q{bottom_left_corner},
     q{bottom_left_corner_mask},
     q{bottom_right_corner},
     q{bottom_right_corner_mask},
     q{bottom_side},
     q{bottom_side_mask},
     q{bottom_tee},
     q{bottom_tee_mask},
     q{box_spiral},
     q{box_spiral_mask},
     q{center_ptr},
     q{center_ptr_mask},
     q{circle},
     q{circle_mask},
     q{clock},
     q{clock_mask},
     q{coffee_mug},
     q{coffee_mug_mask},
     q{cross},
     q{cross_mask},
     q{cross_reverse},
     q{cross_reverse_mask},
     q{crosshair},
     q{crosshair_mask},
     q{diamond_cross},
     q{diamond_cross_mask},
     q{dot},
     q{dot_mask},
     q{dotbox},
     q{dotbox_mask},
     q{double_arrow},
     q{double_arrow_mask},
     q{draft_large},
     q{draft_large_mask},
     q{draft_small},
     q{draft_small_mask},
     q{draped_box},
     q{draped_box_mask},
     q{exchange},
     q{exchange_mask},
     q{fleur},
     q{fleur_mask},
     q{gobbler},
     q{gobbler_mask},
     q{gumby},
     q{gumby_mask},
     q{hand1},
     q{hand1_mask},
     q{hand2},
     q{hand2_mask},
     q{heart},
     q{heart_mask},
     q{icon},
     q{icon_mask},
     q{iron_cross},
     q{iron_cross_mask},
     q{left_ptr},
     q{left_ptr_mask},
     q{left_side},
     q{left_side_mask},
     q{left_tee},
     q{left_tee_mask},
     q{leftbutton},
     q{leftbutton_mask},
     q{ll_angle},
     q{ll_angle_mask},
     q{lr_angle},
     q{lr_angle_mask},
     q{man},
     q{man_mask},
     q{middlebutton},
     q{middlebutton_mask},
     q{mouse},
     q{mouse_mask},
     q{pencil},
     q{pencil_mask},
     q{pirate},
     q{pirate_mask},
     q{plus},
     q{plus_mask},
     q{question_arrow},
     q{question_arrow_mask},
     q{right_ptr},
     q{right_ptr_mask},
     q{right_side},
     q{right_side_mask},
     q{right_tee},
     q{right_tee_mask},
     q{rightbutton},
     q{rightbutton_mask},
     q{rtl_logo},
     q{rtl_logo_mask},
     q{sailboat},
     q{sailboat_mask},
     q{sb_down_arrow},
     q{sb_down_arrow_mask},
     q{sb_h_double_arrow},
     q{sb_h_double_arrow_mask},
     q{sb_left_arrow},
     q{sb_left_arrow_mask},
     q{sb_right_arrow},
     q{sb_right_arrow_mask},
     q{sb_up_arrow},
     q{sb_up_arrow_mask},
     q{sb_v_double_arrow},
     q{sb_v_double_arrow_mask},
     q{shuttle},
     q{shuttle_mask},
     q{sizing},
     q{sizing_mask},
     q{spider},
     q{spider_mask},
     q{spraycan},
     q{spraycan_mask},
     q{star},
     q{star_mask},
     q{target},
     q{target_mask},
     q{tcross},
     q{tcross_mask},
     q{top_left_arrow},
     q{top_left_arrow_mask},
     q{top_left_corner},
     q{top_left_corner_mask},
     q{top_right_corner},
     q{top_right_corner_mask},
     q{top_side},
     q{top_side_mask},
     q{top_tee},
     q{top_tee_mask},
     q{trek},
     q{trek_mask},
     q{ul_angle},
     q{ul_angle_mask},
     q{umbrella},
     q{umbrella_mask},
     q{ur_angle},
     q{ur_angle_mask},
     q{watch},
     q{watch_mask},
     q{xterm},
     q{xterm_mask},

    );

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
