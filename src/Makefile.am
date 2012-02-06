# Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
# Copyright (C) 2012 Red Hat, Inc.

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

# force include config.h before gi18n.h.
AM_CPPFLAGS = -include $(CONFIG_HEADER)

pkglibexec_PROGRAMS = fep

fep_VALAFLAGS =					\
	--vapidir=$(srcdir)			\
	--pkg config				\
	--pkg ibus-1.0				\
	--pkg libfep-glib			\
	--pkg posix				\
	$(VALAFLAGS)

fep_CFLAGS =					\
	$(IBUS_CFLAGS)				\
	$(LIBFEP_CFLAGS)			\
	-DLOCALEDIR=\"$(datadir)/locale\"	\
	$(NULL)

fep_LDADD =					\
	$(IBUS_LIBS)				\
	$(LIBFEP_LIBS)				\
	$(NULL)

fep_SOURCES = fep.vala main.vala

GITIGNOREFILES =				\
	$(fep_SOURCES:.vala=.c)			\
	fep_vala.stamp				\
	$(NULL)

EXTRA_DIST = config.vapi ibus-1.0.deps ibus-1.0.vapi ibus-fep.in fep.wrapper.in
DISTCLEANFILES = ibus-fep fep.wrapper

feplibexecdir = $(pkglibexecdir)
feplibexec_SCRIPTS = fep.wrapper

bin_SCRIPTS = ibus-fep

ibus-fep: ibus-fep.in
	$(AM_V_GEN) sed -e "s!@FEP\@!"$(FEP)"!" \
	-e "s!@WRAPPER\@!"$(pkglibexecdir)/fep.wrapper"!" \
	$< > $@.tmp && \
	mv $@.tmp $@

fep.wrapper: fep.wrapper.in
	$(AM_V_GEN) sed -e "s!@FEP\@!"$(pkglibexecdir)/fep"!" \
	$< > $@.tmp && \
	mv $@.tmp $@

-include $(top_srcdir)/git.mk
