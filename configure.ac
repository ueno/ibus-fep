# vim:set et ts=4:
#
# ibus-fep - IBus client for text terminals (no frame buffer)
#
# Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# if not 1, append datestamp to the version number.
m4_define([package_name], [ibus-fep])
m4_define([ibus_released], [1])
m4_define([ibus_major_version], [1])
m4_define([ibus_minor_version], [4])
m4_define([ibus_micro_version], [2])
m4_define(ibus_maybe_datestamp,
    m4_esyscmd([if test x]ibus_released[ != x1; then date +.%Y%m%d | tr -d '\n\r'; fi]))

m4_define([ibus_version],
    ibus_major_version.ibus_minor_version.ibus_micro_version[]ibus_maybe_datestamp)

AC_INIT([package_name], [ibus_version], [http://github.com/ueno/ibus-fep/issues], [package_name])
AM_INIT_AUTOMAKE([silent-rules])
AC_GNU_SOURCE

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

# define PACKAGE_VERSION_* variables
AM_SANITY_CHECK
AM_MAINTAINER_MODE
AM_DISABLE_STATIC
AC_PROG_CC
AC_PROG_CXX
AM_PROG_CC_C_O
AC_ISC_POSIX
AC_HEADER_STDC
IT_PROG_INTLTOOL([0.35.0])
AM_PROG_LIBTOOL

# For dislpay Date
m4_define(ibus_maybe_datedisplay,
    m4_esyscmd([if test x]ibus_released[ != x1; then date '+%a %b %d %Y' | tr -d '\n\r'; fi]))
m4_define([ibus_datedisplay], ibus_maybe_datedisplay)
DATE_DISPLAY="ibus_datedisplay"
AC_SUBST(DATE_DISPLAY)

# check ibus
PKG_CHECK_MODULES(IBUS, [ibus-1.0 >= 1.4.0], ,
  AC_MSG_ERROR([can't find ibus]))

# check libfep
PKG_CHECK_MODULES(LIBFEP, [libfep-glib >= 0.0.4], ,
  AC_MSG_ERROR([can't find libfep]))

AC_PATH_PROG([FEP], [fep])

# check vala
AM_PROG_VALAC([0.10.0])

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
AC_SUBST(VALAFLAGS)

# define GETTEXT_* variables
GETTEXT_PACKAGE=ibus-fep
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [Define to the read-only architecture-independent data directory.])
AM_GLIB_GNU_GETTEXT

# OUTPUT files
AC_CONFIG_FILES([
Makefile
src/Makefile
po/Makefile.in
])

AC_OUTPUT
