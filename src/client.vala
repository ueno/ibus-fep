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

class Client : Fep.GClient {
    public string engine {
        get {
            var desc = context.get_engine ();
            return desc.get_name ();
        }
        set {
            context.set_engine (value);
        }
    }

    IBus.InputContext context;
    string preedit;
    bool preedit_visible;

    void _ibus_commit_text (IBus.Text text) {
        var str = text.get_text ();
        if (str.length > 0)
            send_data (str, str.length);
    }

    void _ibus_hide_preedit_text () {
        set_cursor_text ("");
        preedit_visible = false;
    }

    void _ibus_show_preedit_text () {
        set_cursor_text (preedit);
        preedit_visible = true;
    }

    void _ibus_update_preedit_text (IBus.Text text,
                                    uint cursor_pos,
                                    bool visible)
    {
        var _preedit = text.get_text ();
        if (_preedit != preedit || preedit_visible != visible) {
            preedit = _preedit;
            if (visible) {
                _ibus_show_preedit_text ();
            } else {
                _ibus_hide_preedit_text ();
            }
        }
    }

    void _ibus_enabled () {
        set_status_text (engine);
    }

    public override bool filter_key_event (uint keyval, uint modifiers) {
        return context.process_key_event (keyval, 0, modifiers);
    }

    bool watch_func (IOChannel source, IOCondition condition) {
        dispatch ();
        return true;
    }

    public Client (IBus.Bus bus) throws Error {
        Object (address: null);
        init (null);

        context = bus.create_input_context ("ibus-fep");
        context.commit_text.connect (_ibus_commit_text);
        context.hide_preedit_text.connect (_ibus_hide_preedit_text);
        context.show_preedit_text.connect (_ibus_show_preedit_text);
        context.update_preedit_text.connect (_ibus_update_preedit_text);
        context.enabled.connect (_ibus_enabled);
        context.enable ();
        context.set_capabilities (IBus.Capabilite.PREEDIT_TEXT);

        var channel = new IOChannel.unix_new (get_poll_fd ());
        channel.add_watch (IOCondition.IN, watch_func);
    }
}
