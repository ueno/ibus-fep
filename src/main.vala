/*
 * Copyright (C) 2012 Daiki Ueno <ueno@unixuser.org>
 * Copyright (C) 2012 Red Hat, Inc.
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

string? opt_preedit_style = null;

const OptionEntry entries[] = {
    { "preedit-style", 's', 0, OptionArg.STRING,
      out opt_preedit_style,
      "Preedit style (default: over-the-spot)", "[root]" },
    { null }
};

static void close_child (Pid pid, int status) {
    Process.close_pid (pid);
    IBus.quit ();
}

static int main (string[] args) {
    EnumClass preedit_style_class = (EnumClass) typeof(PreeditStyle).class_ref ();
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    var context = new OptionContext (
        _("[-- COMMAND...]  - IBus client for text terminals"));
    context.add_main_entries (entries, "ibus-fep");

    stderr.printf("\n\n"); /* hack to show the first line */
    try {
        context.parse (ref args);
    } catch (OptionError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    Options opts = Options () { preedit_style = PreeditStyle.DEFAULT };
    if (opt_preedit_style != null) {
        EnumValue? evalue = preedit_style_class.get_value_by_nick (
            opt_preedit_style);
        if (evalue == null) {
            stderr.printf (_("unknown preedit style %s"), opt_preedit_style);
            return 1;
        }
        opts.preedit_style = (PreeditStyle) evalue.value;
    }
        
    IBus.init ();
    var bus = new IBus.Bus ();
    if (!bus.is_connected ()) {
        stderr.printf (_("ibus-daemon is not running\n"));
        return 1;
    }

    string[]? argv;
    if (args.length > 1) {
        argv = args[1 : args.length];
    } else {
        argv = { Environment.get_variable ("SHELL") };
    }

    try {
        Pid pid;
        if (Process.spawn_async (
                null, argv, null,
                SpawnFlags.DO_NOT_REAP_CHILD |
                SpawnFlags.CHILD_INHERITS_STDIN |
                SpawnFlags.SEARCH_PATH,
                null, out pid))
            ChildWatch.add (pid, close_child);
    } catch (SpawnError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    Client client;
    try {
        client = new Client (bus, opts);
    } catch (Error e) {
        stderr.printf (_("can't create client: %s\n"), e.message);
        return 1;
    }

    IBus.main ();

    return 0;
}
