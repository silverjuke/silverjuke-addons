// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Search layout
//
// ************************************************************

// ***************** settings ***************************

//var SEARCH_FONTCOLOR = 0x000979;
var SEARCH_FONTCOLOR = DEFAULTFONTCOLOR;
var SEARCH_FONTHICOLOR = 0xDD0000;
var SEARCH_FONTSIZE = 20; // user changable
var SEARCH_MSGFONTSIZE;

var SEARCH_BORDER_LEFTRIGHT = 119;
var SEARCH_BORDER_TOP = 70;
var SEARCH_BORDER_BOTTOM = 290;

var SEARCH_OVERLAP = 6;
var SEARCH_MARGIN = 10;

var SEARCH_GAP_X = 20;
var SEARCH_GAP_Y = 10;

var SEARCH_INFO_DY = 44;
var SEARCH_INFO_H = 206;

var SEARCH_SIZE_H_MIN;
var SEARCH_SIZE_W_MIN;

var SEARCH_TIMEOUT = 2;

//***************** globals *********************************

var search_area_w;
var search_area_h;

var search_size_w;
var search_size_h;

var search_offset_y;

var search_count_x;
var search_count_y;
var search_pagesize;

var search_msg_y;
var search_info_y;

var search_urls;

var search_offset;

var search_string;

var search_mode;

var search_pending = 0;

var search_keyboard_drawarea = 0;

//***************** functions ********************************

// edit layout configuration
function SearchConfig()
{
    var dlg = new Dialog();

    dlg.addStaticText(t('search_layout') + "\n");

    dlg.addTextCtrl("fontsize", t('artist_album_track_fontsize'), SEARCH_FONTSIZE);

    mode = 0;

    if (dlg.showModal() == "ok")
    {
        program.iniWrite(CONFIGNAME + "/search_fontsize", dlg.getValue("fontsize"));
        SearchCalculate();
        SearchDraw();
    };

    mode = MODE_SEARCH;
}


function SearchCalculate()
{
    SEARCH_FONTSIZE = Number(program.iniRead(CONFIGNAME + "/search_fontsize", SEARCH_FONTSIZE));
    if (SEARCH_FONTSIZE < 10) SEARCH_FONTSIZE = 10;
    if (SEARCH_FONTSIZE > 100) SEARCH_FONTSIZE = 100;

    SEARCH_SIZE_H_MIN = 3 * SEARCH_FONTSIZE + 2 * SEARCH_MARGIN;
    SEARCH_MSGFONTSIZE = Math.floor(1.5 * SEARCH_FONTSIZE);
    SEARCH_SIZE_W_MIN = 5 * SEARCH_SIZE_H_MIN;

    search_area_w = ET_GetWindowWidth() - 2 * SEARCH_BORDER_LEFTRIGHT;
    search_area_h = ET_GetWindowHeight() - SEARCH_BORDER_TOP - SEARCH_BORDER_BOTTOM;

    search_count_x = Math.floor((search_area_w + SEARCH_GAP_X) / (SEARCH_SIZE_W_MIN + SEARCH_GAP_X))
    search_size_w = Math.floor((search_area_w + SEARCH_GAP_X) / search_count_x) - SEARCH_GAP_X;

    search_count_y = Math.floor((search_area_h + SEARCH_GAP_Y) / (SEARCH_SIZE_H_MIN + SEARCH_GAP_Y));
    search_size_h = Math.floor((search_area_h + SEARCH_GAP_Y) / search_count_y) - SEARCH_GAP_Y;

    search_offset_y = Math.floor((search_size_h - SEARCH_SIZE_H_MIN) / 2);

    search_msg_y = Math.floor((search_area_h - SEARCH_MSGFONTSIZE) / 2);

    search_info_y = SEARCH_BORDER_TOP + search_area_h + SEARCH_INFO_DY;

    search_pagesize = search_count_x * search_count_y;
}


function SearchReset()
{
    Filter("");
    ET_KeyboardSetBuffer("");

    search_string = "";
    search_offset = 0;
}


function SearchTerm()
{
    switch (search_mode)
    {
    case 1: return t('artists');
    case 2: return t('albums');
    case 3: return t('songs');
    }
}


// switch layout to covers display
function SearchMode(init)
{
    mode = MODE_SEARCH;

    ET_DrawDeleteAll();

    if (init)
    {
        search_mode = 0;
        SearchReset();
        search_pending = 0;

        ET_KeyboardReset();
    }
    else
    {
        Filter(search_string, search_mode);
    }

    switch (search_mode)
    {
    case 0: program.layout = LAYOUT_PREFIX + "search_all"; break;
    case 1: program.layout = LAYOUT_PREFIX + "search_artist"; break;
    case 2: program.layout = LAYOUT_PREFIX + "search_album"; break;
    case 3: program.layout = LAYOUT_PREFIX + "search_track"; break;
    }

    // this avoids nasty flickering
    program.setTimeout(SearchDraw, 1, false);
}


function SearchDraw()
{
    ET_DrawDeleteAll();
    SearchCalculate();
    SearchBuildSearchInfo();
    SearchBuildAlbums();
    SearchBuildKeyboard();
    ET_DrawAll();
    SetTick();
}


function SearchBuildAlbums()
{
    // make sure we have some albums in view
    if (search_offset < 0)
    {
        search_offset = search_pagesize * Math.floor((filter_trackcount - 1) / search_pagesize);
    }
    if (search_offset >= filter_trackcount)
    {
        search_offset = 0;
    }

    ET_NewArea(SEARCH_BORDER_LEFTRIGHT, SEARCH_BORDER_TOP, search_area_w, search_area_h, COLOR_LIGHT);
    // Decrease height of upper search results to create extra space for the middle bar
    // ET_NewArea(SEARCH_BORDER_LEFTRIGHT, SEARCH_BORDER_TOP, search_area_w, search_area_h - 65, COLOR_LIGHT);

    if ((search_string == "") || ! filter_trackcount || (search_pending > 0))
    {
        var msg;
        if (search_string == "")
        {
            if (search_mode)
            {
                msg = t('type_any_key_to_start_searching_x', SearchTerm());
            }
            else
            {
                msg = t('type_any_key_to_start_searching_all');
            }
        }
        else if (search_pending > 0)
        {
            msg = t('tap_ok_to_run_search');
        }
        else
        {
            msg = t('no_matches_found');
        }

        ET_SetFont(SEARCH_FONTCOLOR, config_fontface, SEARCH_MSGFONTSIZE);
        ET_AddText(msg, 0, search_msg_y, search_area_w, DT_CENTER | DT_END_ELLIPSIS);

        ET_AddClickArea(0, 0, search_area_w, search_area_h, -1);

        return;
    }

    db.openQuery("SELECT tracks.albumid, tracks.url, tracks.leadartistname, tracks.albumname, tracks.trackname " +
                " FROM albums, tracks " +
				" WHERE " + filter_expr + 
				" AND albums.id == tracks.albumid" +
                " ORDER BY albums.albumindex, tracks.tracknr " +
                " LIMIT " + search_pagesize + " offset " + search_offset);

    search_urls = new Array();
    var clickid = 1000;
    var text_w = search_size_w - search_size_h - 4 * SEARCH_MARGIN;
    var col;
    var x = 0;
    for (col = 0; col < search_count_x; ++col)
    {
        var row;
        var y = 0;

        for (row = 0; row < search_count_y; ++row)
        {
            if (db.nextRecord())
            {
                ET_AddClickArea(x, y, search_size_w, search_size_h, clickid++);
                search_urls.push(db.getField(1));

                var xx = x + search_size_h - SEARCH_OVERLAP;

                // Temporarily disable search thumbnails as long as the bug exists
				//var slowimage = DrawCover(db.getField(0), db.getField(1), x, y, search_size_h, undefined, true, false);
                ET_AddImage(IMG_TRACKFRAME, x, y, search_size_w - search_size_h - SEARCH_OVERLAP + (xx-x), search_size_h, ET_REPEAT_GRID, 0);

                xx += SEARCH_OVERLAP + 2 * SEARCH_MARGIN;
                var yy = y + search_offset_y + SEARCH_MARGIN;

                ET_SetFont(ARTISTFONTCOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_AddText(db.getField(2), xx, yy, text_w, DT_END_ELLIPSIS);
                ET_SetFont(SEARCH_FONTHICOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_Hilite(db.getField(2), xx, yy, text_w, DT_END_ELLIPSIS);

                yy += SEARCH_FONTSIZE;

                ET_SetFont(ALBUMFONTCOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_AddText(db.getField(3), xx, yy, text_w, DT_END_ELLIPSIS);
                ET_SetFont(SEARCH_FONTHICOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_Hilite(db.getField(3), xx, yy, text_w, DT_END_ELLIPSIS);
                yy += SEARCH_FONTSIZE;

                ET_SetFont(TITLEFONTCOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_AddText(db.getField(4), xx, yy, text_w, DT_END_ELLIPSIS);
                ET_SetFont(SEARCH_FONTHICOLOR, config_fontface, SEARCH_FONTSIZE);
                ET_Hilite(db.getField(4), xx, yy, text_w, DT_END_ELLIPSIS);
                yy += SEARCH_FONTSIZE;

                // if slow image then update the screen
                //if (slowimage) ET_DrawAll();
            }

            y += search_size_h + SEARCH_GAP_Y;
        }

        x += search_size_w + SEARCH_GAP_X;
    }

    db.closeQuery();
}


function SearchBuildSearchInfo()
{
    ET_NewArea(SEARCH_BORDER_LEFTRIGHT, search_info_y - 38, search_area_w, 34, COLOR_MIDDLE);
    ET_AddClickArea(0, 0, search_area_w, 34, -1);

    var msg = "";
    if (search_string != "")
    {
        var msg_for = "";

        if (search_mode)
        {
            msg_for = t('search_for_x', SearchTerm()); ;
        }
        else
        {
            msg_for = t('search_for_all');
        }

        msg_for += " '";

        var msg_search = search_string;

        var msg_result = "' ...";

        if (filter_trackcount && (search_pending == 0))
        {
            msg_result += " " + t('results_x_tracks_in_y_albums',
                                filter_trackcount + " " + ((filter_trackcount != 1) ? t('tracks') : t('track')),
                                filter_albumcount + " " + ((filter_albumcount != 1) ? t('albums') : t('album')));
        }

        ET_SetFont(0xFFFFFF, config_fontface, 22);
        var w_for = ET_SizeText(msg_for, msg_for.length);
        var w_result = ET_SizeText(msg_result, msg_result.length);

        ET_SetFont(SEARCH_FONTHICOLOR, config_fontface, 28);
        var w_search = ET_SizeText(msg_search, msg_search.length);

        var x = Math.floor((search_area_w - w_for - w_search - w_result) / 2);

        ET_AddFill(x + w_for - 5, 4, w_search + 10, 26, COLOR_LIGHT);

        ET_AddText(msg_search, x + w_for, 2, w_search);

        ET_SetFont(0xFFFFFF, config_fontface, 22);
        ET_AddText(msg_for, x, 5, w_for);
        ET_AddText(msg_result, x + w_for + w_search, 5, w_result);
    }
}


function SearchBuildKeyboard()
{
    search_keyboard_drawarea = ET_NewArea(SEARCH_BORDER_LEFTRIGHT, search_info_y, search_area_w, SEARCH_INFO_H, COLOR_LIGHT);

    ET_Keyboard(SEARCH_BORDER_LEFTRIGHT, search_info_y, search_area_w, SEARCH_INFO_H,
               "button_keyboard.png", "button_keyboard_hi.png", "button_keyboard_click.png");

    ET_KeyboardDraw();
}


// jump searchlayout a full page backwards
function SearchPrev()
{
    if (search_offset >= search_pagesize)
    {
        search_offset -= search_pagesize;
    }
    else if (search_offset > 0)
    {
        search_offset = 0;
    }
    else
    {
        search_offset = -1;
    }

    SearchDraw();
}


// jump searchlayout a full page forwards
function SearchNext()
{
    search_offset += search_pagesize;
    SearchDraw();
}


function SearchWhere(mode)
{
    search_mode = mode;
    SearchMode();
}

function SearchExit()
{
    Filter("");
    CoversMode();
}


function SearchTick()
{
    if (--search_pending == 0)
    {
        Filter(search_string, search_mode);
        search_pending = 0;
        SearchDraw();
    }
}


function SearchKey(charcode)
{
    if (charcode == 13)
    {
        // enter
        Filter(search_string, search_mode);
        search_pending = 0;
        SearchDraw();
    }
    else if (charcode > 0)
    {
        if (charcode == 8)
        {
            // backspace
            if (search_string.length == 0)
            {
                SetTick();
                return;
            }

            search_string = search_string.substr(0, search_string.length - 1);
        }
        else
        {
            var key = String.fromCharCode(charcode);
            search_string += key;
        }

        if (config_autosearch)
        {
            Filter(search_string, search_mode);
        }
        else
        {
            search_pending = SEARCH_TIMEOUT;
        }

        SearchDraw();
    }
}


// mouseclick
function SearchClick(eventid)
{
    if (eventid == -1)
    {
        if (search_string == "")
        {
            if (search_mode)
            {
                SearchWhere(0);
            }
        }
        else
        {
            SearchReset();
            SearchDraw();
            search_pending = 0;
        }
    }
    else if (eventid >= 1000)
    {
        selected_trackurl = search_urls[eventid - 1000];
        TrackQueue();
    }
    else
    {
        // highlight the clicked key
        ET_KeyboardDraw(eventid);
        ET_DrawAll();

        var result = ET_KeyboardProcess(eventid);

        switch (result)
        {
        case 1:
            search_string = ET_KeyboardGetBuffer();

            if (config_autosearch)
            {
                Filter(search_string, search_mode);
            }
            else
            {
                search_pending = SEARCH_TIMEOUT;
            }
            break;

        case 2:
            // enter
            Filter(search_string, search_mode);
            search_pending = 0;
            break;

        case 3:
            // keyboard mode changed
            break;

        }

        SearchDraw();
    }
}


//************************************************************

