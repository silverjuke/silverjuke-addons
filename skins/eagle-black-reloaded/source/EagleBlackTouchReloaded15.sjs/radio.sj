// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Radio layout
//
// ************************************************************

// ***************** settings ***************************

var RADIO_FONTCOLOR = DEFAULTFONTCOLOR;
var RADIO_FONTSIZE = 20;
var RADIO_ARTSIZE = 150;
var RADIO_SORT = 0;

var RADIO_BORDER_LEFTRIGHT = 124;
var RADIO_PLAYER_BORDER_LEFTRIGHT = 56;
var RADIO_BORDER_TOP = 34;
var RADIO_BORDER_BOTTOM = 250;

var RADIO_GAP_MIN_X = 5;
var RADIO_GAP_MIN_Y = 5;

var RADIO_INFO_DY = 46;
var RADIO_INFO_H = 192;
var RADIO_INFO_PADDING = 10;

var PLAYER_TOPMARGIN = 0;
var MAX_RADIOSTATIONS_IN_DB = 5000;

//***************** globals *********************************

var radio_area_x;
var radio_area_y;


var radio_y;

var radio_prevmode;
var radio_credits;

var radio_area_w;
var radio_area_h;

var radio_count_x;
var radio_count_y;
var radio_pagesize;

var radio_gap_x;
var radio_gap_y;
var radio_offset_y;

var radio_info_y;
var radio_draw_id;
var radio_info_id;

var radio_offset = 0;

var radio_border = 1;

//***************** functions ********************************

// edit layout configuration
function RadioConfig()
{
    var dlg = new Dialog();

    dlg.addStaticText(t('radio_layout') + "\n");

    dlg.addTextCtrl("artsize", t('radio_images_size'), RADIO_ARTSIZE);
    dlg.addTextCtrl("fontsize", t('fontsize'), RADIO_FONTSIZE);
	dlg.addButton('db_empty', t('delete_all_radio_stations'), function(){db.openQuery("DELETE FROM webradio"); db.closeQuery();dlg.close();});
	dlg.addButton('db_fill', t('add_default_radio_stations_to_database'), function(){RadioFillDatabase();dlg.close();RadioDraw();});
	dlg.addButton('ok', t('ok'));
	dlg.addButton('cancel', t('cancel'));
	
    mode = 0;

    var artsize = COVERS_ARTSIZE;

    if (dlg.showModal() == "ok")
    {
        if (dlg.getValue("artsize") != artsize)
        {
            ET_CoverArtCacheClear();
        }
        program.iniWrite(CONFIGNAME + "/radio_artsize", dlg.getValue("artsize"));
		program.iniWrite(CONFIGNAME + "/radio_fontsize", dlg.getValue("fontsize"));
    }
	mode = MODE_RADIO;
	RadioMode();
	RadioDraw();
}

// switch layout to radio display
function RadioMode()
{
    radio_prevmode = mode;
    mode = MODE_RADIO;

    ET_DrawDeleteAll();

    radio_credits = rights.credits;
	
    db = new Database();
	
	var radio_table_column_names = new Array('name', 'url', 'icon', 'country', 'city', 'genre', 'favorite');

    // WEIRD: SQL 'if exists' is not working?
    db.openQuery("SELECT COUNT() FROM sqlite_master WHERE NAME = 'webradio'");
    if (db.getField(0) == 0) {
		db.closeQuery();
        db.openQuery("CREATE TABLE webradio (" + radio_table_column_names.join(', ') + ")");
		RadioFillDatabase();
    }
    db.closeQuery();
	
	// Make sure that the database structure works as expected if someone upgraded from an older version
	db.openQuery("PRAGMA table_info('webradio')");
	for (i = 1; i <= 20; ++i) {
		if (db.nextRecord()) {
			for(var i = 0; i < radio_table_column_names.length; i++) {
				if(radio_table_column_names[i] == db.getField(1)) {
					radio_table_column_names.splice(i,1);
				}
			}
		}
	}
	db.closeQuery();
	for(var i = 0; i < radio_table_column_names.length; i++) {
		db.openQuery("ALTER TABLE webradio ADD COLUMN " + radio_table_column_names[i]);
		db.closeQuery();
	}
	
	if (File.exists("radio.cmd") == false) {
		// The batch file doesn't exist yet - let's create it
		file = new File('radio.cmd');
		file.write('@echo off\ntaskkill /im mplayer.exe\nstart "Webradio" /min  mplayer.exe -playlist %1');
		file.flush();
	}
	if (File.exists("checktask.cmd") == false) {
		// The batch file doesn't exist yet - let's create it
		file = new File('checktask.cmd');
		file.write('@echo off\ntasklist /FI "IMAGENAME eq mplayer.exe" 2>NUL | find /I /N "mplayer.exe">NUL\necho %ERRORLEVEL% > radio.log');
		file.flush();
	}
	if (File.exists("radio.cmd") == false || File.exists("checktask.cmd") == false) {
		MessageMode(t('could_not_create_webradio_file'),
                    t('make_sure_to_have_write_permissions'));
		return false;
		RadioExit();
	}
	
	RadioCalculate();
	
	if (RadioStationcount() > radio_pagesize) {
		program.layout = LAYOUT_PREFIX + "radio_updown_" + RADIO_SORT;
	} else {
		program.layout = LAYOUT_PREFIX + "radio_" + RADIO_SORT;
	}
	
    // this avoids nasty flickering
    program.setTimeout(RadioDraw, 1, false);
}


function RadioDraw(radio_draw_id)
{
    ET_DrawDeleteAll();
    RadioCalculate();
	RadioBuildInfo(radio_draw_id);
    RadioBuild();
    ET_DrawAll();
    SetTick();
}

function RadioCalculate()
{
	RADIO_SORT = Number(program.iniRead(CONFIGNAME + "/radio_sort", RADIO_SORT));
	
	RADIO_ARTSIZE = Number(program.iniRead(CONFIGNAME + "/radio_artsize", RADIO_ARTSIZE));
    if (RADIO_ARTSIZE < 100) RADIO_ARTSIZE = 100;
    if (RADIO_ARTSIZE > 500) RADIO_ARTSIZE = 500;

    RADIO_FONTSIZE = Number(program.iniRead(CONFIGNAME + "/radio_fontsize", RADIO_FONTSIZE));
    if (RADIO_FONTSIZE < 10) RADIO_FONTSIZE = 10;
    if (RADIO_FONTSIZE > 100) RADIO_FONTSIZE = 100;
	
    var radio_size_w = RADIO_ARTSIZE;
    
	if (config_genre != 0) {
		var radio_size_h = RADIO_ARTSIZE + 3 * RADIO_FONTSIZE;
	} else {
		var radio_size_h = RADIO_ARTSIZE + 2 * RADIO_FONTSIZE;
	}
	
	radio_area_w = Math.floor(ET_GetWindowWidth()) - 220;
	radio_info_w = Math.floor(ET_GetWindowWidth()) - 120;
    radio_area_h = Math.floor(ET_GetWindowHeight()) -280;
	radio_area_x = 110;
	radio_area_y = 40;
	
	radio_count_x = Math.floor(radio_area_w / (radio_size_w + RADIO_GAP_MIN_X))
    radio_gap_x = Math.floor((radio_area_w - radio_count_x * radio_size_w) / (radio_count_x - 1));

    radio_count_y = Math.floor(radio_area_h / (radio_size_h + RADIO_GAP_MIN_Y))
    radio_gap_y = Math.floor((radio_area_h - radio_count_y * radio_size_h) / radio_count_y);
    radio_offset_y = Math.floor(radio_gap_y / 2);
	radio_pagesize = radio_count_x * radio_count_y;
	radio_info_y = RADIO_BORDER_TOP + radio_area_h + RADIO_INFO_DY;
}

function RadioStationcount() {
	if (program.kioskMode == true) {
		var query_radiostationcount = "webradio.url<>'' AND webradio.name<>'' ";
	} else {
		var query_radiostationcount = '1=1 ';
	}
	if (RADIO_SORT == 2) {
		query_radiostationcount += " AND webradio.favorite=1";
	}
	db.openQuery("SELECT COUNT(webradio.name) " +
	             "FROM webradio " + 
				 "WHERE " + query_radiostationcount);
    var filter_radiostationcount = Number(db.getField(0));
	db.closeQuery();
	return filter_radiostationcount;
}

function RadioBuild() {
    ET_NewArea(radio_area_x, radio_area_y, radio_area_w, radio_area_h, COLOR_LIGHT);
	if (program.kioskMode == true) {
		var filter_radio_kiosk = "webradio.url<>'' AND webradio.name<>'' ";
	} else {
		var filter_radio_kiosk = '1=1 ';
	}
	
	// make sure we have some albums in view
    if (radio_offset < 0)
    {
        radio_offset = radio_pagesize * Math.floor((RadioStationcount() - 1) / radio_pagesize);
    }
    if (radio_offset >= RadioStationcount()) {
        radio_offset = 0;
    }
	
	switch (RADIO_SORT) {
		case 1:  var radio_order_query = "webradio.genre"; var radio_and_query = "1=1";  break;
		case 2:  var radio_order_query = "webradio.name"; var radio_and_query = "webradio.favorite=1"; break;
		case 3:  var radio_order_query = "webradio.country, webradio.city"; var radio_and_query = "1=1"; break;
		default: var radio_order_query = "webradio.name"; var radio_and_query = "1=1"; break;
    }
	
	db.openQuery("SELECT webradio.rowid, webradio.name, webradio.url, webradio.icon, webradio.country, webradio.city, webradio.genre, webradio.favorite " +
                 "FROM webradio " +
				 "WHERE " + filter_radio_kiosk + " " +
				 "AND " + radio_and_query + " " +
				 "ORDER BY " + radio_order_query + " " +
				 "LIMIT " + radio_pagesize + " " +
				 "OFFSET " + radio_offset);
			 
	var y = radio_offset_y;
    var row;
	var radio_text_width = RADIO_ARTSIZE;
	if (program.kioskMode != true) {
		radio_text_width -= 22;
	}
			
	for (row = 0; row < radio_count_y; ++row) {
        var x = 0;
        var col;
        for (col = 0; col < radio_count_x; ++col) {
			if (db.nextRecord()) {
				var yy = y;
				var city_gap = 0;
				ET_AddClickArea(x, yy, radio_text_width, RADIO_ARTSIZE + 2 * RADIO_FONTSIZE, db.getField(0));
				
				var fromfile = DrawRadioCover(db.getField(3), x, yy, RADIO_ARTSIZE, 0, true, covers_border);

				if (program.kioskMode != true) {
					ET_AddClickArea(x + radio_text_width, yy, RADIO_FONTSIZE * 2, RADIO_FONTSIZE * 2, 0 - db.getField(0));
					ET_AddImage(ET_Skinfile("button_delete.png"), x + radio_text_width, yy, 21, 21, ET_REPEAT_STRETCH, 3);
				}

                yy += RADIO_ARTSIZE;

				ET_SetFont(ALBUMFONTCOLOR, config_fontface, RADIO_FONTSIZE);
				ET_AddText(db.getField(1), x, yy, radio_text_width, DT_CENTER | DT_END_ELLIPSIS);
				if (program.kioskMode != true) {
					ET_AddClickArea(x + radio_text_width - RADIO_FONTSIZE, yy, RADIO_FONTSIZE * 2, RADIO_FONTSIZE * 2, db.getField(0) * MAX_RADIOSTATIONS_IN_DB);
					ET_AddImage(ET_Skinfile("button_edit.png"), x + radio_text_width - RADIO_FONTSIZE, yy, RADIO_FONTSIZE * 2, RADIO_FONTSIZE * 2, ET_REPEAT_STRETCH, 3);
				}
				yy += RADIO_FONTSIZE;
				var radio_country = db.getField(4);
				if (File.exists(ET_Skinfile("flags/" + radio_country + ".png")) == true) {
					var city_gap = Math.round(RADIO_FONTSIZE * 1.25);
					var flag_icon_h = Math.round(RADIO_FONTSIZE * 0.85);
					ET_AddImage("flags/" + radio_country + ".png", x, yy, city_gap, flag_icon_h, ET_REPEAT_STRETCH, 0);
					var city_gap = city_gap + 2;
				}
				ET_SetFont(DEFAULTFONTCOLOR, config_fontface, RADIO_FONTSIZE);
				ET_AddText(db.getField(5), x + city_gap, yy, radio_text_width - city_gap, DT_LEFT | DT_END_ELLIPSIS);
				yy += RADIO_FONTSIZE;
				
				if (config_genre != 0 && db.getField(6) != '') {
					ET_SetFont(GENREFONTCOLOR, config_fontface, RADIO_FONTSIZE);
					ET_AddText(db.getField(6), x, yy, radio_text_width, DT_LEFT | DT_END_ELLIPSIS);
					yy += RADIO_FONTSIZE;
				}
				
				// if slow image then update the screen
                //if (fromfile) ET_DrawAll();
			}
			x += RADIO_ARTSIZE + radio_gap_x;
		}
		if (config_genre != 0) {
			y += RADIO_ARTSIZE + 3 * RADIO_FONTSIZE + radio_gap_y;
		} else {
			y += RADIO_ARTSIZE + 2 * RADIO_FONTSIZE + radio_gap_y;
		}
	}
	db.closeQuery();
}

function RadioBuildInfo(radio_info_id) {
	if (program.layout.substr(LAYOUT_PREFIX.length, 12) == 'radio_updown') {
		var RADIO_PLAYER_BORDER_LEFTRIGHT = 130;
		var radio_player_margin_left = 74;
	} else {
		var RADIO_PLAYER_BORDER_LEFTRIGHT = 56;
		var radio_player_margin_left = 0;
	}
    ET_NewArea(RADIO_PLAYER_BORDER_LEFTRIGHT, radio_info_y, radio_info_w - radio_player_margin_left, RADIO_INFO_H, COLOR_LIGHT);
	ET_AddClickArea(0, 0, radio_info_w - radio_player_margin_left, RADIO_INFO_H, 0 - MAX_RADIOSTATIONS_IN_DB);
	ET_AddImage(IMG_COVERFRAME, 0, 0, radio_info_w - radio_player_margin_left, RADIO_INFO_H, ET_REPEAT_GRID, 0);
	
	var FONTSIZE1 = Math.round(RADIO_FONTSIZE * 1.3);
	var FONTSIZE2 = Math.round(RADIO_FONTSIZE * 1.1);
	var x = RADIO_INFO_H + RADIO_INFO_PADDING;
	var y = Math.floor((RADIO_INFO_H - 2 * FONTSIZE1 - FONTSIZE2 - RADIO_INFO_PADDING * 2) / 2) + RADIO_INFO_PADDING;
	var w = radio_info_w - radio_player_margin_left;
	
	var config_radio_id = program.iniRead(CONFIGNAME + "/radio_id", '');
	if (radio_info_id == '' && config_radio_id != '') {
		radio_info_id = config_radio_id;
	}
		
	
	if (Number(radio_info_id) > 0) {
		// a radio station has been selected
		db.openQuery("SELECT webradio.name, webradio.url, webradio.icon, webradio.country, webradio.city, webradio.genre " +
					 "FROM webradio " +
					 "WHERE webradio.rowid=" + radio_info_id);
		var fromfile = DrawRadioCover(db.getField(2), 0 + RADIO_INFO_PADDING, 10, RADIO_INFO_H - 20, 0, true, covers_border);
		var fromfile = DrawRadioCover('globe.png', radio_info_w - radio_player_margin_left - RADIO_INFO_PADDING - RADIO_INFO_H, 10, RADIO_INFO_H - 20, 0, true, 0);
		ET_SetFont(ALBUMFONTCOLOR, config_fontface, FONTSIZE1);
		ET_AddText(db.getField(0), x, y, w, DT_END_ELLIPSIS);
		y += FONTSIZE1;
		if (db.getField(3) != '' || db.getField(4) != '') {
			var radio_country = db.getField(3);
			if (File.exists(ET_Skinfile("flags/" + radio_country + ".png")) == true) {
				var city_gap = Math.round(FONTSIZE2 * 1.25);
				var flag_icon_h = Math.round(FONTSIZE2 * 0.85);
				ET_AddImage("flags/" + radio_country + ".png", x, y, city_gap, flag_icon_h, ET_REPEAT_STRETCH, 0);
				var city_gap = city_gap + 2;
			} else {
				var city_gap = 0;
			}
			ET_SetFont(RADIO_FONTCOLOR, config_fontface, FONTSIZE2);
			ET_AddText(db.getField(4), x + city_gap, y, w, DT_END_ELLIPSIS);
			y += FONTSIZE1;
		}
		if (db.getField(5) != '' && config_genre != 0) {
			ET_SetFont(RADIO_FONTCOLOR, config_fontface, FONTSIZE2);
			ET_AddText(db.getField(5), x, y, w, DT_END_ELLIPSIS);
			y += FONTSIZE1;
		}
		db.closeQuery();
	} else {
		// no radio station has been selected

		if (player.isPlaying()) {
			var url = player.getUrlAtPos();
			db.openQuery("SELECT albumid, albumname " + 
						 "FROM tracks " +
						 "WHERE url = '" + url.replace(new RegExp("'","g"),"''") + "'");

			DrawCover(db.getField(0), url, 0 + RADIO_INFO_PADDING, 10, RADIO_INFO_H - 20);
			var fromfile = DrawRadioCover('hdd.png', radio_info_w - radio_player_margin_left - RADIO_INFO_PADDING - RADIO_INFO_H, 10, RADIO_INFO_H - 20, 0, true, 0);

			ET_SetFont(ARTISTFONTCOLOR, config_fontface, FONTSIZE1);
			ET_AddText(player.getArtistAtPos(), x, y, w, DT_END_ELLIPSIS);
			y += FONTSIZE1;

			ET_SetFont(TITLEFONTCOLOR, config_fontface, FONTSIZE1);
			ET_AddText(player.getTitleAtPos(), x, y, w, DT_END_ELLIPSIS);
			y += FONTSIZE1;

			var albumname = db.getField(1);

			if (albumname != "") 
			{
				ET_SetFont(ALBUMFONTCOLOR, config_fontface, FONTSIZE2);
				ET_AddText(albumname, x, y, w, DT_END_ELLIPSIS);
			}

			db.closeQuery();
		} else {
			radio_info_id = program.iniRead(CONFIGNAME + "/radio_id", '');
			if (radio_info_id != '' && Number(radio_info_id) > 0) {
				// The radio is supposed to be turned on, so let's make sure to start it if it's not
				db.openQuery("SELECT webradio.name, webradio.url, webradio.icon, webradio.country, webradio.city, webradio.genre " +
							 "FROM webradio " +
							 "WHERE webradio.rowid=" + radio_info_id);
				program.run('checktask.cmd');
				radio_log_file = new File('radio.log');
				radio_status = radio_log_file.read(1);
				// 0 = running, 1 = not running
				radio_log_file.flush();
				File.remove('radio.log');
				if (radio_status != 0) {
					program.run('radio.cmd ' + db.getField(1));
				}
				var fromfile = DrawRadioCover(db.getField(2), 0 + RADIO_INFO_PADDING, 10, RADIO_INFO_H - 20, 0, true, covers_border);
				var fromfile = DrawRadioCover('globe.png', radio_info_w - radio_player_margin_left - RADIO_INFO_PADDING - RADIO_INFO_H, 10, RADIO_INFO_H - 20, 0, true, 0);
				ET_SetFont(ALBUMFONTCOLOR, config_fontface, FONTSIZE1);
				ET_AddText(db.getField(0), x, y, w, DT_END_ELLIPSIS);
				y += FONTSIZE1;
				if (db.getField(3) != '' || db.getField(4) != '') {
					var radio_country = db.getField(3);
					if (File.exists(ET_Skinfile("flags/" + radio_country + ".png")) == true) {
						var city_gap = Math.round(FONTSIZE2 * 1.25);
						var flag_icon_h = Math.round(FONTSIZE2 * 0.85);
						ET_AddImage("flags/" + radio_country + ".png", x, y, city_gap, flag_icon_h, ET_REPEAT_STRETCH, 0);
						var city_gap = city_gap + 2;
					} else {
						var city_gap = 0;
					}
					ET_SetFont(RADIO_FONTCOLOR, config_fontface, FONTSIZE2);
					ET_AddText(db.getField(4), x + city_gap, y, w, DT_END_ELLIPSIS);
					y += FONTSIZE1;
				}
				if (db.getField(5) != '' && config_genre != 0) {
					ET_SetFont(RADIO_FONTCOLOR, config_fontface, FONTSIZE2);
					ET_AddText(db.getField(5), x, y, w, DT_END_ELLIPSIS);
					y += FONTSIZE1;
				}
			} else {
				ET_SetFont(DEFAULTFONTCOLOR, config_fontface, Math.round(RADIO_FONTSIZE * 2));
				ET_AddTextArea(t('pausing') + "\n(" + t('tap_this_area_to_continue') + ")", 0 + RADIO_INFO_PADDING, y, w - RADIO_INFO_PADDING * 3, RADIO_INFO_H - RADIO_INFO_PADDING * 2, DT_TOP | DT_CENTER | DT_END_ELLIPSIS | DT_WORDBREAK);
			}
		}
	}
}

// jump radiolayout a full page backwards
function RadioPrev()
{
    if (radio_offset >= radio_pagesize)
    {
        radio_offset -= radio_pagesize;
    }
    else if (radio_offset > 0)
    {
        radio_offset = 0;
    }
    else
    {
        radio_offset = -1;
    }

	RadioDraw();
}


// jump radiolayout a full page forewards
function RadioNext()
{
    radio_offset += radio_pagesize;
	RadioDraw();
}

function RadioClick(eventid) {
	//alert(eventid);
	if (eventid == '') {
		RadioExit();
	} else if (eventid > 0 && eventid < MAX_RADIOSTATIONS_IN_DB) {
		// Playback radio station
		db.openQuery("SELECT COUNT(*), webradio.url " +
				 "FROM webradio " + 
				 "WHERE rowid=" + eventid);
		if (db.getField(0) == 1 && db.getField(1) != '') {
			// play the radio station
			if (player.isPlaying() == true) {
				// Pause Silverjuke Player;
				player.pause();
			}
			program.iniWrite(CONFIGNAME + "/radio_id", eventid);
			program.run('radio.cmd ' + db.getField(1));
			RadioDraw(eventid);
		}
	} else if (eventid < 0 && eventid > 0 - MAX_RADIOSTATIONS_IN_DB) {
		// Delete station from database
		db.openQuery("SELECT COUNT(*) " +
				 "FROM webradio " + 
				 "WHERE rowid=" + Math.abs(eventid));
		if (db.getField(0) == 1) {
				// delete the radio station
				db.closeQuery();
				db.openQuery("DELETE FROM webradio " +
				             "WHERE webradio.rowid=" + Math.abs(eventid));
				RadioDraw();
		}
	} else if (eventid >= MAX_RADIOSTATIONS_IN_DB) {
		// edit the radio station
		db.openQuery("SELECT COUNT(*) " +
				 "FROM webradio " + 
				 "WHERE rowid=" + eventid / MAX_RADIOSTATIONS_IN_DB);
		if (db.getField(0) == 1) {
			RadioEdit(eventid / MAX_RADIOSTATIONS_IN_DB);
		}
	} else if (eventid = 0 - MAX_RADIOSTATIONS_IN_DB) {
		// Pause/Play toggle
		if (player.isPlaying() == true) {
			player.pause();
			RadioDraw();
		} else {
			var config_radio_id = program.iniRead(CONFIGNAME + "/radio_id", '');
			if (config_radio_id == '') {
				player.play();
				RadioDraw();
			} else {
				// Radio playback/pause - a radio_id is set
				db.openQuery("SELECT COUNT(*), webradio.url " +
							 "FROM webradio " + 
							 "WHERE rowid=" + Math.abs(config_radio_id));
				// Check if the radio_id is valid
				if (db.getField(0) == 1 && db.getField(1) != '') {
					if (config_radio_id > 0) {
						config_radio_id = 0 - config_radio_id;
						program.iniWrite(CONFIGNAME + "/radio_id", config_radio_id);
						program.run('taskkill /im mplayer.exe');
						RadioDraw();
					} else {
						config_radio_id = Math.abs(config_radio_id);
						program.iniWrite(CONFIGNAME + "/radio_id", config_radio_id);
						program.run('radio.cmd ' + db.getField(1));
						RadioDraw(config_radio_id);
					}
				} else {
					// Something is wrong: there is no database record although there should be one - let's default back to the regular SJ player
					program.iniWrite(CONFIGNAME + "/radio_id", '');
					player.play();
					RadioDraw();
				}
				db.closeQuery();
			}
		}
	}
	db.closeQuery();
}

function RadioEdit(radiostation_id) {
	var static_text = t('create_new_webradio_station');
	var radio_allow_dialog = 1;
	var webradio_station_name;
	var webradio_url;
	var webradio_country_code;
	var webradio_locale;
	var webradio_genre;
	var webradio_file;
	
	db.openQuery("SELECT COUNT(*) " +
			 "FROM webradio");
	var total_radio_station_records = db.getField(0);
	db.closeQuery();
	
	if (radiostation_id != '' && radiostation_id == Number(radiostation_id)) {
		db.openQuery("SELECT webradio.name, webradio.url, webradio.icon, webradio.country, webradio.city, webradio.genre, webradio.favorite " +
					 "FROM webradio " + 
					 "WHERE rowid=" + radiostation_id);
		var static_text = t('edit_webradio_station', '"' + db.getField(0) + '"');
		var webradio_station_name = db.getField(0);
		var webradio_url  = db.getField(1);
		var webradio_country_code = db.getField(3);
		var webradio_locale = db.getField(4);
		var webradio_genre = db.getField(5);
		var webradio_file = db.getField(2);
		var webradio_favorite = db.getField(6);
		var radio_ok_button_label = t('save');
	} else {
		if (total_radio_station_records >= MAX_RADIOSTATIONS_IN_DB) {
			var radio_allow_dialog = 0;
		}
		var radio_ok_button_label = t('add');
	}
	
	if (radio_allow_dialog == 1) {
		var dlg = new Dialog();
		dlg.addButton('ok', radio_ok_button_label);
		db.closeQuery();

		dlg.addStaticText(static_text + "\n--------------------------------------------------------------------------------------------------------------");

		dlg.addTextCtrl("webradio_name", t('station_name'), webradio_station_name);
		dlg.addTextCtrl("webradio_url", t('webradio_url'), webradio_url);
		dlg.addTextCtrl("webradio_country", t('country_code'), webradio_country_code);
		dlg.addTextCtrl("webradio_locale", t('locale'), webradio_locale);
		dlg.addTextCtrl("webradio_genre", t('genre'), webradio_genre);
		dlg.addTextCtrl("webradio_file", t('icon'), webradio_file);
		dlg.addCheckCtrl("webradio_favorite", t('favorite'), webradio_favorite);
		dlg.addButton('cancel', t('cancel'));

		mode = 0;

		if (dlg.showModal() == "ok") {
			var webradio_station_name = dlg.getValue('webradio_name');
			var webradio_url = dlg.getValue('webradio_url');
			var webradio_country_code = dlg.getValue('webradio_country');
			var webradio_locale = dlg.getValue('webradio_locale');
			var webradio_genre = dlg.getValue('webradio_genre');
			var webradio_file = dlg.getValue('webradio_file');
			var webradio_favorite = dlg.getValue('webradio_favorite');
			// Sanitization
			if (static_text != t('create_new_webradio_station') ) {
					db.openQuery("DELETE FROM webradio " +
								 "WHERE webradio.rowid=" + radiostation_id);			
			}
			db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre, favorite) " +
						"VALUES ('" + webradio_station_name + "', " +
								"'" + webradio_url + "', " +
								"'" + webradio_file + "', " +
								"'" + webradio_country_code + "', " +
								"'" + webradio_locale + "', " +
								"'" + webradio_genre + "', " +
								webradio_favorite + ")");
			db.closeQuery();
		}
		mode = MODE_RADIO;
		RadioMode();
		RadioDraw();
	} else {
		// Too many records
		MessageMode(t('too_many_radio_station_records', MAX_RADIOSTATIONS_IN_DB),
					t('delete_records_before_adding_new_ones'));
	}
}

function RadioExit() {
    //program.run('taskkill /im mplayer.exe');
	//if (player.isPaused() == true) {
	//	player.play();
	//}
	switch (radio_prevmode) {
		case MODE_COVERS: CoversMode(); break;
		case MODE_TRACKS: TracksMode(); break;
		case MODE_SEARCH: SearchMode(); break;
		default: CoversMode(); break;
    }
}

// draw a square image in a frame, return true if created from file (slow)
function DrawImage(filename, x, y, size, transparency, cache, border) {
	if (cache == undefined) cache = true;
    if (border == undefined) border = true;
    var coversize = border ? (size - FRAME_BORDERWIDTH * 2) : size;
	var slowfile = false;
	
	if (border) {
        ET_AddImage(filename, x + FRAME_BORDERWIDTH, y + FRAME_BORDERWIDTH, coversize, coversize, 0, transparency);
        ET_AddImage(IMG_COVERFRAME, x, y, size, size, ET_REPEAT_GRID, 0);
    } else {
        ET_AddImage(filename, x, y, size, size, 0, transparency);
    }
	
	return slowfile;
}

function DrawRadioCover(filename, x, y, size, transparency, cache, border) {
	if (filename == '') {
		var radiostation_image = "radiologo/radio-icon.png";
	} else if (File.exists(ET_Skinfile("radiologo/" + filename)) == true) {
			var radiostation_image = "radiologo/" + filename;
	} else if (File.exists(filename) == true) {
			var radiostation_image = filename;
	} else {
			var radiostation_image = "radiologo/radio-icon.png";
	}
	var fromfile = DrawImage(radiostation_image, x, y, size, transparency, cache, border);
	return fromfile;
}

function RadioSort(radio_sort_button) {
	if (RADIO_SORT == radio_sort_button) {
		RADIO_SORT = 0;
	} else {
		RADIO_SORT = radio_sort_button;
	}
	program.iniWrite(CONFIGNAME + "/radio_sort", RADIO_SORT);
	mode = MODE_RADIO;
	RadioMode();
	RadioDraw();
}

function RadioFillDatabase() {
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('SWR1 BW', 'http://mp3-live.swr.de/swr1bw_m.m3u', 'de_swr1.png', 'de', 'Stuttgart', 'News/AC/Oldies')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('SWR3', 'http://mp3-live.swr3.de/swr3_m.m3u', 'de_swr3.png', 'de', 'Baden-Baden', 'Top 40')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Radio Ton', 'http://live.radio-ton.de/live64.m3u', 'de_radioton.png', 'de', 'Heilbronn', 'Oldies')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BBC 1', 'http://bbc.co.uk/radio/listen/live/r1_aaclca.pls', 'gb_bbc.jpg', 'gb', 'London', '')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Antenne Bayern', 'http://www.antenne.de/webradio/antenne.m3u', 'de_antenne_bayern.jpg', 'de', 'Ismaning', 'AOR')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BR3', 'http://streams.br-online.de/bayern3_2.m3u', 'de_bayern3.png', 'de', 'München', 'AOR')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('HR3', 'http://metafiles.gl-systemhaus.de/hr/hr3_2.m3u', 'de_hr3.png', 'de', 'Frankfurt', 'Pop')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Das Ding', 'http://mp3-live.dasding.de/dasding_s.m3u', 'de_dasding.png', 'de', 'Stuttgart', 'Pop')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('WDR 1Live', 'http://metafiles.gl-systemhaus.de/wdr/channel_einslive.m3u', 'de_1live.jpg', 'de', 'Köln', '')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Sunshine Live', 'http://stream.hoerradar.de/sunshinelive-mp3-192.m3u', 'de_sunshine_live.png', 'de', 'Schwetzingen', 'Techno')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Rock Antenne', 'http://www.rockantenne.de/webradio/rockantenne.m3u', 'de_rock_antenne.png', 'de', 'München', 'Rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('SWR1 RP', 'http://mp3-live.swr.de/swr1rp_m.m3u', 'de_swr1.png', 'de', 'Mainz', 'News/AC/Oldies')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('N-Joy Radio', 'http://www.ndr.de/resources/metadaten/audio/m3u/n-joy.m3u', 'de_njoy.png', 'de', 'Hamburg', 'Top 40 / Dance')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('ORF Ö3', 'http://mp3stream7.apasf.apa.at:8000/listen.pls', 'at_orf_ö3.png', 'at', 'Wien', 'Top 40')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Free Radio 80s', 'http://stream1.radiomonitor.com/Free-80s-128.m3u', 'gb_free_radio_80s.png', 'gb', 'Birmingham', '80s')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('EldoRadio Alternative', 'http://sc-alternative.eldoradio.lu/listen.pls', 'lu_eldoradio.png', 'lu', 'Luxembourg', 'Alternative')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BR Puls', 'http://streams.br-online.de/jugend-radio_2.m3u', 'de_br_puls.png', 'de', 'München', 'Alternative')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Deluxe Lounge', 'http://radio.cdn.deluxemusic.tv/deluxemusic.tv/lounge.mp3.m3u', 'de_deluxe_lounge.png', 'de', 'München', 'Lounge')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('MDR Jump', 'http://www.jumpradio.de/static/webchannel/jump_live_channel_high.m3u', 'de_mdr_jump.png', 'de', 'Halle', 'Hot AC, Pop, Rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('917xfm', 'http://live96.917xfm.de/listen.pls', 'de_917xfm.jpg', 'de', 'Hamburg', 'Indie, Alternative, Electro and Jazz')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Absolut Radio', 'http://www.listenlive.eu/absolut.m3u', 'de_absolut_radio.jpg', 'de', 'Nürnberg', 'Album rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Alsterradio', 'http://live96.106acht.de/listen.pls', 'de_alsterradio.png', 'de', 'Hamburg', 'Rock und Pop')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BR1', 'http://streams.br-online.de/bayern1_2.m3u', 'de_br1.jpg', 'de', 'München', 'News/Oldies/Schlager')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('B5 aktuell', 'http://streams.br-online.de/b5aktuell_2.m3u', 'de_b5_aktuell.png', 'de', 'München', 'News')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Big FM', 'http://srv04.bigstreams.de/bigfm-mp3-64.m3u', 'de_big_fm.jpg', 'de', 'Stuttgart', 'Top 40/RnB')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Delta Radio', 'http://stream.hoerradar.de/deltaradio128.m3u', 'de_delta.png', 'de', 'Kiel', 'Rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Delta Radio Alternative Max', 'http://stream.hoerradar.de/deltaradio-alternative128.m3u', 'de_delta_alternative_max.png', 'de', 'Kiel', 'Alternative')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Delta Radio Grunge', 'http://stream.hoerradar.de/deltaradio-grunge128.m3u', 'de_delta_grunge.png', 'de', 'Kiel', 'Grunge')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Deluxe', 'http://195.190.137.104:8000/deluxemusic.tv/radio_web/mp3.m3u', 'de_deluxe.jpg', 'de', 'München', 'Easy Listening')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Deluxe 80s Extreme', 'http://radio.cdn.deluxemusic.tv/deluxemusic.tv/80s.mp3.m3u', 'de_deluxe_80s_extreme.png', 'de', 'München', '80s')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Project Reloaded', 'http://www.listenlive.eu/pr.m3u', 'de_project_reloaded.jpg', 'de', 'Hannover', 'Alternative')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Hit Radio FFH', 'http://streams.ffh.de/radioffh/mp3/hqlivestream.m3u', 'de_ffh.jpg', 'de', 'Frankfurt', 'Top 40')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('HIT104', 'http://www.hit104.de/listen.pls', 'de_hit104.png', 'de', '', 'Top 40')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('ANTENNE 1', 'http://antenne1.fmstreams.de/stream1/livestream.mp3.m3u', 'de_antenne1.jpg', 'de', 'Stuttgart', 'Hot Adult Contemporary')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('HR1', 'http://gffstream.ic.llnwd.net/stream/gffstream_mp3_w67a.m3u', 'de_hr1.jpg', 'de', 'Frankfurt', 'Info/Sport/Music')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('MDR SPUTNIK OnAir Channel', 'http://www.sputnik.de/m3u/live.hi.m3u', 'de_mdr_sputnik_.jpg', 'de', 'Halle', 'Pop, Rock, Hot AC')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Die Neue Welle', 'http://live.meine-neue-welle.de/dnw_128.mp3.m3u', 'de_die_neue_welle.png', 'de', 'Karlsruhe', 'Rock/Pop')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('#Musik.Main', 'http://main-high.rautemusik.fm/listen.pls', 'de_raute_main.png', 'de', '', '80s, Pop, Rock, Charts and new Hits')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('#Musik.Rock', 'http://rock-high.rautemusik.fm/listen.pls', 'de_raute_rock.png', 'de', '', 'Rock, Alternative, Punk, Indie Rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('94 3 rs2', 'http://www.listenlive.eu/rs2.m3u', 'de_94_3_rs2.jpg', 'de', 'Berlin', 'Adult Contemporary')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('RBB Fritz', 'http://www.fritz.de/live.m3u', 'de_rbb_fritz.jpg', 'de', 'Potsdam', 'Top 40')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('RBB Radio Eins', 'http://www.radioeins.de/live.m3u', 'de_rbb_radio_eins.png', 'de', 'Potsdam', 'Adult Contemporary')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Rocky FM', 'http://www.rockyfm.com/listen.pls', 'de_rocky_fm.png', 'de', '', 'Rock')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BBC 2', 'http://bbc.co.uk/radio/listen/live/r2.asx', 'gb_bbc2.png', 'gb', '', 'Adult Contemporary')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('BBC 6 Music', 'http://www.bbc.co.uk/radio/listen/live/r6_aaclca.pls', 'gb_bbc6_music.jpg', 'gb', '', 'Adult Alternative')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('ORF FM4', 'http://mp3stream1.apasf.apa.at:8000/listen.pls', 'at_orf_fm4.jpg', 'at', 'Wien', 'Rock/Alternative/Diverse')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Radio Veronica', 'http://provisioning.streamtheworld.com/pls/VERONICA.pls', 'nl_veronica.jpg', 'nl', 'Hilversum', '80s and 90s Hits')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('Radio 100FM', 'http://onair.100fmlive.dk/100fm_live.mp3.m3u', 'dk_radio_100.png', 'dk', 'Copenhagen', 'Hot Adult Contemporary')");
	db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('KALX', 'http://icecast.media.berkeley.edu:8000/kalx-128.mp3.m3u', 'us_kalx.png', 'us', 'Berkeley, CA', 'College')");
	//db.openQuery("INSERT INTO webradio (name, url, icon, country, city, genre) VALUES ('', '', '', '', '', '')");
 
    db.closeQuery();
}

//************************************************************
