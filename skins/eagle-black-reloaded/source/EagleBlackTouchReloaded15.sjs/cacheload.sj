// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Cacheload layout
//
// ************************************************************

// ***************** settings ***************************

var CACHELOAD_BORDER_LEFTRIGHT = 0;
var CACHELOAD_BORDER_TOP = 0;
var CACHELOAD_BORDER_BOTTOM = 30;
var CACHELOAD_GAP = 10;

//***************** globals *********************************

var cacheload_area_w;
var cacheload_area_h;

var cacheload_count_x;
var cacheload_count_y;
var cacheload_pagesize;

var cacheload_offset_x;

var cacheload_offset;
var cacheload_albumcount;

var cacheload_row;

//***************** functions ********************************


function CacheLoadCalculate()
{
    CoversCalculate();

    var size = COVERS_ARTSIZE + CACHELOAD_GAP;

    cacheload_area_w = ET_GetWindowWidth() - 2 * CACHELOAD_BORDER_LEFTRIGHT;
    cacheload_area_h = ET_GetWindowHeight() - CACHELOAD_BORDER_TOP - CACHELOAD_BORDER_BOTTOM;

    cacheload_count_x = Math.floor((cacheload_area_w + CACHELOAD_GAP) / size);
    cacheload_count_y = Math.floor((cacheload_area_h + CACHELOAD_GAP) / size);

    cacheload_offset_x = Math.floor((cacheload_area_w + CACHELOAD_GAP - cacheload_count_x * size) / 2);
    cacheload_offset_y = Math.floor((cacheload_area_h + CACHELOAD_GAP - cacheload_count_y * size) / 2);

    cacheload_pagesize = cacheload_count_x * cacheload_count_y;
}


// switch layout to cacheload display
function CacheLoadMode()
{
    mode = MODE_CACHELOAD;

    ET_DrawDeleteAll();

    program.layout = LAYOUT_PREFIX + "cacheload";

    db.openQuery("SELECT COUNT(*)" + 
				" FROM albums;");
    cacheload_albumcount = Number(db.getField(0));
    db.closeQuery();

    cacheload_offset = 0;
    cacheload_row = 0;

    // this avoids nasty flickering
    program.setTimeout(CacheLoadDraw, 1, false);
}


function CacheLoadDraw()
{
    if (cacheload_offset >= cacheload_albumcount)
    {
        db.closeQuery();
        CoversMode();
        return;
    }

    CacheLoadCalculate();
    CacheLoadBuild()
    ET_DrawAll();

    if (++cacheload_row >= cacheload_count_y)
    {
        db.closeQuery();
        cacheload_row = 0;
        cacheload_offset += cacheload_pagesize;
    }

    // auto to next page
    program.setTimeout(CacheLoadDraw, 1, false);
}


function CacheLoadBuild()
{
    if (cacheload_row == 0)
    {
        ET_DrawDeleteAll();

        ET_NewArea(CACHELOAD_BORDER_LEFTRIGHT, CACHELOAD_BORDER_TOP, cacheload_area_w, cacheload_area_h, 0x000000);

        db.openQuery("SELECT albums.id, albums.albumname " +
                     "FROM albums, tracks WHERE albums.id == tracks.albumid " +
                     "GROUP BY albums.id ORDER BY albums.albumindex " +
                     "LIMIT " + cacheload_pagesize + " OFFSET " + cacheload_offset);
    }

    program.setSkinText("cacheload_info", tt.caching_album_art + ": " + (cacheload_offset + cacheload_row * cacheload_count_x) + "/" + cacheload_albumcount +". " + tt.touch_to_abort);

    var x = cacheload_offset_x;
    var y = cacheload_offset_y + cacheload_row * (COVERS_ARTSIZE + CACHELOAD_GAP);
    var col;
    for (col = 0; col < cacheload_count_x; ++col)
    {
        if (db.nextRecord())
        {
            DrawCover(db.getField(0), undefined, x, y, COVERS_ARTSIZE, 0, true, covers_border);
        }

        x += COVERS_ARTSIZE + CACHELOAD_GAP;
    }
}


function CacheLoadAbort()
{
    cacheload_offset = cacheload_albumcount;
}

