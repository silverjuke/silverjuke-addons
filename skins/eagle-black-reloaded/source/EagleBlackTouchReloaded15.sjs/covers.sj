// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Covers layout
//
// ************************************************************

// ***************** settings ***************************

var COVERS_FONTCOLOR = DEFAULTFONTCOLOR;
var COVERS_FONTSIZE = 20;
var COVERS_TRACKNUMBERS = 14;

var COVERS_BORDER_LEFTRIGHT = 124;
var PLAYER_BORDER_LEFT = 80;
var PLAYER_BORDER_RIGHT = 80;

var COVERS_BORDER_TOP = 34;
var COVERS_BORDER_BOTTOM = 250;

var COVERS_GAP_MIN_X = 5;
var COVERS_GAP_MIN_Y = 5;

var COVERS_INFO_DY = 46;
var COVERS_INFO_H = 144;

var COVERS_ARTSIZE = 150;
var PLAYER_TOPMARGIN = 0;
var PLAYER_SPACE_RATIO = 0.7;

//***************** globals *********************************

var covers_area_w;
var player_area_w;
var covers_area_h;

var covers_count_x;
var covers_count_y;
var covers_pagesize;

var covers_gap_x;
var covers_gap_y;
var covers_offset_y;

var covers_info_y;

var covers_offset = 0;

var covers_border = 1;
var covers_radio_id = '';

//***************** functions ********************************

// edit layout configuration
function CoversConfig()
{
    var dlg = new Dialog();

    dlg.addStaticText(t('cover_layout') + "\n");

    dlg.addTextCtrl("artsize", t('cover_images_size'), COVERS_ARTSIZE);
    dlg.addTextCtrl("fontsize", t('album_fontsize'), COVERS_FONTSIZE);
	dlg.addTextCtrl("tracknumbers", t('album_tracknumbers'), COVERS_TRACKNUMBERS);
    dlg.addSelectCtrl("border", t('border_around_covers'), covers_border, t('no'), t('yes'));
    mode = 0;

    var artsize = COVERS_ARTSIZE;

    if (dlg.showModal() == "ok")
    {
        if (dlg.getValue("artsize") != artsize)
        {
            ET_CoverArtCacheClear();
        }
        program.iniWrite(CONFIGNAME + "/covers_artsize", dlg.getValue("artsize"));
		program.iniWrite(CONFIGNAME + "/covers_fontsize", dlg.getValue("fontsize"));
        program.iniWrite(CONFIGNAME + "/covers_border", dlg.getValue("border"));
		program.iniWrite(CONFIGNAME + "/covers_tracknumbers", dlg.getValue("tracknumbers"));

		CoversDraw();
    };
    mode = MODE_COVERS;
}


function CoversCalculate()
{
	COVERS_ARTSIZE = Number(program.iniRead(CONFIGNAME + "/covers_artsize", COVERS_ARTSIZE));
    if (COVERS_ARTSIZE < 100) COVERS_ARTSIZE = 100;
    if (COVERS_ARTSIZE > 500) COVERS_ARTSIZE = 500;

    COVERS_FONTSIZE = Number(program.iniRead(CONFIGNAME + "/covers_fontsize", COVERS_FONTSIZE));
    if (COVERS_FONTSIZE < 10) COVERS_FONTSIZE = 10;
    if (COVERS_FONTSIZE > 100) COVERS_FONTSIZE = 100;
	
	COVERS_TRACKNUMBERS = Number(program.iniRead(CONFIGNAME + "/covers_tracknumbers", COVERS_TRACKNUMBERS));
    if (COVERS_TRACKNUMBERS < 10) COVERS_TRACKNUMBERS = 10;
    if (COVERS_TRACKNUMBERS > 100) COVERS_TRACKNUMBERS = 100;

    var covers_size_w = COVERS_ARTSIZE;
    var covers_size_h = COVERS_ARTSIZE + 2 * COVERS_FONTSIZE;
	if (config_genre != 0) {
		covers_size_h += COVERS_FONTSIZE;
	}
	
	if (program.kioskMode == true && IniAllowSearch() != 1) {
		PLAYER_BORDER_RIGHT = 56;
	} else {
		PLAYER_BORDER_RIGHT = 80;
	}
	
	if (program.kioskMode == true && IniAllowVideo() != 1) {
		PLAYER_BORDER_LEFT = 56;
	} else {
		PLAYER_BORDER_LEFT = 80;
	}

	

    covers_area_w = ET_GetWindowWidth() - 2 * COVERS_BORDER_LEFTRIGHT;
    covers_area_h = ET_GetWindowHeight() - COVERS_BORDER_TOP - COVERS_BORDER_BOTTOM;
	covers_info_w = ET_GetWindowWidth() - PLAYER_BORDER_LEFT - PLAYER_BORDER_RIGHT;

    covers_count_x = Math.floor(covers_area_w / (covers_size_w + COVERS_GAP_MIN_X))
    covers_gap_x = Math.floor((covers_area_w - covers_count_x * covers_size_w) / (covers_count_x - 1));

    covers_count_y = Math.floor(covers_area_h / (covers_size_h + COVERS_GAP_MIN_Y))
    covers_gap_y = Math.floor((covers_area_h - covers_count_y * covers_size_h) / covers_count_y);
    covers_offset_y = Math.floor(covers_gap_y / 2);

    covers_pagesize = covers_count_x * covers_count_y;

    covers_info_y = COVERS_BORDER_TOP + covers_area_h + COVERS_INFO_DY;

    covers_border = Number(program.iniRead(CONFIGNAME + "/covers_border", covers_border));
	
	covers_radio_id = program.iniRead(CONFIGNAME + "/radio_id", '');
	
}


// switch layout to covers display
function CoversMode()
{
    mode = MODE_COVERS;

    ET_DrawDeleteAll();
	
	if (config_radio) {
		var layout_suffix = '_radio';
	} else {
		var layout_suffix = '';
	}

    if (config_karaoke) {
        program.layout = limit_karaoke ? LAYOUT_PREFIX + "covers_karaoke_on" + layout_suffix : LAYOUT_PREFIX + "covers_karaoke_off" + layout_suffix;
    } else {
        program.layout = LAYOUT_PREFIX + "covers" + layout_suffix;
    }

    // this avoids nasty flickering
    program.setTimeout(CoversDraw, 1, false);
}


function CoversDraw()
{
    ET_DrawDeleteAll();
    CoversCalculate();
    CoversBuildInfo();
    CoversBuildAlbums();
    ET_DrawAll();
    SetTick();
}


function CoversBuildAlbums()
{
    ET_NewArea(COVERS_BORDER_LEFTRIGHT, COVERS_BORDER_TOP, covers_area_w, covers_area_h, COLOR_LIGHT);

    // make sure we have some albums in view
    if (covers_offset < 0)
    {
        covers_offset = covers_pagesize * Math.floor((filter_albumcount - 1) / covers_pagesize);
    }
    if (covers_offset >= filter_albumcount)
    {
        covers_offset = 0;
    }

    db.openQuery("SELECT albums.id, albums.leadartistname, albums.albumname, tracks.year, COUNT(tracks.trackcount), tracks.genrename " +
                 "FROM albums, tracks " +
				 "WHERE " + filter_expr +
                 "AND albums.id == tracks.albumid " +
                 "GROUP BY albums.id " +
                 "ORDER BY albums.albumindex " +
				 "LIMIT " + covers_pagesize + " " +
				 "OFFSET " + covers_offset);

    var y = covers_offset_y;
    var row;

    for (row = 0; row < covers_count_y; ++row)
    {
        var x = 0;
        var col;
        for (col = 0; col < covers_count_x; ++col)
        {
            if (db.nextRecord())
            {
                var yy = y;

				ET_AddClickArea(x, yy, COVERS_ARTSIZE, COVERS_ARTSIZE + 2 * COVERS_FONTSIZE, db.getField(0));

                var fromfile = DrawCover(db.getField(0), undefined, x, yy, COVERS_ARTSIZE, 0, true, covers_border);

                yy += COVERS_ARTSIZE;

                var artist = db.getField(1);
                if (artist == "") 
				{
					artist = t('various');
					ET_SetFont(DEFAULTFONTCOLOR, config_fontface, COVERS_FONTSIZE);
				} 
				else
				{
					ET_SetFont(ARTISTFONTCOLOR, config_fontface, COVERS_FONTSIZE);
				}
                ET_AddText(artist, x, yy, COVERS_ARTSIZE, DT_CENTER | DT_END_ELLIPSIS);
                yy += COVERS_FONTSIZE;
				
				var albumname = db.getField(2);
				var trackcount = db.getField(4);
				var genrename = db.getField(5);
				var ALBUMYEAR_SPACE = Math.floor(COVERS_FONTSIZE * 2);
				
				if (config_year == 1 && db.getField(3).length > 3) {
					ET_SetFont(ALBUMFONTCOLOR, config_fontface, COVERS_FONTSIZE);
					ET_AddText(albumname, x, yy, (COVERS_ARTSIZE - ALBUMYEAR_SPACE), DT_LEFT | DT_END_ELLIPSIS);
					ET_SetFont(DEFAULTFONTCOLOR, config_fontface, COVERS_FONTSIZE);
					ET_AddText(AlbumYear("", db.getField(3)), (x + COVERS_ARTSIZE - ALBUMYEAR_SPACE), yy, ALBUMYEAR_SPACE, DT_RIGHT | DT_END_ELLIPSIS);
                } else {
					ET_SetFont(ALBUMFONTCOLOR, config_fontface, COVERS_FONTSIZE);
					ET_AddText(albumname, x, yy, (COVERS_ARTSIZE), DT_CENTER | DT_END_ELLIPSIS);
				}
				
				if (config_trackcount != 0) {
					var tracknumber_width = COVERS_TRACKNUMBERS + 3;
					var tracknumber_height = Math.floor(COVERS_TRACKNUMBERS/1.1) + 2;
					var tracknumber_pos_x = x + (2 * covers_border * FRAME_BORDERWIDTH);
					var tracknumber_pos_y = yy - COVERS_TRACKNUMBERS - (6 * covers_border * FRAME_BORDERWIDTH) - tracknumber_height;
					var tracknumber_padding = 1;
					if (trackcount.length > 1) {
						var tracknumber_offset = 0;
					} else {
						var tracknumber_offset = 5;
					}
					if (trackcount == 1) {
						if ((config_confirm != 1 && config_trackcount == 1) || config_trackcount == 2) {
							ET_AddImage("counter_bg_single.png", tracknumber_pos_x, tracknumber_pos_y, tracknumber_width, tracknumber_height, ET_REPEAT_STRETCH, 0);
							ET_SetFont(COLOR_DARK, config_fontface, COVERS_TRACKNUMBERS);
							ET_AddText(trackcount, tracknumber_pos_x + tracknumber_offset, tracknumber_pos_y, tracknumber_width - (2 * tracknumber_padding), tracknumber_height - (2 * tracknumber_padding), DT_CENTER | DT_VCENTER);
						}
					} else {
						if (config_trackcount == 2) {
							ET_AddImage("counter_bg_multi.png", tracknumber_pos_x, tracknumber_pos_y, tracknumber_width, tracknumber_height, ET_REPEAT_STRETCH, 0);
							ET_SetFont(COLOR_DARK, config_fontface, COVERS_TRACKNUMBERS);
							ET_AddText(trackcount, tracknumber_pos_x + tracknumber_offset, tracknumber_pos_y, tracknumber_width - (2 * tracknumber_padding), tracknumber_height - (2 * tracknumber_padding), DT_CENTER | DT_VCENTER);
						}
					}
				}
				
				yy += COVERS_FONTSIZE;
				
				if (config_genre != 0 && genrename != '') {
					ET_SetFont(GENREFONTCOLOR, config_fontface, COVERS_FONTSIZE);
					ET_AddText(genrename, x, yy, COVERS_ARTSIZE, DT_LEFT | DT_END_ELLIPSIS);
					yy += COVERS_FONTSIZE;
				}
				
                // if slow image then update the screen
                if (fromfile) ET_DrawAll();
            }

            x += COVERS_ARTSIZE + covers_gap_x;
        }

        y += COVERS_ARTSIZE + 2 * COVERS_FONTSIZE + covers_gap_y;
		if (config_genre != 0) {
			y += COVERS_FONTSIZE;
		}
    }

    db.closeQuery();
}

function TimeUpdate() {
	ET_NewArea(0, 0, 1000, 500, 0xFF0000);
	var x = 0;
	var y = 0;
	var w = 100;
	ET_SetFont(ARTISTFONTCOLOR, config_fontface, 70);
	ET_AddText('time', x, y, w, DT_END_ELLIPSIS);
	return;
}


function CoversBuildInfo() {	
    ET_NewArea(PLAYER_BORDER_LEFT, covers_info_y, covers_info_w, COVERS_INFO_H, COLOR_LIGHT);

	if ((program.kioskMode || config_restricted) && !IniAllowPause()) {
		var player_offset_x = 10;
		var player_offset_y = 12;
	} else {
		ET_AddClickArea(0, 0, Math.floor(covers_info_w * PLAYER_SPACE_RATIO), COVERS_INFO_H, -1);
		ET_AddImage(IMG_COVERFRAME, 0, 5, Math.floor(covers_info_w * PLAYER_SPACE_RATIO), COVERS_INFO_H - 5, ET_REPEAT_GRID, 0);
		var player_offset_x = 20;
		var player_offset_y = 14;
	}
	if (((program.kioskMode || config_restricted) && !IniAllowEditQueue()) || player.queueLength <= 1) {
		var queue_offset_x = 0;
		var queue_offset_y = 0;
	} else {
		ET_AddClickArea(Math.floor(covers_info_w * PLAYER_SPACE_RATIO), 0, Math.floor(covers_info_w * (1 - PLAYER_SPACE_RATIO)), COVERS_INFO_H, -2);
		ET_AddImage(IMG_COVERFRAME, Math.floor(covers_info_w * PLAYER_SPACE_RATIO) +10, 5, Math.floor(covers_info_w * (1 - PLAYER_SPACE_RATIO)) - 10, COVERS_INFO_H - 5, ET_REPEAT_GRID, 0);
		var queue_offset_x = 5;
		var queue_offset_y = 8;
	}

	var FONTSIZE1 = 26;
    var FONTSIZE2 = 22;
	var x = COVERS_INFO_H + player_offset_x;
	var y = Math.floor((COVERS_INFO_H - 2 * FONTSIZE1 - FONTSIZE2) / 2);
	var w = Math.floor(covers_info_w * PLAYER_SPACE_RATIO) - player_offset_x - x;
	
	if (player.isPlaying()) {
        var url = player.getUrlAtPos();
        db.openQuery("SELECT albumid, albumname, year " + 
		             "FROM tracks " +
					 "WHERE url = '" + url.replace(new RegExp("'","g"),"''") + "'");

        DrawCover(db.getField(0), url, player_offset_x, player_offset_y, COVERS_INFO_H - player_offset_y * 2);
		var fromfile = DrawRadioCover('hdd.png', covers_info_w * PLAYER_SPACE_RATIO - COVERS_INFO_H, 10, COVERS_INFO_H - 20, 0, true, 0);
		ET_AddClickArea(player_offset_x, player_offset_y, COVERS_INFO_H - player_offset_y, COVERS_INFO_H - player_offset_y, db.getField(0));
       
        ET_SetFont(ARTISTFONTCOLOR, config_fontface, FONTSIZE1);
        ET_AddText(player.getArtistAtPos(), x, y, w, DT_END_ELLIPSIS);
        y += FONTSIZE1;

		ET_SetFont(TITLEFONTCOLOR, config_fontface, FONTSIZE1);
        ET_AddText(player.getTitleAtPos(), x, y, w, DT_END_ELLIPSIS);
        y += FONTSIZE1;

        var albumname = db.getField(1);
		var trackyear = db.getField(2);

        if (albumname != "") {
			ET_SetFont(ALBUMFONTCOLOR, config_fontface, FONTSIZE2);
			ET_AddText(albumname, x, y, w, DT_END_ELLIPSIS);
			if (config_year == 1) {
				y += FONTSIZE2;
				ET_SetFont(DEFAULTFONTCOLOR, config_fontface, FONTSIZE2);
				if (trackyear.length > 3) {
					ET_AddText("(" + AlbumYear("", trackyear) + ")", x, y, w, DT_END_ELLIPSIS);
				}
			}
		}
        db.closeQuery();
	} else {
        // SJ player is NOT playing
		if (covers_radio_id != '' && Number(covers_radio_id) > 0) {
			// The radio is supposed to be turned on, so let's make sure to start it if it's not
			db.openQuery("SELECT webradio.name, webradio.url, webradio.icon, webradio.country, webradio.city, webradio.genre " +
						 "FROM webradio " +
						 "WHERE webradio.rowid=" + covers_radio_id);
			program.run('checktask.cmd');
			radio_log_file = new File('radio.log');
			radio_status = radio_log_file.read(1);
			// 0 = running, 1 = not running
			radio_log_file.flush();
			File.remove('radio.log');
			if (radio_status != 0) {
				program.run('radio.cmd ' + db.getField(1));
			}
			var fromfile = DrawRadioCover(db.getField(2), player_offset_x, player_offset_y, COVERS_INFO_H - player_offset_y * 2, 0, true, covers_border);
			var fromfile = DrawRadioCover('globe.png', covers_info_w * PLAYER_SPACE_RATIO - COVERS_INFO_H, 10, COVERS_INFO_H - 20, 0, true, 0);
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
				ET_SetFont(TITLEFONTCOLOR, config_fontface, FONTSIZE2);
				ET_AddText(db.getField(4), x + city_gap, y, w, DT_END_ELLIPSIS);
				y += FONTSIZE1;
			}
			if (db.getField(5) != '' && config_genre != 0) {
				ET_SetFont(TITLEFONTCOLOR, config_fontface, FONTSIZE2);
				ET_AddText(db.getField(5), x, y, w, DT_END_ELLIPSIS);
				y += FONTSIZE1;
			}
			db.closeQuery();
		} else {
			// Neither SJ player nor radio player are running, so let's display a pause/stop message in the player
			var info1;
			var info2;
			if (player.isStopped()) {
				info1 = "* * * * * " + t('welcome') + " * * * * *";
				info2 = "(" + t('tap_any_album_to_select') + ")";
			} else if (player.isPaused()) {
				info1 = t('pausing');
				info2 = "(" + t('tap_this_area_to_continue') + ")";
			}

			var FONTSIZE1 = 30;
			var FONTSIZE2 = 25;
			var y = Math.floor((COVERS_INFO_H - FONTSIZE1 - FONTSIZE2) / 2);

			ET_SetFont(COVERS_FONTCOLOR, config_fontface, FONTSIZE1);
			ET_AddText(info1, 0, y, Math.floor(covers_info_w * PLAYER_SPACE_RATIO), DT_CENTER | DT_END_ELLIPSIS);
			y += FONTSIZE1;

			ET_SetFont(COVERS_FONTCOLOR, config_fontface, FONTSIZE2);
			ET_AddText(info2, 0, y, Math.floor(covers_info_w * PLAYER_SPACE_RATIO), DT_CENTER | DT_END_ELLIPSIS);
		}
    }

	// Queue Display
	var x = COVERS_INFO_H + player_offset_x;
	var w = Math.floor(covers_info_w * PLAYER_SPACE_RATIO) - player_offset_x - x;

	x += w + 40;
	y = PLAYER_TOPMARGIN + queue_offset_y;
	var FONTSIZE3 = 16;

	if ((player.queuePos + 1) < player.queueLength)
	{
		x += 10;
		w = covers_info_w - x;

		if (((program.kioskMode || config_restricted) && !IniAllowEditQueue())) {
			ET_SetFont(COVERS_FONTCOLOR, config_fontface, FONTSIZE3, 0, 0);
			ET_AddText(t('tracks_in_queue') + ":", x, y, w, DT_LEFT | DT_END_ELLIPSIS);
			y += FONTSIZE3;
		}

		var lines = Math.floor((COVERS_INFO_H - y - PLAYER_TOPMARGIN) / FONTSIZE3);
		var nextnr;
		for (nextnr = 1; nextnr <= lines; ++nextnr)
		{
			if ((player.queuePos + nextnr) < player.queueLength)
			{
				var text;

				if (nextnr == lines)
				{
					if ((player.queueLength - player.queuePos - nextnr) != 1) {
						text = "(+" + t('x_tracks_more', (player.queueLength - player.queuePos - nextnr)) + ")";
					} else {
						text = "(+" + t('x_track_more', (player.queueLength - player.queuePos - nextnr)) + ")";
					}
				}
				else
				{
					text = player.getArtistAtPos(player.queuePos + nextnr) + " - " + player.getTitleAtPos(player.queuePos + nextnr);
				}

				ET_SetFont(COVERS_FONTCOLOR, config_fontface, FONTSIZE3, 0, 0);
				ET_AddText(text, x, y, w, DT_LEFT | DT_END_ELLIPSIS);
				y += FONTSIZE3;
			}
		}
	}
}


// jump coverlayout a full page backwards
function CoversPrev()
{
    if (covers_offset >= covers_pagesize)
    {
        covers_offset -= covers_pagesize;
    }
    else if (covers_offset > 0)
    {
        covers_offset = 0;
    }
    else
    {
        covers_offset = -1;
    }

	CoversDraw();
}


// jump coverlayout a full page forewards
function CoversNext()
{
    covers_offset += covers_pagesize;
	CoversDraw();
}


// mouseclick
function CoversClick(eventid)
{
	if (eventid < 0)
    {
        if (eventid == -1) {
		PausePlay();
		} 
		if (eventid == -2 && player.isStopped() == false && player.queueLength > 1) {
			QueueMode();
		}
    }
    else
    {
        // album clicked
        //selected_albumid = covers_albumids[eventid];
		selected_albumid = eventid;

        db.openQuery("SELECT COUNT(*), url, leadartistname, trackname" + 
		            " FROM tracks" + 
					" WHERE albumid = " + selected_albumid + 
					" AND " + filter_expr);
        var albumsize = Number(db.getField(0));
        selected_trackurl = db.getField(1);
		var queued_artist = db.getField(2);
		var queued_title = db.getField(3);
        db.closeQuery();
		
	

		if ((albumsize == 1) && (config_confirm != 1)) {
            program.setSkinText("queue_message", t('has_been_queued', queued_title, queued_artist));
			TrackQueue();
        } else {
            TracksMode();
        }
    }
}


// toggle pause/play
function PausePlay() {
    if ((program.kioskMode || config_restricted) && !IniAllowPause()) return;

    if (player.isPlaying()) {
        player.pause();
    } else if (player.isPaused()) {
		if (covers_radio_id != '') {
			if (covers_radio_id > 0) {
				covers_radio_id = 0 - covers_radio_id;
				program.iniWrite(CONFIGNAME + "/radio_id", covers_radio_id);
				program.run('taskkill /im mplayer.exe');
			} else if(covers_radio_id < 0) {
				covers_radio_id = Math.abs(covers_radio_id);
				program.iniWrite(CONFIGNAME + "/radio_id", covers_radio_id);
			}
		} else {
			player.play();
		}
    }

	CoversDraw()
}


function CoversKey(charcode)
{
    var key = String.fromCharCode(charcode).toUpperCase();

    if ((key == "#") || ((key >= "0") && (key <= "9")))
    {
        CoversJump("#");
    }
    else if ((key == "#") || ((key >= "A") && (key <= "Z")))
    {
        CoversJump(key);
    }
    else
    {
        SetTick();
    }
}


// jump the coverlayout to the given searchcharacter
function CoversJump(c)
{
    var code;

    if (c == "#")
    {
        code = 123;
    }
    else
    {
        code = c.charCodeAt(0) + 32;
    }

    db.openQuery("SELECT albumindex " +
	             "FROM albums " +
				 "WHERE azfirst >= " + code + " " + 
				 "ORDER BY azfirst limit 1;");

    if (db.nextRecord())
    {
        covers_offset = Number(db.getField(0));

        if (limit_expr != "1")
        {
            db.closeQuery();

            // in case a limiting music selection is used count the albums visible up to the normal azfirst album
            db.openQuery("SELECT COUNT(distinct albumindex) FROM albums, tracks " +
                         "WHERE " + limit_expr + " AND albums.albumindex < " + covers_offset + " AND albums.id == tracks.albumid " +
                         "ORDER BY albums.albumindex;");

            if (db.nextRecord())
            {
                covers_offset = Number(db.getField(0));
            }
        }
    }
    else
    {
        covers_offset = filter_albumcount - 1;
    }
    db.closeQuery();

	CoversDraw();

    return false;
}


//************************************************************

