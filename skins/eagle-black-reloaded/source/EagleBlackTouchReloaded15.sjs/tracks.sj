// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Tracks layout
//
// ************************************************************

// ***************** settings ***************************

var TRACKS_BORDER_TOP = 107;
var TRACKS_BORDER_BOTTOM = 106;

var TRACKS_FONTCOLOR = DEFAULTFONTCOLOR;
var TRACKS_FONTSIZE = 25;
var TRACKS_COVER_FONTSIZE;

var TRACKS_MARGIN = 10;
var TRACKS_SIZE_H;
var TRACKS_COMPILATION_SIZE_H;
var TRACKS_GAP_X = 16;
var TRACKS_GAP_Y;

var TRACKS_ARTSIZE = 200;

var tracks_area_w = 934;
var tracks_area_x = 120;

//***************** globals *********************************

var tracks_area_h;
var tracks_cover_y;
var tracks_y;
var tracks_count_y;
var tracks_compilation_count_y;
var tracks_pagesize;
var tracks_compilation_pagesize;
var tracks_gap_y;
var tracks_size_w
var tracks_urls;
var tracks_albumsize;
var tracks_albumid_previous = -1;
var tracks_albumid_previous = -1;
var tracks_offset;
var tracks_compilation;

//***************** functions ********************************


// edit layout configuration
function TracksConfig()
{
    var dlg = new Dialog();

    dlg.addStaticText(t('tracks_layout') + "\n");

    dlg.addTextCtrl("artsize", t('cover_image_size'), TRACKS_ARTSIZE);
    dlg.addTextCtrl("fontsize", t('track_fontsize'), TRACKS_FONTSIZE);

    mode = 0;

    if (dlg.showModal() == "ok")
    {
        program.iniWrite(CONFIGNAME + "/tracks_artsize", dlg.getValue("artsize"));
        program.iniWrite(CONFIGNAME + "/tracks_fontsize", dlg.getValue("fontsize"));

        TracksDraw();
    };

    mode = MODE_TRACKS;
}


function TracksCalculate()
{
    TRACKS_ARTSIZE = Number(program.iniRead(CONFIGNAME + "/tracks_artsize", TRACKS_ARTSIZE));
    if (TRACKS_ARTSIZE < 100) TRACKS_ARTSIZE = 100;
    if (TRACKS_ARTSIZE > 500) TRACKS_ARTSIZE = 500;

    TRACKS_FONTSIZE = Number(program.iniRead(CONFIGNAME + "/tracks_fontsize", TRACKS_FONTSIZE));
    if (TRACKS_FONTSIZE < 20) TRACKS_FONTSIZE = 20;
    if (TRACKS_FONTSIZE > 100) TRACKS_FONTSIZE = 100;

    TRACKS_COVER_FONTSIZE = TRACKS_FONTSIZE;

    TRACKS_SIZE_H = TRACKS_FONTSIZE + 2 * TRACKS_MARGIN;
    //TRACKS_COMPILATION_SIZE_H = 2 * TRACKS_FONTSIZE + 2 * TRACKS_MARGIN;
	TRACKS_COMPILATION_SIZE_H = TRACKS_FONTSIZE + 2 * TRACKS_MARGIN;

    TRACKS_GAP_Y = Math.floor(TRACKS_FONTSIZE / 2) - 3;

    tracks_area_h = ET_GetWindowHeight() - TRACKS_BORDER_TOP - TRACKS_BORDER_BOTTOM + 6;
	
	var tracks_area_w = ET_GetWindowWidth() - 200;
	//alert(tracks_area_w);

    tracks_size_w = tracks_area_w - TRACKS_ARTSIZE - TRACKS_GAP_X;

    //tracks_cover_y = Math.floor((tracks_area_h - TRACKS_ARTSIZE - 2 * TRACKS_COVER_FONTSIZE) / 2);
	tracks_cover_y = 0;

    tracks_count_y = Math.floor((tracks_area_h - TRACKS_FONTSIZE) / (TRACKS_SIZE_H + TRACKS_GAP_Y));
    tracks_compilation_count_y = Math.floor((tracks_area_h - TRACKS_FONTSIZE) / (TRACKS_COMPILATION_SIZE_H + TRACKS_GAP_Y));

    tracks_gap_y = TRACKS_GAP_Y;
    tracks_y = Math.floor((tracks_area_h - tracks_count_y * TRACKS_SIZE_H - (tracks_count_y - 1) * TRACKS_GAP_Y - TRACKS_FONTSIZE) / 2);
    tracks_compilation_y = Math.floor((tracks_area_h - tracks_compilation_count_y * TRACKS_COMPILATION_SIZE_H - (tracks_compilation_count_y - 1) * TRACKS_GAP_Y - TRACKS_FONTSIZE) / 2);

    tracks_pagesize = tracks_count_y;
    tracks_compilation_pagesize = tracks_compilation_count_y;
}


// switch layout to tracks display
function TracksMode()
{
	mode = MODE_TRACKS;

    ET_DrawDeleteAll();
	
	TracksInit();
	TracksCalculate();
	var track_mode = 0;
	if (tracks_albumsize > tracks_pagesize) {
		var track_mode = 1;
	}
	
	switch (track_mode)
	{
    case 0: program.layout = LAYOUT_PREFIX + "tracks"; break;
	case 1: program.layout = LAYOUT_PREFIX + "tracks_updown"; break;
	}

    // this avoids nasty flickering
    program.setTimeout(TracksDraw, 1, false);
}


function TracksInit()
{
    if (selected_albumid != tracks_albumid_previous) tracks_offset = 0;
    tracks_albumid_previous = selected_albumid;

    db.openQuery("SELECT COUNT(*)" + 
	            " FROM tracks" + 
				" WHERE albumid = " + selected_albumid + 
				" AND " + filter_expr);

    tracks_albumsize = Number(db.getField(0));

    db.closeQuery();

    db.openQuery("SELECT leadartistname " +
	             "FROM albums " +
				 "WHERE id = " + selected_albumid);

    tracks_compilation = (db.getField(0) == "");

    db.closeQuery();
}


function TracksDraw()
{
    ET_DrawDeleteAll();
    TracksCalculate();
    TracksBuild();
    ET_DrawAll();
    SetTick();
}


function TracksBuild()
{
    var pagesize = tracks_compilation ? tracks_compilation_pagesize : tracks_pagesize;

    if (tracks_offset < 0) tracks_offset = pagesize * Math.floor((tracks_albumsize - 1) / pagesize);
    if (tracks_offset >= tracks_albumsize) tracks_offset = 0;
	
	var tracks_area_w = ET_GetWindowWidth() - 200;

    ET_NewArea(tracks_area_x, TRACKS_BORDER_TOP, tracks_area_w, tracks_area_h, COLOR_LIGHT);

	db.openQuery("SELECT albums.leadartistname, albums.albumname, tracks.year, tracks.genrename, COUNT(tracks.trackcount), SUM(tracks.playtimems) " +
	             "FROM albums, tracks " +
				 "WHERE albums.id = " + selected_albumid + " " +
				 "AND " + filter_expr + " " +
				 "AND albums.id == tracks.albumid");
				 
    var x = 0;
    var y = tracks_cover_y;
	var current_trackcount = db.getField(4);
	var timetotal = db.getField(5);

    DrawCover(selected_albumid, undefined, x, y, TRACKS_ARTSIZE, false);
    ET_AddClickArea(x, y, TRACKS_ARTSIZE, TRACKS_ARTSIZE + 2 * TRACKS_COVER_FONTSIZE, -1);

    y += TRACKS_ARTSIZE + TRACKS_COVER_FONTSIZE;

    if (!tracks_compilation)
    {
        ET_SetFont(ARTISTFONTCOLOR, config_fontface, TRACKS_COVER_FONTSIZE);
        ET_AddTextArea(db.getField(0), x, y, TRACKS_ARTSIZE, 60, DT_TOP | DT_CENTER | DT_END_ELLIPSIS | DT_WORDBREAK);
        y += 2 * TRACKS_COVER_FONTSIZE;
    }

    ET_SetFont(ALBUMFONTCOLOR, config_fontface, TRACKS_COVER_FONTSIZE);
    ET_AddTextArea(db.getField(1), x, y, TRACKS_ARTSIZE, 80, DT_TOP | DT_CENTER | DT_END_ELLIPSIS | DT_WORDBREAK);
    y += 2 * TRACKS_COVER_FONTSIZE;
	
	var albumyear = db.getField(2);
	
	if (config_year == 1 && albumyear.length > 3) {
		ET_SetFont(DEFAULTFONTCOLOR, config_fontface, TRACKS_COVER_FONTSIZE);
		ET_AddText("(" + albumyear + ")", x, y, TRACKS_ARTSIZE, DT_CENTER | DT_END_ELLIPSIS);
		y += TRACKS_COVER_FONTSIZE;
	}
	
	var albumgenre = db.getField(3);
	
	if (config_genre != 0 && albumgenre != '') {
		ET_SetFont(GENREFONTCOLOR, config_fontface, TRACKS_COVER_FONTSIZE);
		ET_AddText(albumgenre, x, y, TRACKS_ARTSIZE, DT_CENTER | DT_END_ELLIPSIS);
		y += 2 * TRACKS_COVER_FONTSIZE;
	}

    db.closeQuery();

    db.openQuery("SELECT tracks.url, tracks.tracknr, tracks.trackname, tracks.leadartistname, tracks.playtimems, tracks.rating " +
	             "FROM tracks " +
				 "WHERE tracks.albumid = " + selected_albumid + " " +
                 "AND " + filter_expr + " " +
                 "ORDER BY tracks.disknr, tracks.tracknr " + " " +
				 "LIMIT " + (pagesize + 1) + " " +
                 "OFFSET " + tracks_offset + ";");

    tracks_urls = new Array();

    x += TRACKS_ARTSIZE + TRACKS_GAP_X;
    //y = tracks_y;
	var y = tracks_cover_y;
	var playtime = MsToTime(db.getField(4));

    var row;
	var track_counter = 0;
	var rating_counter;
	var col_timetotal;
	
    var count_y = tracks_compilation ? tracks_compilation_count_y : tracks_count_y;
    var size_h = tracks_compilation ? TRACKS_COMPILATION_SIZE_H : TRACKS_SIZE_H;
	
    for (row = 0; row < count_y; ++row)
    {
        if (db.nextRecord())
        {
			var col_tracknumber = Math.round(TRACKS_FONTSIZE * 2);
			var col_text = tracks_size_w - col_tracknumber - (TRACKS_GAP_X * 2);
			if (config_rating != 0) {
				var col_rating = Math.round(TRACKS_FONTSIZE * 2);
				var col_text = col_text - col_rating - TRACKS_GAP_X;
			} else {
				var col_rating;
			}
			if (IniAllowTime() != 0) {
				var col_time = Math.round(TRACKS_FONTSIZE * 3);
				var col_text = col_text - col_time - TRACKS_GAP_X;
			} else {
				var col_time;
			}
			
			ET_AddImage(IMG_TRACKFRAME, x, y, tracks_size_w, size_h, ET_REPEAT_GRID, 0);
            var yy = y ;

            tracks_urls.push(db.getField(0));
            ET_AddClickArea(x, yy, tracks_size_w, size_h, row);

            yy += TRACKS_MARGIN;

            ET_SetFont(TRACKS_FONTCOLOR, config_fontface, TRACKS_FONTSIZE);
            ET_AddText(Number(tracks_offset + track_counter + 1), x + 25, yy, 35);
            if (tracks_compilation)
            {
				ET_SetFont(ARTISTFONTCOLOR, config_fontface, Math.floor(TRACKS_FONTSIZE / 1.2));
				ET_AddText(db.getField(3), x + 60, yy, col_text / 2, DT_END_ELLIPSIS);
				ET_SetFont(TITLEFONTCOLOR, config_fontface, Math.floor(TRACKS_FONTSIZE / 1.2));
				ET_AddText(db.getField(2), x + 60 + (col_text / 2), yy, col_text / 2, DT_END_ELLIPSIS);
            } else {
				ET_SetFont(TITLEFONTCOLOR, config_fontface, TRACKS_FONTSIZE);
				ET_AddText(db.getField(2), x + 60, yy, col_text, DT_END_ELLIPSIS);
			}
			if (IniAllowTime() != 0) {
				ET_SetFont(TIMEFONTCOLOR, config_fontface, Math.floor(TRACKS_FONTSIZE / 1.2));
				ET_AddText(MsToTime(db.getField(4)), x + 60 + col_text, yy, col_time, DT_RIGHT | DT_END_ELLIPSIS);
				var col_timetotal = col_text;
				var col_text = col_text + col_time + TRACKS_GAP_X;
			}
			if (config_rating != 0) {
				var rating_string = '';
				for (rating_counter = 0; rating_counter < db.getField(5); ++rating_counter) {
					var rating_string = rating_string + '*';
				}
				ET_SetFont(RATINGFONTCOLOR, config_fontface, Math.floor(TRACKS_FONTSIZE * 1.2));
				ET_AddText(rating_string, x + 60 + col_text, yy, col_rating, DT_END_ELLIPSIS);
			}
        }

        y += size_h + TRACKS_GAP_Y;
		var track_counter = track_counter + 1;
    }
	
	if (IniAllowTime() != 0) {
		ET_SetFont(TIMEFONTCOLOR, config_fontface, Math.floor(TRACKS_FONTSIZE / 1.2));
		ET_AddText(MsToTime(timetotal), x + 60 + col_timetotal, yy + size_h + TRACKS_GAP_Y, col_time, DT_RIGHT | DT_END_ELLIPSIS);
	}

    if (db.nextRecord())
    {
		//var remaining_tracks = current_trackcount + "|" + tracks_offset + "|" + track_counter;
		var remaining_tracks = current_trackcount - (tracks_offset + track_counter);
		if (remaining_tracks == 1) {
			ET_SetFont(DEFAULTFONTCOLOR, config_fontface, TRACKS_FONTSIZE);
			ET_AddText("(" + t('one_more_track_available') + ")", x, y, tracks_size_w, DT_CENTER);
		} else {
			ET_SetFont(DEFAULTFONTCOLOR, config_fontface, TRACKS_FONTSIZE);
			ET_AddText("(" + t('x_more_tracks_available', remaining_tracks) + ")", x, y, tracks_size_w, DT_CENTER);
		}
    }

    db.closeQuery();
}


function TracksClick(eventid)
{
    if (eventid == -1)
    {
        selected_trackurl = undefined;
    }
    else
    {
        selected_trackurl = tracks_urls[eventid];
    }
    Queue();
}


// scroll trackslayout a full page up
function TracksPageUp()
{
    var pagesize = tracks_compilation ? tracks_compilation_pagesize : tracks_pagesize;

    if (tracks_offset >= pagesize)
    {
        tracks_offset -= pagesize;
    }
    else if (tracks_offset > 0)
    {
        tracks_offset = 0;
    }
    else
    {
        tracks_offset = -1;
    }

    TracksDraw();
}


// scroll trackslayout a full page down
function TracksPageDown()
{
    var pagesize = tracks_compilation ? tracks_compilation_pagesize : tracks_pagesize;
    tracks_offset += pagesize;
    TracksDraw();
}


//************************************************************

