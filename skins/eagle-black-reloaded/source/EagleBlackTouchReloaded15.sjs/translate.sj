// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Translations
//
// German translation by Joachim Müller
//
// Usage:    tt.id
//           - aborts with error for unknown id
//
//           tt['id']
//           - returns undefined value for unknown id
//
//           t('id')
//           t('id', var1)
//           t('id', var1, var2)
//
//           - returns '<<id_phrase>>' for unknown id
//           - var1 and var2 replace %1 and %2 placeholders
//
// ************************************************************


//***************** globals *********************************

var tt = new Object;

var tt1 = new RegExp("%1", "gi");
var tt2 = new RegExp("%2", "gi");

//***************** functions ********************************

function t(id, v1, v2)
{
    var txt = tt[id];

print(id + " / " + v1 + " / " + v2);
    if (txt == undefined) return "<<" + id + ">>";

    if (v1 == undefined) return txt;
    txt = txt.replace(tt1, v1);

    if (v2 == undefined) return txt;
    txt = txt.replace(tt2, v2);

    return txt;
}


function TranslateInit()
{
    tt.yes = "Yes";
    tt.no = "No";
    tt.configuration = "Configuration";
    tt.layout_configuration = "Layout Configuration";
    tt.configuration_version_warning_1 = "The previous configuration of this skin was stored by:";
    tt.configuration_version_warning_2 = "Please verify the next dialog to see if everything is set up to your liking";
    tt.program_version_warning = "Silverjuke version must be at least 2.73r2";
    tt.settings_incorrect = "WARNING - the following settings are incorrect for this skin:";
    tt.ask_confirmation_before_queing_or_playing = "Ask confirmation before queing or playing?";
    tt.allow_queing_of_complete_albums = "Allow queueing of complete albums?";
    tt.allow_search_beyond_kiosk_music_selection = "Allow search beyond kiosk music selection?";
    tt.no_limit_search_as_well ="No, limit search as well";
    tt.yes_search_full_library = "Yes, search full library";
    tt.search_after_each_character = "Search after each character";
    tt.no_wait_for_enter_key = "No, wait for timeout or enter key";
    tt.idle_time = "Idle time after which to jump to main screen (sec)";
    tt.karaoke_music_selection = "Karaoke music selection";
    tt.apply_kiosk_restrictions_in_window_mode = "In windowed mode apply same restrictions as in kioskmode?";
    tt.cache_album_art_on_startup = "Cache all album art upon startup?";
    tt.optimize_for_hires = "Optimize display for screen resolutions higher than 1024 x 768?";
    tt.relevant_silverjuke_settings = "Relevant Silverjuke settings:";
    tt.max_tracks_in_queue = "Maximum number of tracks in queue";
	tt.limit_max_tracks_in_queue = "Limit maximum number of tracks in queue";
    tt.idle_time_before_visualization = "Idle time before visualization starts (0 to disable):";
    tt.tracks_limited_to_music_selection = "Tracks limited to music selection:";
    tt.none = "none";
    tt.avoid_double_tracks_in_queue = "Avoid double tracks in queue";
    tt.pause = "Pause";
    tt.keyboard_layout = "Keyboard layout:";
    tt.prefered_cover = "Prefered cover:";
    tt.track = "track";
    tt.tracks = "tracks";
    tt.album = "album";
    tt.albums = "albums";
    tt.artist = "artist";
    tt.artists = "artists";
	tt.black_touch_fork = "Eagle Black Touch Reloaded is based on the great skin EagleBlueTouch by SilverEagle and has been modified by Joachim Müller\nas far as the looks and particular functionality is concerned.\nDetails about the changes can be reviewed in the announcement-trhead or the changelog.txt file that comes with the skin.";
    tt.eagle_library_explanation = "This skin uses the EagleTools library to replace some of Silverjuke's built-in behaviour.\nIf you run into display or music library related problems please verify them using the default\n'Silverness' skin and/or report them to the link below before posting on the general forum."; // Don't replace the \n - they are linebreak commands
    tt.black_touchsupport = "Click this link for updates and support";
    tt.black_touchcopyrights = "This skin and the EagleTools library (c) SilverEagle";
    tt.silverjuke_copyrights = "Silverjuke (c) Bjoern Petersen Software Design and Development";
    tt.ok = "OK";
    tt.cannot_queue_x = "Cannot queue %1"; // %1 is either the album or the track
    tt.queue_size_limited_to_x = "Queue size limited to %1 tracks"; // %1 is the number of tracks
    tt.already_in_queue = "Already in queue";
    tt.no_more_credits = "Not enough credits";
    tt.track_already_in_queue = "Track(s) already in queue";
    tt.total_length = "Total length";
    tt.song = "track";
    tt.songs = "tracks";
    tt.play_this_x = "Play this %1?"; // %1 is either the album or the track
    tt.queue_this_x = "Queue this %1?"; // %1 is either the album or the track
    tt.cover_layout = "Covers layout";
    tt.cover_images_size = "Cover images size (default 150)";
    tt.album_fontsize = "Album/Artist fontsize (default 20)";
    tt.border_around_covers = "Use border around individual covers";
    tt.various = "Various";
    tt.tracks_in_queue = "next";
    tt.x_track_more = "%1 more"; // %1 is the number of tracks
    tt.x_tracks_more = "%1 more"; // %1 is the number of tracks
    tt.welcome = "WELCOME";
    tt.tap_any_album_to_select = "tap any album to select";
    tt.pausing = "PAUSING";
    tt.tap_this_area_to_continue = "tap this area to continue";
    tt.back = "Back";
    tt.clear ="Clear";
    tt.shift = "Shift";
    tt.anywhere = "anywhere";
    tt.tracks_layout = "Tracks layout";
    tt.cover_image_size = "Cover image size (default 200)";
    tt.track_fontsize = "Track fontsize (default 20)";
    tt.x_more_tracks_available = "%1 more tracks";
	tt.one_more_track_available = "1 more track";
    tt.type_any_key_to_start_searching_all = "(type any key to start searching)";
    tt.type_any_key_to_start_searching_x = "(type any key to start searching in %1)"; // %1 is either anything, artist, song or album
    tt.tap_ok_to_run_search = "(Tap 'OK' to run search)";
    tt.no_matches_found = "(no matches found)";
    tt.search_for_all = "Searching for";
    tt.search_for_x = "Searching in %1 for";
    tt.results_x_tracks_in_y_albums = "found %1 in %2"; // %1 is amount of tracks, %2 amount of albums
	tt.caching_album_art = "Caching album art";
	tt.touch_anywhere_to_abort = "Touch the screen anywhere to abort.";
	tt.display_year = "Display year?";
	tt.fontface = "Font";
	tt.font_warning = "only enter font name that actually exists on your machine";
	tt.screen_has_no_config_options = "This screen doesn't have any configuration options";
	tt.cant_open_keyboard_layout = "Cannot open keyboard layout %1";
	tt.number_abbreviation = "No.";
	tt.search_layout = "Search layout";
	tt.artist_album_track_fontsize = "Artist/Album/Track fontsize (default 20)";
	tt.volume_preset = "Volume preset for kiosk mode";
	tt.no_preset = "No preset";
	tt.touch_to_abort = "Touch screen anywhere to abort caching";
	tt.has_been_queued = "%1 (%2) queued";
	tt.album_track_counter_display = "Album track counter display";
	tt.never = "Never";
	tt.always = "Always";
	tt.depending_on_confirmation_level = "Depending on confirmation level";
	tt.hide_queue = "Hide queue";
	tt.album_tracknumbers = "Album track counter display size (Default 14)";
	tt.disabled = "disabled";
	tt.search = "Search";
	tt.toggle_time_display = "Time display";
	tt.display_rating = "Display rating";
	tt.display_genre = "Display genre";
	tt.kiosk_mode_functionality = "Kiosk mode -> Functionality";
	tt.playback_queue = "Playback -> Queue";
	tt.playback_automatic_control_additional_options = "Playback -> Automatic control -> Additional options...";
	tt.settings = "Settings";
	tt.credits = "Credits:";
	tt.volume = "Volume";
	tt.edit_queue = "Edit queue";
	tt.enable_webradio = "Enable webradio";
	tt.currently_playing = "Currently playing";
	tt.queue_pos_is = "Queue pos # %1";  // %1 is position
	tt.remove_tracks_from_queue = "Remove tracks from queue";
	tt.could_not_create_webradio_file = "Could not create necessary webradio file in Silverjuke folder.";
	tt.make_sure_to_have_write_permissions = "Make sure that you have got write permissions on that folder.";
	tt.mplayer_not_found = "The webradio file mplayer.exe hasn't been found inside the silverjuke folder.";
	tt.edit_webradio_station = "Edit Webradio station %1";
	tt.create_new_webradio_station = "Create new webradio station";
	tt.station_name = "Station name";
	tt.webradio_url = "Webradio URL";
	tt.country_code = "Country code";
	tt.locale = "Locale";
	tt.genre = "Genre";
	tt.icon ="Icon";
	tt.radio_layout = "Radio-Darstellung";
	tt.radio_images_size = "Radio station icon size (default 150)";
    tt.fontsize = "Fontsize (default 20)";
	tt.add = "Add";
	tt.save = "Save";
	tt.cancel = "Cancel";
	tt.delete_all_radio_stations = "Delete all radio stations";
	tt.add_default_radio_stations_to_database = "Add all available default radio stations to database";
	tt.favorite = "Favorite";
	tt.too_many_radio_station_records = "You have more than %1 radio station records in your database.";
	tt.delete_records_before_adding_new_ones = "You will have to delete existing records before being able to add more.";
	tt.webradio_cant_be_enabled = "Webradio can not be enabled, because mplayer.exe doesn't reside inside the silverjuke folder. Refer to the announcement below for details.";
	tt.webradio_announcement_thread = "Webradio announcement thread";


    switch (program.locale)
    {
    case "de":
    case "de_DE":
        tt.yes = "Ja";
        tt.no = "Nein";
        tt.configuration = "Einstellungen";
        tt.layout_configuration = "Layout-Einstellungen";
        tt.configuration_version_warning_1 = "Die vorherigen Einstellungen dieses Skins wurden gespeichert durch:";
        tt.configuration_version_warning_2 = "Bitte überprüfe den nächsten Dialog, um sicherzustellen, dass alles zufriedenstellend istt.";
        tt.program_version_warning = "Silverjuke version muss mindestens 2.73r2 sein";
        tt.settings_incorrect = "ACHTUNG - die folgenden Einstelllungen sind NICHT richtig für diesen Skin:";
        tt.ask_confirmation_before_queing_or_playing = "Bestätigung vor Wiedergabe oder Aufnahme in Warteschlange anzeigen?";
        tt.allow_queing_of_complete_albums = "Erlaube Aufnahme ganzer Alben in die Warteschlange?";
        tt.allow_search_beyond_kiosk_music_selection = "Erweitern der Suche jenseits der Musikauswahl des Kiosk-Modus erlauben?";
        tt.no_limit_search_as_well ="Nein, Suche ebenfalls einschränken";
        tt.yes_search_full_library = "Ja, durchsuche gesamtes Musikarchiv";
        tt.search_after_each_character = "Nach jedem Tastenanschlag suchen";
        tt.no_wait_for_enter_key = "Nein, auf Timeout oder Betätigung durch Enter-Taste warten";
        tt.idle_time = "Leerlaufzeit, nach der zum Hauptbildschirm gesprungen wird (Sek)";
        tt.karaoke_music_selection = "Karaoke-Musikauswahl";
        tt.apply_kiosk_restrictions_in_window_mode = "Im Fenster-Modus die gleichen Beschränkungen anwenden wie im Kiosk-Modus?";
        tt.cache_album_art_on_startup = "Vorschaubilder für Alben beim Programmstart cachen?";
        tt.optimize_for_hires = "Anzeige optimieren für Auflösung größer 1024 x 768?";
        tt.relevant_silverjuke_settings = "Relevante Silverjuke-Einstellungen:";
        tt.max_tracks_in_queue = "Maximalanzahl von Titeln in Warteschlange";
		tt.limit_max_tracks_in_queue = "Maximalanzahl von Titeln in Warteschlange einschränken";
        tt.idle_time_before_visualization = "Wartezeit vor Visualisierungsbeginn (0 zum deaktivieren):";
        tt.tracks_limited_to_music_selection = "Titel auf Musikauswahl begrenzen:";
        tt.none = "keine";
        tt.avoid_double_tracks_in_queue = "Vermeide doppelte Titel in Warteschlange";
        tt.pause = "Pause";
        tt.keyboard_layout = "Tastatur-Layout:";
        tt.prefered_cover = "Bevorzugtes Cover:";
        tt.track = "Titel";
        tt.tracks = "Titel";
        tt.album = "Album";
        tt.albums = "Alben";
        tt.artist = "Künstler";
        tt.artists = "Künstler";
		tt.black_touch_fork = "Eagle Black Touch Reloaded basiert auf dem großartigen Skin EagleBlueTouch von SilverEagle und wurde durch Joachim Müller modifiziert,\nwas Aussehen und Funktionalität angeht.\nDetails der Veränderungen kann im Ankündigungs-Thread bzw. in der im Skin enthaltenen changelog.txt Datei eingesehen werden.";
        tt.eagle_library_explanation = "Dieser Skin benutzt die EagleTools-Bibliothek, um Teile der in Silverjuke eingebauten Funktionalität zu ersetzen.\nSollten Probleme mit der Anzeige oder dem Musikarchiv auftreten sollten bitte zuerst mit dem Standard-Skin\n'Silverness' überkreuz prüfen und/oder unter untenstehendem Link posten bevor Du im allgemeinen Forum das Problem beschreibst."; // Don't replace the \n - they are linebreak commands
        tt.black_touchsupport = "Hier klicken für Updates und Support";
        tt.black_touchcopyrights = "Dieser Skin und die EagleTools-Bibliothek unterliegen dem Urheberrecht von SilverEagle.";
        tt.silverjuke_copyrights = "Silverjuke (c) Björn Petersen Software Design and Developmentt.";
        tt.ok = "OK";
        tt.cannot_queue_x = "%1 kann nicht hinzugefügt werden."; // %1 is either the album or the track
        tt.queue_size_limited_to_x = "Die Warteschlange ist auf %1 Titel begrenzt."; // %1 is the number of tracks
        tt.already_in_queue = "Bereits in Warteschlange.";
        tt.no_more_credits = "Nicht genug Kredits vorhanden.";
        tt.track_already_in_queue = "Titel bereits in Warteschlange vorhanden.";
        tt.total_length = "Gesamtlänge";
        tt.song = "Lied";
        tt.songs = "Lieder";
        tt.play_this_x = "%1 wiedergeben?"; // %1 is either the album or the track
        tt.queue_this_x = "%1 zu Warteschlange hinzufügen?"; // %1 is either the album or the track
        tt.cover_layout = "Cover-Darstellung";
        tt.cover_images_size = "Coverbild-Größe (Standard 150)";
        tt.album_fontsize = "Album/Künstler Schriftgrad (Standard 20)";
        tt.border_around_covers = "Rahmen um individuelle Cover";
        tt.various = "Verschiedene";
        tt.tracks_in_queue = "Titel in Warteschlange";
        tt.x_track_more = "%1 weiterer Titel"; // %1 is the number of tracks
        tt.x_tracks_more = "%1 weitere Titel"; // %1 is the number of tracks
        tt.welcome = "Willkommen";
        tt.tap_any_album_to_select = "Beliebiges Album berühren zum Auswählen";
        tt.pausing = "PAUSE";
        tt.tap_this_area_to_continue = "Diesen Bereich berühren, um fortzufahren";
        tt.back = "zurück";
        tt.clear ="Löschen";
        tt.shift = "Groß";
        tt.anywhere = "überall";
        tt.tracks_layout = "Titel-Darstellung";
        tt.cover_image_size = "Cover Bildgröße (Standard 200)";
        tt.track_fontsize = "Titel Zeichengröße (Standard 20)";
        tt.x_more_tracks_available = "weitere %1 Titel vorhanden";
		tt.one_more_track_available = "1 weiterer Titel vorhanden";
        tt.type_any_key_to_start_searching_all = "Suchbegriff eingeben";
        tt.type_any_key_to_start_searching_x = "Suchbegriff eingeben (Suche in %1)"; // %1 is either artist, song or album
        tt.tap_ok_to_run_search = "Berühre 'OK', um die Suche zu starten";
        tt.no_matches_found = "Keine Treffer gefunden";
        tt.search_for_all = "Suchen nach";
        tt.search_for_x = "Suchen in %1 nach";
        tt.results_x_tracks_in_y_albums = "%1 in %2 gefunden"; // %1 is amount of tracks, %2 amount of albums
		tt.caching_album_art = "Erzeuge Vorschaubilder-Cache";
		tt.touch_anywhere_to_abort = "Berühre den Bildschirm zum Abbrechen.";
		tt.display_year = "Jahr anzeigen?";
		tt.fontface = "Schriftart";
		tt.font_warning = "muss tatsächlich auf Rechner existieren!";
		tt.screen_has_no_config_options = "Dieser Dialog hat keine separaten Einstellmöglichkeiten";
		tt.cant_open_keyboard_layout = "Kann Tastatur-Layout %1 nicht öffnen.";
		tt.number_abbreviation = "Nr.";
		tt.search_layout = "Suchseite-Darstellung";
		tt.artist_album_track_fontsize = "Schriftgrad Künstler/Album/Titel (Standard 20)";
		tt.volume_preset = "Vorgabe-Lautstärke für Kiosk-Modus";
		tt.no_preset = "Keine Vorgabe";
		tt.touch_to_abort = "Berühre den Bildschirm zum Abbrechen";
		tt.has_been_queued = "%1 (%2) übernommen";
		tt.album_track_counter_display = "Anzeige Titelanzahl auf Hauptbildschirm";
		tt.never = "Niemals";
		tt.always = "Immer";
		tt.depending_on_confirmation_level = "Abhängig von der Bestätigungs-Einstellung";
		tt.hide_queue = "Verstecke Warteschlange";
		tt.album_tracknumbers = "Titelanzahl-Anzeige (Standard 14)";
		tt.disabled = "deaktiviert";
		tt.search = "Suchen";
		tt.toggle_time_display = "Zeitanzeige";
		tt.display_rating = "Wertung anzeigen";
		tt.display_genre = "Genre anzeigen";
		tt.kiosk_mode_functionality = "Kiosk-Modus -> Funktionalität";
		tt.playback_queue = "Wiedergabe -> Warteschlange";
		tt.playback_automatic_control_additional_options = "Wiedergabe -> Automatische Steuerung -> Weitere Optionen...";
		tt.settings = "Einstellungen";
		tt.credits = "Kredite:";
		tt.volume = "Lautstärke";
		tt.edit_queue = "Wiedergabeliste ändern";
		tt.enable_webradio = "Webradio aktivieren";
		tt.currently_playing = "Derzeit läuft";
		tt.queue_pos_is = "Warteschlange-Position %1";  // %1 is position
		tt.remove_tracks_from_queue = "Titel aus Wiedergabeliste entfernen";
		tt.could_not_create_webradio_file = "Konnte benötigte Webradio-Datei im Silverjuke-Ordner nicht erstellen.";
		tt.make_sure_to_have_write_permissions = "Stelle sicher, dass Schreibrechte in diesem Ordner vorhanden sind.";
		tt.mplayer_not_found = "Die Webradio-Datei mplayer.exe konnte im Silverjuke-Verzeichnis nicht gefunden werden.";
		tt.edit_webradio_station = "Internetradio-Station %1 bearbeiten";
		tt.create_new_webradio_station = "Neue Internetradio-Station erstellen";
		tt.station_name = "Stationsname";
		tt.webradio_url = "Webradio URL";
		tt.country_code = "Ländercode";
		tt.locale = "Ort";
		tt.genre = "Genre";
		tt.icon ="lokale Icon-Datei";
		tt.radio_layout = "Radio-Darstellung";
		tt.radio_images_size = "Größe Radio-Stations-Icon (Standard 150)";
		tt.fontsize = "Schriftgrad (Standard 20)";
		tt.add = "Hinzufügen";
		tt.save = "Speichern";
		tt.cancel = "Abbrechen";
		tt.delete_all_radio_stations = "Alle gespeicherten Radiosender löschen";
		tt.add_default_radio_stations_to_database = "Alle verfügbaren Standard-Radiosender zur Datenbank hinzufügen";
		tt.favorite = "Favorit";
		tt.webradio_cant_be_enabled = "Das Internetradio-Feature kann nicht aktiviert werden, weil die Datei mplayer.exe sich nicht im Silverjuke-Verzeichnis befindet. Lies die untenstehende Ankündigung für Details.";
		tt.webradio_announcement_thread = "Internetradio-Ankündigungs-Thread auf silverjuke.net";
        break;
    }
}

