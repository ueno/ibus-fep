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

enum PreeditStyle {
    OVER_THE_SPOT,
    ROOT,
    DEFAULT = OVER_THE_SPOT
}

struct Options {
    public PreeditStyle preedit_style;
}

class Client : Fep.GClient {
    IBus.InputContext context = null;
    IBus.LookupTable lookup_table;
    bool preedit_visible = false;
    bool lookup_table_visible = false;
    Options opts;

    string preedit = "";
    Fep.GAttribute? preedit_attr;
    string status = "";
    Fep.GAttribute? status_attr;

#if !IBUS_1_5
    bool enabled = false;
#endif

    void _ibus_commit_text (IBus.Text text) {
        var str = text.get_text ();
        if (str.length > 0)
            send_text (str);
    }

    void _ibus_show_preedit_text () {
        if (opts.preedit_style == PreeditStyle.ROOT) {
            set_status_text (preedit, preedit_attr);
            status = preedit;
            status_attr = preedit_attr;
        } else
            set_cursor_text (preedit, preedit_attr);
        preedit_visible = true;
    }

    void _ibus_hide_preedit_text () {
        if (opts.preedit_style == PreeditStyle.ROOT)
            update_status ();
        else
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

    string format_indicator () {
        var desc = context.get_engine ();
        if (desc != null) {
            var symbol = desc.symbol;
            if (symbol.length == 0) {
                symbol = (desc.name.up () + "??").substring (0, 2);
            }
            return "[" + symbol + "] ";
        } else {
            return "[??] ";
        }
    }

    void update_status () {
        var builder = new StringBuilder ();

        // on ibus-1.5, context has always an active engine
#if IBUS_1_5
        builder.append (format_indicator ());
#else
        if (enabled) {
            builder.append (format_indicator ());
        } else {
            builder.append ("[  ] ");
        }
#endif

        Fep.GAttribute? attr = null;
        if (lookup_table_visible) {
            var pages = lookup_table.cursor_pos /
                lookup_table.page_size;
            var start = pages * lookup_table.page_size;
            var end = uint.min (
                start + lookup_table.page_size,
                lookup_table.get_number_of_candidates ());
            for (var index = start; index < end; index++) {
                var label = lookup_table.get_label (index - start);
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
        // When root style, need to recover the previous preedit text
        // shown at the status area.
        if (opts.preedit_style == PreeditStyle.ROOT && preedit_visible)
            _ibus_show_preedit_text ();
        else
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

#if IBUS_1_5
    void _ibus_global_engine_changed (string name) {
        update_status ();
    }
#else
    void _ibus_enabled () {
        enabled = true;
        update_status ();
    }

    void _ibus_disabled () {
        enabled = false;
        update_status ();
    }
#endif

    public override bool filter_event (Fep.GEvent e) {
        switch (e.any.type) {
        case Fep.GEventType.KEY_PRESS:
            if (context != null) {
                context.process_key_event_async.begin (
                    e.key.keyval, 0, e.key.modifiers,
                    -1, null,
                    (obj, res) => {
                        var retval = false;
                        try {
                            retval = context.process_key_event_async_finish (res);
                        } catch (GLib.Error e) {
                        }
                        if (!retval)
                            send_data (e.key.source, e.key.source_length);
                    });
                update_status ();
            }
            return true;
        default:
            break;
        }
        return false;
    }

    bool watch_func (IOChannel source, IOCondition condition) {
        dispatch ();
        return true;
    }

    void create_input_context_done () {
        context.commit_text.connect (_ibus_commit_text);
        context.show_preedit_text.connect (_ibus_show_preedit_text);
        context.hide_preedit_text.connect (_ibus_hide_preedit_text);
        context.update_preedit_text.connect (
            _ibus_update_preedit_text);
        context.show_lookup_table.connect (_ibus_show_lookup_table);
        context.hide_lookup_table.connect (_ibus_hide_lookup_table);
        context.update_lookup_table.connect (
            _ibus_update_lookup_table);

        context.set_capabilities (IBus.Capabilite.PREEDIT_TEXT |
                                  IBus.Capabilite.LOOKUP_TABLE |
                                  IBus.Capabilite.AUXILIARY_TEXT |
                                  IBus.Capabilite.FOCUS);
        context.focus_in ();

#if IBUS_1_5
        // on ibus-1.5, context has always an active engine
        update_status ();
#else
        // on ibus-1.4, need to track enable/disable of context
        context.enabled.connect (_ibus_enabled);
        context.disabled.connect (_ibus_disabled);
        context.enable ();
#endif
    }

    public Client (IBus.Bus bus, Options opts) throws Error {
        Object (address: null);
        init (null);
        this.opts = opts;

#if IBUS_1_5
        bus.global_engine_changed.connect (_ibus_global_engine_changed);
#endif
        bus.create_input_context_async ("ibus-fep", -1, null, (obj, res) => {
                try {
                    context = bus.create_input_context_async_finish (res);
                    create_input_context_done ();
                } catch (Error e) {
                    warning ("can't create input context: %s", e.message);
                }
            });

        var channel = new IOChannel.unix_new (get_poll_fd ());
        channel.add_watch (IOCondition.IN, watch_func);
    }
}
