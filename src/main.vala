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

public class Options {
    public string? style = null;
    public bool dontsave = false;
    public bool dontload = false;
    public OptionEntry[] entries;
    public OptionContext option_context;
    public Options () {
        option_context = new OptionContext (
            _("[-- COMMAND...]  - IBus client for text terminals"));
        OptionEntry e_style = {"style", 's', 0, OptionArg.STRING,
            out this.style, "Input style (default: over-the-spot)", "[root]"};
        OptionEntry e_temp = {"temp", 't', 0, OptionArg.NONE,
            out this.dontsave, "Don't save settings", null};
        OptionEntry e_noconf = {"noconf", 'n', 0, OptionArg.NONE,
            out this.dontload, "Don't load settings (implies --temp)", null};
        OptionEntry e_null = {null};
        option_context.add_main_entries ({e_style, e_temp, e_noconf, e_null},
            "ibus-fep");
    }
}

static void close_child (Pid pid, int status) {
    Process.close_pid (pid);
    IBus.quit ();
}

static int main (string[] args) {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Config.GETTEXT_PACKAGE);

    var o = new Options ();
    stderr.printf("\n\n"); /* hack to show the first line */
    try {
        o.option_context.parse (ref args);
    } catch (OptionError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    string[] argv = {};
    if (args.length > 1) {
        for (int i = 1; i < args.length; i++)
                argv += args[i];
    }
    if (argv.length == 0)
        argv += Environment.get_variable ("SHELL");
    try {
        Pid pid;
        if (Process.spawn_async_with_pipes
                (null, argv, null, SpawnFlags.DO_NOT_REAP_CHILD |
                 SpawnFlags.CHILD_INHERITS_STDIN | SpawnFlags.SEARCH_PATH,
                 null, out pid, null, null, null))
            ChildWatch.add (pid, close_child);
    } catch (SpawnError e) {
        stderr.printf ("%s\n", e.message);
        return 1;
    }

    IBus.init ();
    var bus = new IBus.Bus ();
    if (!bus.is_connected ()) {
        stderr.printf (_("ibus-daemon is not running\n"));
        return 1;
    }

    IBus.Config config = bus.get_config ();
    if (o.dontload == false) {
        if (o.style == null) {
            Variant? values = config.get_values ("fep");
            if (values != null) {
                /* FIXME: should iterate and check for "style" */
                Variant? v = config.get_value ("fep", "style");
                if (v != null) {
                    o.style = v.get_string ();
                }
            }
        }
        if (o.dontsave == false) {
            if (o.style != "root")
                o.style = "over-the-spot";
            config.set_value ("fep", "style", o.style);
        }
    }

    Client client;
    try {
        client = new Client (bus, o);
    } catch (Error e) {
        stderr.printf (_("can't create client: %s\n"), e.message);
        return 1;
    }

    IBus.main ();

    return 0;
}
