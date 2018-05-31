// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Confirm layout
//
// ************************************************************

// ***************** settings ***************************

var CONFIRM_FONTCOLOR = DEFAULTFONTCOLOR;
var CONFIRM_FONTSIZE = 25;
var CONFIRM_MSG_FONTSIZE = 40;

var CONFIRM_BORDER_H = 5;

var CONFIRM_SIZE_H = 50;
var CONFIRM_GAP_Y = 8;

//***************** globals *********************************


var confirm_area_x;
var confirm_area_y;
var confirm_area_w = 700;
var confirm_area_h = 280;

var confirm_y;

var confirm_prevmode;

//***************** functions ********************************


function ConfirmCalculate()
{
    confirm_area_x = Math.floor((ET_GetWindowWidth() - confirm_area_w) / 2);
    confirm_area_y = Math.floor((ET_GetWindowHeight() - confirm_area_h) / 2) - 40;

    confirm_y = Math.floor((confirm_area_h - 5 * CONFIRM_FONTSIZE) / 2);
}


// switch layout to confirm display
function ConfirmMode()
{
    confirm_prevmode = mode;
    mode = MODE_CONFIRM;

    ET_DrawDeleteAll();

    program.layout = LAYOUT_PREFIX + "confirm";

    // this avoids nasty flickering
    program.setTimeout(ConfirmDraw, 1, false);
}


function ConfirmDraw()
{
    ET_DrawDeleteAll();
    ConfirmCalculate();
    ConfirmBuild();
    ET_DrawAll();
    SetTick();
}


function ConfirmBuild()
{

    ET_NewArea(confirm_area_x, confirm_area_y, confirm_area_w, confirm_area_h, COLOR_LIGHT);

    var albumid, trackurl, info1, info2, info3, info4, msg;

    if (selected_trackurl == "")
    {
        db.openQuery("SELECT albums.leadartistname, albums.albumname, COUNT(tracks.id), sum(tracks.playtimems)" +
                     " FROM albums, tracks" +
					 " WHERE tracks.albumid = albums.id" +
					 " AND albums.id = " + selected_albumid);

        albumid = selected_albumid

        info1 = db.getField(0);
        info2 = db.getField(1);
        info3 = db.getField(2) + " " + t('tracks');
        info4 = t('total_length') + " " + MsToTime(db.getField(3));

        db.closeQuery();

        msg = t('album');
    }
    else
    {
        // confirm track
        db.openQuery("SELECT albumid, leadartistname, trackname, albumname, year, playtimems " +
                     "FROM tracks " +
					 "WHERE url='" + selected_trackurl.replace(quotematch,"''") + "'");

        trackurl = selected_trackurl;
        albumid = db.getField(0);

        info1 = db.getField(1);
        info2 = db.getField(2);
        info3 = AlbumYear(db.getField(3), db.getField(4));
        info4 = MsToTime(db.getField(5));

        db.closeQuery();

        msg = t('song');
    }

    var x = 0;
    var y = 0;

    DrawCover(albumid, trackurl, x, y, confirm_area_h);

    x += confirm_area_h + 40;
    y += confirm_y;

    var w = confirm_area_w - confirm_area_h - 40;

    ET_SetFont(ARTISTFONTCOLOR, config_fontface, CONFIRM_FONTSIZE);
    ET_AddText(info1, x, y, w, DT_CENTER | DT_END_ELLIPSIS);
    y += CONFIRM_FONTSIZE;

    ET_SetFont(ALBUMFONTCOLOR, config_fontface, CONFIRM_FONTSIZE);
    ET_AddText(info2, x, y, w, DT_CENTER | DT_END_ELLIPSIS);
    y += CONFIRM_FONTSIZE;

    y += CONFIRM_FONTSIZE;

	ET_SetFont(DEFAULTFONTCOLOR, config_fontface, CONFIRM_FONTSIZE);
    ET_AddText(info3, x, y, w, DT_CENTER | DT_END_ELLIPSIS);
    y += CONFIRM_FONTSIZE;

    ET_AddText(info4, x, y, w, DT_CENTER | DT_END_ELLIPSIS);
    y += CONFIRM_FONTSIZE;

    ET_NewArea(confirm_area_x, confirm_area_y + confirm_area_h + 50, confirm_area_w, CONFIRM_MSG_FONTSIZE, COLOR_LIGHT);

    ET_SetFont(CONFIRM_FONTCOLOR, config_fontface, CONFIRM_MSG_FONTSIZE);

    if ((IniMaxTracksInQueue() == 1) || (!player.isPlaying()))
    {
        msg = t('play_this_x', msg);
    }
    else
    {
        msg = t('queue_this_x', msg);
    }

    ET_AddText(msg, 0, 0, confirm_area_w, DT_CENTER | DT_END_ELLIPSIS);

}


function ConfirmExit()
{
    switch (confirm_prevmode)
    {
    case MODE_SEARCH: SearchMode(); break;
    case MODE_TRACKS: TracksMode(); break;
    default: CoversMode(); break;
    }
}



function ConfirmOk()
{
    QueueOk();

    switch (confirm_prevmode)
    {
    case MODE_SEARCH: SearchMode(); break;
    default: CoversMode(); break;
    }

}


function ConfirmClick(eventid)
{
    // not used
}


//************************************************************

