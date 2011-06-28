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

CFLAGS = -Wall -g
LOADLIBES = -lXss -lX11

all: encode-emacs22.ctext encode-emacs22-ext.ctext \
	encode-emacs23.ctext encode-emacs23-ext.ctext \
	encode-xemacs21.ctext
# encode-emacs21.ctext encode-emacs21-ext.ctext \

encode-emacs21.ctext encode-emacs21-ext.ctext: encode-all.el
	emacs21 -q -batch -l encode-all.el -f my-ctext 
encode-emacs22.ctext encode-emacs22-ext.ctext: encode-all.el
	emacs22 -q -batch -l encode-all.el -f my-ctext 
encode-emacs23.ctext encode-emacs23-ext.ctext: encode-all.el
	emacs23 -q -batch -l encode-all.el -f my-ctext 
encode-xemacs21.ctext: encode-all.el
	xemacs21 -q -batch -l encode-all.el -f my-ctext 




encode-dump: encode-dump.c Makefile
	$(CC) $(CFLAGS) encode-dump.c -lX11 -o encode-dump

Encode-X11-xlib: Encode-X11-xlib.c Makefile
	$(CC) $(CFLAGS) Encode-X11-xlib.c -lX11 -o Encode-X11-xlib
Encode-X11-xlib2: Encode-X11-xlib2.c Makefile
	$(CC) $(CFLAGS) Encode-X11-xlib2.c -lX11 -o Encode-X11-xlib2
