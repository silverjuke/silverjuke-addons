// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Queue layout
//
// ************************************************************

// ***************** settings ***************************

var QUEUE_FONTCOLOR = DEFAULTFONTCOLOR;
var QUEUE_FONTSIZE = 30;

var QUEUE_BORDER_TOP = 107;
var QUEUE_BORDER_BOTTOM = 30;

var QUEUE_MARGIN = 10;
var QUEUE_SIZE_H;

var QUEUE_ARTSIZE = 200;

var queue_area_y = 60;

//***************** globals *********************************

var queue_y;

var queue_prevmode;
var queue_credits;

var queue_area_h;
var queue_cover_y;
var queue_y;
var queue_count_y;
var queue_pagesize;

//***************** functions ********************************

// switch layout to queue display
function QueueMode()
{
    if (player.isStopped() == true) {
		return;
	}
	queue_prevmode = mode;
    mode = MODE_QUEUE;

    ET_DrawDeleteAll();

    queue_credits = rights.credits;

    program.layout = LAYOUT_PREFIX + "queue";

    // this avoids nasty flickering
    program.setTimeout(QueueDraw, 1, false);
}


function QueueDraw()
{
    ET_DrawDeleteAll();
    QueueBuild();
    ET_DrawAll();
    SetTick();
}


function QueueBuild()
{
    queue_y = Math.floor((queue_area_h - 2 * QUEUE_FONTSIZE) / 2);
	var QUEUE_ARTSIZE = Number(program.iniRead(CONFIGNAME + "/queue_artsize", QUEUE_ARTSIZE));
    if (QUEUE_ARTSIZE < 100) QUEUE_ARTSIZE = 100;
    if (QUEUE_ARTSIZE > 500) QUEUE_ARTSIZE = 500;

    var QUEUE_FONTSIZE = Number(program.iniRead(CONFIGNAME + "/queue_fontsize", QUEUE_FONTSIZE));
    if (QUEUE_FONTSIZE < 20) QUEUE_FONTSIZE = 20;
    if (QUEUE_FONTSIZE > 100) QUEUE_FONTSIZE = 100;

    QUEUE_COVER_FONTSIZE = QUEUE_FONTSIZE;

    QUEUE_SIZE_H = QUEUE_FONTSIZE + 2 * QUEUE_MARGIN;

    QUEUE_GAP_Y = Math.floor(QUEUE_FONTSIZE ) ;

    queue_area_h = ET_GetWindowHeight() - QUEUE_BORDER_TOP - QUEUE_BORDER_BOTTOM + 6;
	queue_area_x = QUEUE_BORDER_TOP;
	
	var queue_area_w = ET_GetWindowWidth() - 150;

	queue_cover_y = 0;

    queue_count_y = Math.floor((queue_area_h - QUEUE_FONTSIZE) / (QUEUE_SIZE_H + QUEUE_GAP_Y));

    queue_y = Math.floor((queue_area_h - queue_count_y * QUEUE_SIZE_H - (queue_count_y - 1) * QUEUE_GAP_Y - QUEUE_FONTSIZE) / 2);
    queue_pagesize = queue_count_y;
	
	ET_NewArea(queue_area_x, queue_area_y, queue_area_w, queue_area_h, COLOR_LIGHT);

    
    var y = queue_y;

	
	// Width settings
	var columns_amount = 10;
	var width_time = 0;
	// subtract ommitted columns here
	if (IniAllowTime() == 0) {
		columns_amount -= 1;
		var width_time =  Math.floor(QUEUE_FONTSIZE * 3);
	}
	if (IniAllowEditQueue() != 0 || IniRandomPlay() != 0) {
		columns_amount -= 4;
	}
	if (IniAllowRemoveFromQueue() != 0) {
		columns_amount -= 1;
	}

	var QUEUE_GAP_X = 20;
	var width_button = 30;
	var width_button = 30;
	var width_button = 30;
	var width_button = 30;
	var width_button = 30;
	var width_thumb = Math.floor(QUEUE_FONTSIZE * 1) ;
	
	var columns_remaining_width = queue_area_w - ((width_button * 5) + width_thumb + width_time + (columns_amount * QUEUE_GAP_X)) - 60;
	//var columns_remaining_width = queue_area_w - (width_thumb + (columns_amount * QUEUE_GAP_X) + width_time + 200);
	//var columns_remaining_width = columns_remaining_width - ((columns_amount - 5) * width_thumb);
	var width_track_no = Math.floor(columns_remaining_width * 0.25);
	var width_title = Math.floor(columns_remaining_width * 0.25);
	var width_artist = Math.floor(columns_remaining_width * 0.25);
	var width_albumname = Math.floor(columns_remaining_width * 0.25);
	var total_queue_time = 0;
	

	// Populate the arrays
	var nextnr;
	var qArtist = new Array();
	var qDuration = new Array();
	var qAlbum = new Array();
	var qTitle = new Array();
	var qURL = new Array();

	for (nextnr = 0; nextnr <= player.queueLength; ++nextnr) {
		if (player.getTitleAtPos(player.queuePos + nextnr) != '' && player.getArtistAtPos(player.queuePos + nextnr) != '') {
			qArtist[nextnr]    = player.getArtistAtPos(player.queuePos + nextnr);
			qTitle[nextnr]     = player.getTitleAtPos(player.queuePos + nextnr);
			qAlbum[nextnr]     = player.getAlbumAtPos(player.queuePos + nextnr);
			qDuration[nextnr]  = player.getDurationAtPos(player.queuePos + nextnr);
			qURL[nextnr]       = player.getUrlAtPos(player.queuePos + nextnr);
			var height_consumption = ((Math.max(QUEUE_FONTSIZE, width_button) + QUEUE_GAP_Y) * nextnr) - QUEUE_GAP_Y;
			if (height_consumption < queue_area_h - Math.max(QUEUE_FONTSIZE, width_button) - QUEUE_GAP_Y * 2) {
				var max_queue_display_rows = nextnr;
			}
		}
	}
	

	// Loop through the array populated above
	for (nextnr = 0; nextnr <= max_queue_display_rows; ++nextnr) {
		var x = 0;
		ET_SetFont(QUEUE_FONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
		if (nextnr == 0) {
			ET_AddText(t('currently_playing'), x, y, width_track_no, DT_RIGHT | DT_END_ELLIPSIS);
		} else {
			ET_AddText(t('queue_pos_is', nextnr), x, y, width_track_no, DT_RIGHT | DT_END_ELLIPSIS);
		}
		x = x + width_track_no + QUEUE_GAP_X;
        var url = qURL[nextnr];
        //db.openQuery("SELECT albumid " + 
		//             "FROM tracks " +
		//			 "WHERE url = '" + url.replace(new RegExp("'","g"),"''") + "'");
		//DrawCover(db.getField(0), url, x, y, width_thumb, ET_REPEAT_STRETCH, true, 0);
		//db.closeQuery();
		//ET_AddImage(IMG_TRACKFRAME, x, y, width_thumb, width_thumb, ET_REPEAT_STRETCH, 0);
		//x = x + width_thumb + QUEUE_GAP_X;
		ET_SetFont(ARTISTFONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
		ET_AddText(qArtist[nextnr], x, y, width_artist, DT_LEFT | DT_END_ELLIPSIS);
		x += width_artist + QUEUE_GAP_X;
		ET_SetFont(TITLEFONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
		ET_AddText(qTitle[nextnr], x, y, width_title, DT_LEFT | DT_END_ELLIPSIS);
		x += width_title + QUEUE_GAP_X;
		if (1==1) {
			ET_SetFont(ALBUMFONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
			ET_AddText(qAlbum[nextnr], x, y, width_albumname, DT_LEFT | DT_END_ELLIPSIS);
			x += width_albumname + QUEUE_GAP_X;
		}
		if (IniAllowTime() != 0) {
			ET_SetFont(TIMEFONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
			ET_AddText(MsToTime(total_queue_time + qDuration[nextnr]), x, y, width_time, DT_RIGHT | DT_END_ELLIPSIS);
			total_queue_time = total_queue_time + qDuration[nextnr];
			x += width_time + QUEUE_GAP_X;
		}
		if (IniAllowRemoveFromQueue() == 1) {
			ET_AddImage('button_keyboard.png', x, y, width_button, width_button, 3);
			ET_AddImage('button_delete.png', x + Math.floor(width_button * 0.1), y + Math.floor(width_button * 0.1), Math.floor(width_button * 0.8), Math.floor(width_button * 0.8), ET_REPEAT_STRETCH, 3);
			ET_AddClickArea(x, y, width_button, width_button, nextnr * 100 + 1);
		}
		x += width_button + QUEUE_GAP_X;
		if (IniAllowEditQueue() != 0 && IniRandomPlay() != 1 && nextnr != 0 && nextnr != 1 && nextnr != 2 && player.queueLength != 3) {
			ET_AddImage('button_keyboard.png', x, y, width_button, width_button, 3);
			ET_AddImage('button_to_top.png', x + Math.floor(width_button * 0.1), y + Math.floor(width_button * 0.1), Math.floor(width_button * 0.8), Math.floor(width_button * 0.8), ET_REPEAT_STRETCH, 3);
			ET_AddClickArea(x, y, width_button, width_button, nextnr * 100 + 2);
		}
		x += width_button + QUEUE_GAP_X;
		if (IniAllowEditQueue() != 0 && IniRandomPlay() != 1 && nextnr != 0 && nextnr != 1) {
			ET_AddImage('button_keyboard.png', x, y, width_button, width_button, 3);
			ET_AddImage('button_up.png', x + Math.floor(width_button * 0.1), y + Math.floor(width_button * 0.1), Math.floor(width_button * 0.8), Math.floor(width_button * 0.8), ET_REPEAT_STRETCH, 3);
			ET_AddClickArea(x, y, width_button, width_button, nextnr * 100 + 3);
		}
		x += width_button + QUEUE_GAP_X;
		if (IniAllowEditQueue() != 0 && IniRandomPlay() != 1 && nextnr != 0 && nextnr < qTitle.length - 1) {
			ET_AddImage('button_keyboard.png', x, y, width_button, width_button, 3);
			ET_AddImage('button_down.png', x + Math.floor(width_button * 0.1), y + Math.floor(width_button * 0.1), Math.floor(width_button * 0.8), Math.floor(width_button * 0.8), ET_REPEAT_STRETCH, 3);
			ET_AddClickArea(x, y, width_button, width_button, nextnr * 100 + 4);
		}
		x += width_button + QUEUE_GAP_X;
		if (IniAllowEditQueue() != 0 && IniRandomPlay() != 1 && nextnr != 0 && nextnr < qTitle.length - 1 && nextnr < qTitle.length - 2) {
			ET_AddImage('button_keyboard.png', x, y, width_button, width_button, 3);
			ET_AddImage('button_to_bottom.png', x + Math.floor(width_button * 0.1), y + Math.floor(width_button * 0.1), Math.floor(width_button * 0.8), Math.floor(width_button * 0.8), ET_REPEAT_STRETCH, 3);
			ET_AddClickArea(x, y, width_button, width_button, nextnr * 100 + 5);
		}
		x += width_button + QUEUE_GAP_X;
		y += Math.max(QUEUE_FONTSIZE, width_button) + QUEUE_GAP_Y;
	}
	x = 0;
	ET_SetFont(QUEUE_FONTCOLOR, config_fontface, QUEUE_FONTSIZE, 0, 0);
	var missing_queue_songs = player.queueLength - max_queue_display_rows -1;
	//alert("queuePos (current playback position): " + player.queuePos + "\nqueueLength: " + player.queueLength + "\nremovePlayed: " + player.removePlayed);
	if (missing_queue_songs > 0) {
		if (missing_queue_songs == 1) {
			ET_AddText("+ " + t('x_track_more', missing_queue_songs), x, y, queue_area_w, DT_LEFT | DT_END_ELLIPSIS);
		} else {
			ET_AddText("+ " + t('x_tracks_more', missing_queue_songs), x, y, queue_area_w, DT_LEFT | DT_END_ELLIPSIS);
		}
	}
}


function QueueClick(eventid)
{
    if (eventid == '') {
		ET_DrawDeleteAll();
		QueueExit();
	}
	var position_in_queue = Math.floor(eventid / 100);
	var queue_button = eventid - (position_in_queue * 100);
	if (queue_button == 1) {
		//remove track from queue
		player.removeAtPos(position_in_queue);
	}
	if (queue_button == 2) {
		//move to the very top of the player
		var temp_queue = player.getUrlAtPos(position_in_queue);
		player.removeAtPos(position_in_queue);
		player.addAtPos(1, temp_queue);
	}
	if (queue_button == 3) {
		//move track one position up in player
		var temp_queue = player.getUrlAtPos(position_in_queue);
		player.removeAtPos(position_in_queue);
		player.addAtPos(position_in_queue - 1, temp_queue);
	}
	if (queue_button == 4) {
		//move track one position down in player
		var temp_queue = player.getUrlAtPos(position_in_queue);
		player.removeAtPos(position_in_queue);
		player.addAtPos(position_in_queue + 1, temp_queue);
	}
	if (queue_button == 5) {
		//move track to the very bottom in player
		var temp_queue = player.getUrlAtPos(position_in_queue);
		player.removeAtPos(position_in_queue);
		player.addAtPos(player.queueLength, temp_queue);
	}
	ET_DrawDeleteAll();
	QueueDraw();
}


function QueueExit()
{
    switch (queue_prevmode) {
		case MODE_COVERS: CoversMode(); break;
		case MODE_QUEUE: QueueMode(); break;
		case MODE_SEARCH: SearchMode(); break;
    }
}

//************************************************************
