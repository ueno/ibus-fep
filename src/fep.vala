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

class IBusFep {
	public string engine {
		get {
			var desc = context.get_engine ();
			return desc.get_name ();
		}
		set {
			context.set_engine (value);
		}
	}

	Fep.GClient client;
	IBus.InputContext context;
	string preedit;

	void _ibus_commit_text (IBus.Text text) {
		var str = text.get_text ();
		if (str.length > 0)
			client.send_data (str, str.length);
	}

	void _ibus_hide_preedit_text () {
		client.set_cursor_text ("");
	}

	void _ibus_show_preedit_text () {
		client.set_cursor_text (preedit);
	}

	void _ibus_update_preedit_text (IBus.Text text,
									uint cursor_pos,
									bool visible)
	{
		var _preedit = text.get_text ();
		if (visible) {
			if (_preedit != preedit) {
				preedit = _preedit;
				_ibus_show_preedit_text ();
			}
		} else {
			_ibus_hide_preedit_text ();
		}
	}

	void _ibus_enabled () {
		client.set_status_text (engine);
	}

	bool _fep_filter_key_event (uint keyval, uint modifiers) {
		return context.process_key_event (keyval, 0, modifiers);
	}

	public IBusFep (IBus.Bus bus) {
		context = bus.create_input_context ("ibus-fep");
		context.commit_text.connect (_ibus_commit_text);
		context.hide_preedit_text.connect (_ibus_hide_preedit_text);
		context.show_preedit_text.connect (_ibus_show_preedit_text);
		context.update_preedit_text.connect (_ibus_update_preedit_text);
		context.enabled.connect (_ibus_enabled);
		context.enable ();
		context.set_capabilities (IBus.Capabilite.PREEDIT_TEXT);

		client = new Fep.GClient (null, null);
		client.filter_key_event.connect (_fep_filter_key_event);
	}

	bool watch_func (IOChannel source, IOCondition condition) {
		client.dispatch_key_event ();
		return true;
	}

	public void run () {
		var channel = new IOChannel.unix_new (
			client.get_key_event_poll_fd ());
		channel.add_watch (IOCondition.IN, watch_func);

		IBus.main ();
	}
}
