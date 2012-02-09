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
    bool enabled = false;
    IBus.LookupTable lookup_table;
    bool preedit_visible = false;
    bool lookup_table_visible = false;

    string preedit = "";
    Fep.GAttribute? preedit_attr;
    string status = "";
    Fep.GAttribute? status_attr;

    void _ibus_commit_text (IBus.Text text) {
        var str = text.get_text ();
        if (str.length > 0)
            send_text (str);
    }

    void _ibus_show_preedit_text () {
        set_cursor_text (preedit, preedit_attr);
        preedit_visible = true;
    }

    void _ibus_hide_preedit_text () {
        set_cursor_text ("", null);
        preedit_visible = false;
    }

    void _ibus_update_preedit_text (IBus.Text text,
                                    uint cursor_pos,
                                    bool visible)
    {
        var _preedit = text.get_text ();
        var attrs = text.get_attributes ();
        Fep.GAttribute? attr = null;
        for (var i = 0; i < attrs.attributes.length; i++) {
            var _attr = attrs.get (i);
            if (_attr.type == IBus.AttrType.UNDERLINE) {
                attr = Fep.GAttribute () {
                    type = Fep.GAttrType.UNDERLINE,
                    value = Fep.GAttrUnderline.SINGLE,
                    start_index = _attr.start_index,
                    end_index = _attr.end_index
                };
            }
        }
        if (preedit != _preedit || preedit_attr != attr ||
            preedit_visible != visible) {
            preedit = _preedit;
            preedit_attr = attr;
            if (visible) {
                _ibus_show_preedit_text ();
            } else {
                _ibus_hide_preedit_text ();
            }
        }
    }

    void update_status () {
        var builder = new StringBuilder ();
        if (enabled) {
            var desc = context.get_engine ();
            builder.append ("[" + desc.symbol + "] ");
        } else {
            builder.append ("[  ] ");
        }
        Fep.GAttribute? attr = null;
        if (lookup_table_visible) {
            var pages = lookup_table.cursor_pos /
                lookup_table.page_size;
            var start = pages * lookup_table.page_size;
            var end = uint.min (
                start + lookup_table.page_size,
                lookup_table.get_number_of_candidates ());
            for (var index = start; index < end; index++) {
                var label = lookup_table.get_label (index);
                var candidate = lookup_table.get_candidate (index);
                var label_text = label != null ?
                    label.get_text () :
                    (index - start + 1).to_string ();
                var text = "%s:%s".printf (label_text,
                                           candidate.get_text ());
                if (lookup_table.is_cursor_visible () &&
                    index == lookup_table.get_cursor_pos ()) {
                    var start_index = builder.str.char_count ();
                    attr = Fep.GAttribute () {
                        type = Fep.GAttrType.STANDOUT,
                        value = 1,
                        start_index = start_index,
                        end_index = start_index + text.char_count ()
                    };
                }
                builder.append (text);
                if (index < end - 1)
                    builder.append_c (' ');
            }
        }
        if (status != builder.str || status_attr != attr) {
            set_status_text (builder.str, attr);
            status = builder.str;
            status_attr = attr;
        }
    }

    void _ibus_show_lookup_table () {
        lookup_table_visible = true;
        update_status ();
    }

    void _ibus_hide_lookup_table () {
        lookup_table_visible = false;
        update_status ();
    }

    void _ibus_update_lookup_table (IBus.LookupTable lookup_table,
                                    bool visible)
    {
        this.lookup_table = lookup_table;
        if (visible)
            _ibus_show_lookup_table ();
        else
            _ibus_hide_lookup_table ();
    }

    void _ibus_enabled () {
        enabled = true;
        update_status ();
    }

    void _ibus_disabled () {
        enabled = false;
        update_status ();
    }

    public override bool filter_key_event (uint keyval,
                                           uint modifiers)
    {
        if (keyval == toggle_keyval &&
            (modifiers & toggle_modifiers) != 0) {
            if (enabled)
                context.disable ();
            else
                context.enable ();
            return true;
        }
        return context.process_key_event (keyval, 0, modifiers);
    }

    bool watch_func (IOChannel source, IOCondition condition) {
        dispatch ();
        return true;
    }

    IBus.Config config;

    uint toggle_keyval = IBus.backslash;
    uint toggle_modifiers = IBus.ModifierType.CONTROL_MASK;

    public Client (IBus.Bus bus) throws Error {
        Object (address: null);
        init (null);

        config = bus.get_config ();
        var values = config.get_values ("fep");
        if (values != null) {
            var value = values.lookup_value ("toggle_shortcut",
                                             VariantType.STRING);
            if (value != null) {
                IBus.key_event_from_string (value.get_string (),
                                            out toggle_keyval,
                                            out toggle_modifiers);
            }
        }

        context = bus.create_input_context ("ibus-fep");
        context.commit_text.connect (_ibus_commit_text);
        context.show_preedit_text.connect (_ibus_show_preedit_text);
        context.hide_preedit_text.connect (_ibus_hide_preedit_text);
        context.update_preedit_text.connect (
            _ibus_update_preedit_text);
        context.show_lookup_table.connect (_ibus_show_lookup_table);
        context.hide_lookup_table.connect (_ibus_hide_lookup_table);
        context.update_lookup_table.connect (
            _ibus_update_lookup_table);
        context.enabled.connect (_ibus_enabled);
        context.disabled.connect (_ibus_disabled);

        context.enable ();
        context.set_capabilities (IBus.Capabilite.PREEDIT_TEXT);

        var channel = new IOChannel.unix_new (get_poll_fd ());
        channel.add_watch (IOCondition.IN, watch_func);
    }
}
