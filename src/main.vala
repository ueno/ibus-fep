/*
 * Copyright (C) 2011-2012 Daiki Ueno <ueno@unixuser.org>
 * Copyright (C) 2011-2012 Red Hat, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

static string engine;

const OptionEntry[] options = {
    {"engine", '\0', 0, OptionArg.STRING, ref engine,
     N_("Engine name"), null },
    { null }
};

static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    var option_context = new OptionContext (
        _("- use IBus input method on text terminal"));
    option_context.add_main_entries (options, "ibus-fep");
    try {
        option_context.parse (ref args);
    } catch (OptionError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    if (engine == null) {
        stderr.printf ("please specify engine name with --engine\n");
        return 1;
    }
        
    IBus.init ();
    var bus = new IBus.Bus ();
    if (!bus.is_connected ()) {
        stderr.printf ("ibus-daemon is not running\n");
        return 1;
    }

    var fep = new IBusFep (bus);
    fep.engine = engine;
    fep.run ();

    return 0;
}
