# Copyright 2011 Kevin Ryde


# export '%CURSOR_GLYPH', '@CURSOR_NAME' ?



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
use vars '$VERSION', '@ISA', '%CURSOR_GLYPH', '@CURSOR_NAME', '@EXPORT_OK';

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = ('%CURSOR_GLYPH', '@CURSOR_NAME');

# uncomment this to run the ### lines
use Smart::Comments;

$VERSION = 3;

# cf XmuCursorNameToIndex()

my @CURSOR_NAME
  = (
     # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and do { printf qq{     %-30s # %d\n}, qq{q{$1},}, $i++; printf qq{     %-30s # %d\n}, qq{q{$1_mask},}, $i++;}' </usr/include/X11/cursorfont.h" 'insert)

     q{X_cursor},                   # 0
     q{X_cursor_mask},              # 1
     q{arrow},                      # 2
     q{arrow_mask},                 # 3
     q{based_arrow_down},           # 4
     q{based_arrow_down_mask},      # 5
     q{based_arrow_up},             # 6
     q{based_arrow_up_mask},        # 7
     q{boat},                       # 8
     q{boat_mask},                  # 9
     q{bogosity},                   # 10
     q{bogosity_mask},              # 11
     q{bottom_left_corner},         # 12
     q{bottom_left_corner_mask},    # 13
     q{bottom_right_corner},        # 14
     q{bottom_right_corner_mask},   # 15
     q{bottom_side},                # 16
     q{bottom_side_mask},           # 17
     q{bottom_tee},                 # 18
     q{bottom_tee_mask},            # 19
     q{box_spiral},                 # 20
     q{box_spiral_mask},            # 21
     q{center_ptr},                 # 22
     q{center_ptr_mask},            # 23
     q{circle},                     # 24
     q{circle_mask},                # 25
     q{clock},                      # 26
     q{clock_mask},                 # 27
     q{coffee_mug},                 # 28
     q{coffee_mug_mask},            # 29
     q{cross},                      # 30
     q{cross_mask},                 # 31
     q{cross_reverse},              # 32
     q{cross_reverse_mask},         # 33
     q{crosshair},                  # 34
     q{crosshair_mask},             # 35
     q{diamond_cross},              # 36
     q{diamond_cross_mask},         # 37
     q{dot},                        # 38
     q{dot_mask},                   # 39
     q{dotbox},                     # 40
     q{dotbox_mask},                # 41
     q{double_arrow},               # 42
     q{double_arrow_mask},          # 43
     q{draft_large},                # 44
     q{draft_large_mask},           # 45
     q{draft_small},                # 46
     q{draft_small_mask},           # 47
     q{draped_box},                 # 48
     q{draped_box_mask},            # 49
     q{exchange},                   # 50
     q{exchange_mask},              # 51
     q{fleur},                      # 52
     q{fleur_mask},                 # 53
     q{gobbler},                    # 54
     q{gobbler_mask},               # 55
     q{gumby},                      # 56
     q{gumby_mask},                 # 57
     q{hand1},                      # 58
     q{hand1_mask},                 # 59
     q{hand2},                      # 60
     q{hand2_mask},                 # 61
     q{heart},                      # 62
     q{heart_mask},                 # 63
     q{icon},                       # 64
     q{icon_mask},                  # 65
     q{iron_cross},                 # 66
     q{iron_cross_mask},            # 67
     q{left_ptr},                   # 68
     q{left_ptr_mask},              # 69
     q{left_side},                  # 70
     q{left_side_mask},             # 71
     q{left_tee},                   # 72
     q{left_tee_mask},              # 73
     q{leftbutton},                 # 74
     q{leftbutton_mask},            # 75
     q{ll_angle},                   # 76
     q{ll_angle_mask},              # 77
     q{lr_angle},                   # 78
     q{lr_angle_mask},              # 79
     q{man},                        # 80
     q{man_mask},                   # 81
     q{middlebutton},               # 82
     q{middlebutton_mask},          # 83
     q{mouse},                      # 84
     q{mouse_mask},                 # 85
     q{pencil},                     # 86
     q{pencil_mask},                # 87
     q{pirate},                     # 88
     q{pirate_mask},                # 89
     q{plus},                       # 90
     q{plus_mask},                  # 91
     q{question_arrow},             # 92
     q{question_arrow_mask},        # 93
     q{right_ptr},                  # 94
     q{right_ptr_mask},             # 95
     q{right_side},                 # 96
     q{right_side_mask},            # 97
     q{right_tee},                  # 98
     q{right_tee_mask},             # 99
     q{rightbutton},                # 100
     q{rightbutton_mask},           # 101
     q{rtl_logo},                   # 102
     q{rtl_logo_mask},              # 103
     q{sailboat},                   # 104
     q{sailboat_mask},              # 105
     q{sb_down_arrow},              # 106
     q{sb_down_arrow_mask},         # 107
     q{sb_h_double_arrow},          # 108
     q{sb_h_double_arrow_mask},     # 109
     q{sb_left_arrow},              # 110
     q{sb_left_arrow_mask},         # 111
     q{sb_right_arrow},             # 112
     q{sb_right_arrow_mask},        # 113
     q{sb_up_arrow},                # 114
     q{sb_up_arrow_mask},           # 115
     q{sb_v_double_arrow},          # 116
     q{sb_v_double_arrow_mask},     # 117
     q{shuttle},                    # 118
     q{shuttle_mask},               # 119
     q{sizing},                     # 120
     q{sizing_mask},                # 121
     q{spider},                     # 122
     q{spider_mask},                # 123
     q{spraycan},                   # 124
     q{spraycan_mask},              # 125
     q{star},                       # 126
     q{star_mask},                  # 127
     q{target},                     # 128
     q{target_mask},                # 129
     q{tcross},                     # 130
     q{tcross_mask},                # 131
     q{top_left_arrow},             # 132
     q{top_left_arrow_mask},        # 133
     q{top_left_corner},            # 134
     q{top_left_corner_mask},       # 135
     q{top_right_corner},           # 136
     q{top_right_corner_mask},      # 137
     q{top_side},                   # 138
     q{top_side_mask},              # 139
     q{top_tee},                    # 140
     q{top_tee_mask},               # 141
     q{trek},                       # 142
     q{trek_mask},                  # 143
     q{ul_angle},                   # 144
     q{ul_angle_mask},              # 145
     q{umbrella},                   # 146
     q{umbrella_mask},              # 147
     q{ur_angle},                   # 148
     q{ur_angle_mask},              # 149
     q{watch},                      # 150
     q{watch_mask},                 # 151
     q{xterm},                      # 152
     q{xterm_mask},                 # 153
    );
### @CURSOR_NAME


%CURSOR_GLYPH
  = (
     # (shell-command "perl -n -e '/define XC_([^ ]*).*?([0-9]+)/ and $1 ne q{num_glyphs} and printf qq{     %-25s => %s,\n     %-25s => %s,\n},$1.q{_mask},$2,$1,$2+1' </usr/include/X11/cursorfont.h" 'insert)

     map {$CURSOR_NAME[$_] => $_} 0 .. $#CURSOR_NAME
    );
### %CURSOR_GLYPH

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
