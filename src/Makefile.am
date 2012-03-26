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

libexec_PROGRAMS = ibus-fep-client

ibus_fep_client_VALAFLAGS =			\
	--vapidir=$(srcdir)			\
	--pkg config				\
	--pkg ibus-1.0				\
	--pkg libfep-glib			\
	--pkg posix				\
	$(VALAFLAGS)

if IBUS_1_5
ibus_fep_client_VALAFLAGS += -D IBUS_1_5
endif

ibus_fep_client_CFLAGS =			\
	$(IBUS_CFLAGS)				\
	$(LIBFEP_CFLAGS)			\
	-DLOCALEDIR=\"$(datadir)/locale\"	\
	$(NULL)

ibus_fep_client_LDADD =				\
	$(IBUS_LIBS)				\
	$(LIBFEP_LIBS)				\
	$(NULL)

ibus_fep_client_SOURCES = client.vala main.vala

GITIGNOREFILES =				\
	$(ibus_fep_client_SOURCES:.vala=.c)	\
	ibus_fep_client_vala.stamp		\
	$(NULL)

EXTRA_DIST = config.vapi ibus-1.0.deps ibus-1.0.vapi ibus-fep.in
DISTCLEANFILES = ibus-fep

bin_SCRIPTS = ibus-fep

ibus-fep: ibus-fep.in
	$(AM_V_GEN) sed -e "s!@FEP\@!"$(FEP)"!" \
	-e "s!@CLIENT\@!"$(libexecdir)/ibus-fep-client"!" \
	$< > $@.tmp && \
	mv $@.tmp $@

dist_man_MANS = ibus-fep.1

-include $(top_srcdir)/git.mk
