// ***************** settings ********************************

var VERSION = "musictube";
var CONFIGNAME = "musictube";

var PROGRESS_STEP = 100;
var QUICKINDEX_EMPTY = "(empty)";
var QUICKINDEX_UNUSED = " -";
var QUICKINDEX_PAGESIZE = 25;
var INFOLINE_COUNT = 8;
var MSG_TIME = 1000;

// ***************** globals *********************************

var configdlg;
var config_ratingdb = "c:\\globalrating.db"
var config_mintracksperartist = 0; // not configurable in this skin

var db;
var dbindex;
var dbrating;

var quotematch = new RegExp("'","g");
var omitmatch;

var quickfiltername = "QuickFilter";
var quickfilterid = -1;

var quickindexmode = 0;
var quick = new Array(undefined, undefined, undefined, undefined);
var quicklast = new Array(undefined, undefined, undefined, undefined);
var quickfilter = "(1)";
var quickindex = new Array(QUICKINDEX_PAGESIZE);
var quickindexpos = 0;
var quickindexcount = 0;

var kioskrefresh_search;
var kioskrefresh_musicsel;

//****************** startup *********************************

program.onLoad = Init;

//***************** functions ********************************


function Init()
{
    db = new Database();
    dbindex = new Database();

    program.layout = "default";

    InitOmit()

    quickfilterid = MusicSearchInit(quickfiltername)

    QuickIndexInit();

    player.onTrackChange = NowPlayingDraw;

    program.onKioskStarting = KioskRefreshInit;
    program.onKioskStarted = KioskRefresh;

    program.onKioskEnding = KioskRefreshInit;

    program.onKioskEnded = KioskRefresh;
	
    program.addMenuEntry('Configure musictube skin', ConfigEdit);
    program.addMenuEntry('Write Ratings to global Database', GlobalRatingWrite);
    program.addMenuEntry('Read Ratings from global Database', GlobalRatingRead);
}


function KioskRefreshInit()
{
    kioskrefresh_search = program.search;
    kioskrefresh_musicsel = program.musicSel;
}


function KioskRefresh()
{
	ScreenUpdate();
    if (quickindexmode >= -1) QuickIndexDraw();
    QuickFilterDraw();
    NowPlayingDraw();

    program.musicSel = kioskrefresh_musicsel;
    program.search = kioskrefresh_search;
}


// read our stored configuration
function ConfigRead()
{
    config_ratingdb = program.iniRead(CONFIGNAME + "/ratingdb", config_ratingdb);
}


// edit our configuration, store & apply changes
function ConfigEdit()
{
    configdlg = new Dialog();

    configdlg.addStaticText(VERSION + " configuration\n");

    configdlg.addTextCtrl("ratingdb", "Global rating database (empty if no global ratings)", config_ratingdb);
    configdlg.addButton("ratingdbselect", 'Select...', ConfigRatingdbSelect);

    if (configdlg.showModal() == "ok")
    {
        program.iniWrite(CONFIGNAME + "/ratingdb", configdlg.getValue("ratingdb"));

        ConfigRead();
    };

    configdlg = undefined;
}


function ConfigRatingdbSelect()
{
    var file = fileSel("Select Global rating database", configdlg.getValue("ratingdb"), 1);

    if (file) configdlg.setValue('ratingdb', file);
}


function GlobalRatingRead()
{
    if (GlobalRatingOpen())
    {
        program.setDisplayMsg("reading ratings...");

	dbrating.openQuery("select count() from globalrating;");
	var total = dbrating.getField(0);
        var count = 0;
	dbrating.closeQuery();

        dbrating.openQuery("select artist, album, title, rating from globalrating;");

        db.openQuery("begin");
	db.closeQuery();

        while (dbrating.nextRecord())
        {
            var artist = dbrating.getField(0).replace(quotematch,"''");
            var album = dbrating.getField(1).replace(quotematch,"''");
            var title = dbrating.getField(2).replace(quotematch,"''");
            var rating = Number(dbrating.getField(3));

            db.openQuery("update tracks set rating = " + rating +
                         " where leadartistname = '" + artist +
                         "' and albumname = '" + album +
                         "' and trackname = '" + title + "';");
            db.closeQuery();

            if ((++count % PROGRESS_STEP) == 0)
            {
                program.setDisplayMsg("reading ratings " + count + "/" + total + "...");
            }
        }

        db.openQuery("commit");
	db.closeQuery();

	dbrating.closeQuery();

        program.setDisplayMsg("");

        dbrating = undefined;
    }
}


function GlobalRatingWrite()
{
    if (GlobalRatingOpen())
    {
        program.setDisplayMsg("writing ratings...");

	db.openQuery("select count() from tracks where rating > 0;");
	var total = db.getField(0);
        var count = 0;
	db.closeQuery();

        db.openQuery("select leadartistname, albumname, trackname, rating from tracks where rating > 0;");

        dbrating.openQuery("begin");
	dbrating.closeQuery();

        while (db.nextRecord())
        {
            var artist = db.getField(0).replace(quotematch,"''");
            var album = db.getField(1).replace(quotematch,"''");
            var title = db.getField(2).replace(quotematch,"''");
            var rating = Number(db.getField(3));

            dbrating.openQuery("insert or replace into globalrating (artist, album, title, rating) values ('" +
                               artist + "', '" + album + "', '" + title + "' ,'" + rating + "');");
            dbrating.closeQuery();

            if ((++count % PROGRESS_STEP) == 0)
            {
                program.setDisplayMsg("writing ratings " + count + "/" + total + "...");
            }
        }

        dbrating.openQuery("commit");
	dbrating.closeQuery();

	db.closeQuery();

        program.setDisplayMsg("");

        dbrating = undefined;
    }
}


// open (create if not existing) the global rating database
function GlobalRatingOpen()
{
    var dir = config_ratingdb.substr(0, config_ratingdb.lastIndexOf("\\"));

    if (!File.isdir(dir))
    {
        alert("Cannot open or create Global rating file '" + config_ratingdb + "'");
        return false;
    }

    dbrating = new Database(config_ratingdb);

    // WEIRD: SQL 'if exists' is not working?
    // dbindex.openQuery("drop table if exists globalrating;");
    dbrating.openQuery("select count() from sqlite_master where name = 'globalrating';");
    if (dbrating.getField(0) == 0)
    {
        dbrating.closeQuery();
        dbrating.openQuery('create table globalrating (artist, album, title, rating);');
    }
    dbrating.closeQuery();

    dbrating.openQuery("select count() from sqlite_master where name = 'globalrating_index1';");
    if (dbrating.getField(0) == 0)
    {
        dbrating.closeQuery();
        dbrating.openQuery('create unique index globalrating_index1 on globalrating (artist, album, title);');
    }
    dbrating.closeQuery();


    return true;
}


// build a regexp for leading 'omit words'
function InitOmit()
{
    var omitexpr = "^(";
    var omitlist = program.iniRead("library/omitArtistWords","the, der, die, die happy, das").split(",");

    var trim = new RegExp("^ | $");
    for (i = 0; i < omitlist.length; ++i)
    {
        if (i > 0) { omitexpr += '|'; }
        omitexpr += omitlist[i].replace(trim, "") + " ";
    }
    omitexpr += ')';

    omitmatch = new RegExp(omitexpr, "i");
}


// set up a temp table to use for indexing
function QuickIndexInit()
{
    // WEIRD: SQL 'if exists' is not working?
    // dbindex.openQuery("drop table if exists quickindex;");
    db.openQuery("select count() from sqlite_master where name = 'quickindex';");
    if (db.getField(0) > 0)
    {
        db.closeQuery();
        db.openQuery("drop table quickindex;");
    }
    db.closeQuery();

    db.openQuery("create temporary table quickindex (value, sort)");
    db.closeQuery();

    QuickFilterClear();
}


// fill the temp index table for the given mode
function QuickIndexCreate(mode)
{
    program.setDisplayMsg("create index...");

    dbindex.openQuery("begin;");
    dbindex.closeQuery();

    dbindex.openQuery("delete from quickindex;");
    dbindex.closeQuery();

    switch (mode)
    {
    case -1:
        db.openQuery("select name from advsearch where name != '" + quickfiltername + "'");
        break;

    case 0:
        if (config_mintracksperartist == 0)
        {
            db.openQuery("select distinct leadartistname from tracks where " + quickfilter);
        }
        else
        {
            db.openQuery("select leadartistname from tracks where " + quickfilter +
                         " group by leadartistname having count() >= " + config_mintracksperartist);
        }
        break;

    case 1:
        db.openQuery("select distinct genrename from tracks where " + quickfilter);
        break;

    case 2:
    case 3:
        db.openQuery("select distinct year from tracks where " + quickfilter);
        break;

    case 4:
    case 5:
        db.openQuery("select distinct rating from tracks where " + quickfilter);
        break;

    }

    quickindexpos = 0;
    quickindexcount = 0;
    while (db.nextRecord())
    {
        var value = db.getField(0).replace(quotematch, "''");
        var sort = value.replace(omitmatch, "");

        dbindex.openQuery("insert into quickindex (value, sort) values ('" + value + "', sortable('" + sort + "'))");

        if ((++quickindexcount % PROGRESS_STEP) == 0)
        {
            program.setDisplayMsg("create index " + quickindexcount + "...");
        }
    }

    dbindex.closeQuery();

    dbindex.openQuery("commit;");
    dbindex.closeQuery();

    program.setDisplayMsg("");
}


// use the given entry on de temp index page for the active quickfilter setting
function QuickIndexSelect(nr)
{
    if (quickindexmode >= -1)
    {
        var value = quickindex[nr];

        if (value != undefined)
        {
            if (quickindexmode == -1)
            {
                var search = program.search;
                program.musicSel = value;
                program.search = search;
                program.refreshWindows(2);
            }
            else
            {
                quick[quickindexmode] = value;
                QuickFilterDraw();
                QuickFilterSQL();
            }
        }
    }
}


// jump to first temp index for given char of artist name
function QuickIndexJump(c)
{
    if (quickindexmode == 0)
    {
        dbindex.openQuery("select count() from quickindex where sort < '" + c + "' order by sort");
        var offset = dbindex.getField(0);
        dbindex.closeQuery();

        quickindexpos = Math.min(offset, quickindexcount - 1);
        QuickIndexDraw();
    }
}


// jump to first temp index page
function QuickIndexFirst()
{
    if (quickindexmode >= -1)
    {
        quickindexpos = 0;
        QuickIndexDraw();
    }
}


// jump to previous temp index page
function QuickIndexPrev()
{
    if (quickindexmode >= -1)
    {
        quickindexpos = Math.max(quickindexpos - QUICKINDEX_PAGESIZE, 0);
        QuickIndexDraw();
    }
}


// jump to next temp index page
function QuickIndexNext()
{
    if (quickindexmode >= -1)
    {
        quickindexpos = Math.min(quickindexpos + QUICKINDEX_PAGESIZE, Math.max(quickindexcount - QUICKINDEX_PAGESIZE, 0));
        QuickIndexDraw();
    }
}


// jump to last temp index page
function QuickIndexLast()
{
    if (quickindexmode >= -1)
    {
        quickindexpos = Math.max(quickindexcount - QUICKINDEX_PAGESIZE, 0);
        QuickIndexDraw();
    }
}


// draw the current temp index page
function QuickIndexDraw()
{
    var leadspaces = Spaces(9 - ("" + quickindexpos + "" + quickindexcount).length);
    program.setSkinText("quickindexpos", leadspaces + (quickindexpos + 1) + "/" + quickindexcount);

    dbindex.openQuery("select value from quickindex order by sort limit " + QUICKINDEX_PAGESIZE + " offset " + quickindexpos);

    for (i = 0; i < QUICKINDEX_PAGESIZE; ++i)
    {
        if (dbindex.nextRecord())
        {
            var value = dbindex.getField(0);
            quickindex[i] = value;

            if (value == "") value = QUICKINDEX_EMPTY;
            program.setSkinText("quickindex" + i, value);
        }
        else
        {
            program.setSkinText("quickindex" + i, "");
            quickindex[i] = undefined;
        }
    }

    dbindex.closeQuery();
}


// clear & hide all current quickfilter settings
function QuickFilterClear(clearmusicsel)
{
    var mode, i;

    for (mode = 0; mode < 5; ++mode)
    {
        var prev = quick[mode];

        if (prev != undefined)
        {
            quicklast[mode] = prev;
            quick[mode] = undefined;
        }
    }

    program.setSkinText("quickindexpos", "");

    for (i = 0; i < QUICKINDEX_PAGESIZE; ++i)
    {
        program.setSkinText("quickindex" + i, "");
    }

    for (i = 0; i < 6; ++i)
    {
        program.setSkinText("quick" + i, "");
    }

    if (clearmusicsel)
    {
        var search = program.search;
        program.musicSel = "";
        program.search = search;
        program.refreshWindows(2);
    }

    quickindexmode = -2;
}


// set up temp index for music searches
function QuickFilterModePreset()
{
    QuickFilterClear(program.musicSel == quickfiltername);

    quickindexmode = -1;
    QuickIndexCreate(-1);
    QuickIndexDraw();
}


// set up the temp index for the given quickfilter setting and clear or recall its setting
function QuickFilterMode(mode)
{
    var current = quick[mode];

    if (current != undefined)
    {
        quicklast[mode] = current;
    }

    quick[mode] = undefined;
    QuickFilterSQL();

    if (mode != quickindexmode)
    {
        // create 'index' for current mode
        QuickIndexCreate(mode);
        QuickIndexDraw();

        quickindexmode = mode;
    }

    if (current == undefined)
    {
        quick[mode] = quicklast[mode];
        QuickFilterSQL();
    }

    QuickFilterDraw();
}


// draw all quickfilter settings
function QuickFilterDraw()
{
    for (i = 0; i < 6; ++i)
    {
        var value = quick[i];

        if (value == undefined) value = QUICKINDEX_UNUSED;
        else if (value == "") value = QUICKINDEX_EMPTY;

        program.setSkinText("quick" + i, value);
    }
}


// create an SQL searchexpression from a searchstring
function QuickFilterSQL()
{
    quickfilter = "(1";

    if (quick[0] != undefined)
    {
        quickfilter += " and leadartistname = '" + quick[0].replace(quotematch, "''") + "'";
    }

    if (quick[1] != undefined)
    {
        quickfilter += " and genrename = '" + quick[1].replace(quotematch, "''") + "'";
    }

    if (quick[2] != undefined)
    {
        quickfilter += " and year >= '" + quick[2] + "'";
    }

    if (quick[3] != undefined)
    {
        quickfilter += " and year <= '" + quick[3] + "'";
    }

    if (quick[4] != undefined)
    {
        quickfilter += " and rating >= '" + quick[4] + "'";
    }

    if (quick[5] != undefined)
    {
        quickfilter += " and rating <= '" + quick[5] + "'";
    }

    quickfilter += ")";

    MusicSearchSet(quickfilterid, "1", quickfilter);

    var search = program.search;
    program.musicSel = quickfiltername;
    program.search = search;
//    program.refreshWindows(2);
}


function SetRating(rating)
{
    if (player.queueLength > 0)
    {
        var url = player.getUrlAtPos()

        db.openQuery("update tracks set rating=" + rating + "where url = '" + url.replace(quotematch,"''") + "';");
        db.closeQuery();

        if (rating > 0)
        {
            program.setDisplayMsg("Rating set to " + rating, MSG_TIME);
        }
        else
        {
            program.setDisplayMsg("Rating cleared", MSG_TIME);
        }

        NowPlayingDraw();
    }
}


// set up a new SJ music search filter to be used for our own SQL expressions
function MusicSearchInit(filtername)
{
    var filterid = -1;

    db.openQuery("select id from advsearch where name = '" + filtername + "';");
    if (db.nextRecord())
    {
        filterid = db.getField(0);		
    }
    db.closeQuery();

    if (filterid == -1)
    {
        db.openQuery("insert into advsearch (name) values ('" + filtername + "');");
        db.closeQuery();

        // getField(-1) does not work, SilverJuke bug?
        // as workaround just run the select again instead
        db.openQuery("select id from advsearch where name = '" + filtername + "';");
        filterid = db.getField(0);		
        db.closeQuery();
    }

    return filterid;
}


// set up a SJ music search filter based on a given SQL expression
function MusicSearchSet(filterid, selecttracks, filter)
{	
    var quotematch = new RegExp("'", "g");

    db.openQuery("update advsearch set rules='" +
                  "1:5" +
                  DecToHex(filterid.length) + ":" + filterid +
                  "a:TempFilter" +
                  "1:" + selecttracks +
                  "1:01:11:51:21:0" +
                  DecToHex(filter.length) + ":" + filter.replace(quotematch,"''") +
                  "0:1:0" +
                  "' where id=" + filterid + ";");
    db.closeQuery();
}	


function NowPlayingDraw()
{
	ScreenUpdate();
    var linenr = 0;

    if (player.queuelength > 0)
    {
        program.setSkinText('now_artist', "");
        program.setSkinText('now_title', "");
        program.setSkinText('now_album', "");
    }
    else
    {
        var url = player.getUrlAtPos();
        var album = player.getAlbumAtPos();

        db.openQuery("select year, rating, bitrate, samplerate, channels, playtimems from tracks where url='" + url.replace(quotematch, "''") + "';");

        if (db.nextRecord())
        {
            var year = Number(db.getField(0));
            if (year > 0)
            {
                if (album != "") album += ", ";
                album += year;
            }

            var duration = Number(db.getField(5));
            if (duration > 0) program.setSkinText("now_info" + linenr++, "Duration: " + MsToTime(duration));

            var bitrate = Number(db.getField(2));
            if (bitrate > 0) program.setSkinText("now_info" + linenr++, "Bitrate: " + bitrate / 1000 + "kbps");

            var samplerate = Number(db.getField(3));
            if (samplerate > 0) program.setSkinText("now_info" + linenr++, "Samplerate: " + samplerate / 1000 + "kHz");

            var channels = Number(db.getField(4));
            switch (channels)
            {
            case 1: program.setSkinText("now_info" + linenr++, "Channels: Mono"); break;
            case 2: program.setSkinText("now_info" + linenr++, "Channels: Stereo"); break;
            }

            var rating = Number(db.getField(1));
            switch (rating)
            {
            case 1: program.setSkinText("now_info" + linenr++, "Rating: *"); break;
            case 2: program.setSkinText("now_info" + linenr++, "Rating: * *"); break;
            case 3: program.setSkinText("now_info" + linenr++, "Rating: * * *"); break;
            case 4: program.setSkinText("now_info" + linenr++, "Rating: * * * *"); break;
            case 5: program.setSkinText("now_info" + linenr++, "Rating: * * * * *"); break;
            }
        }

        if (album != "") album = "(" + album + ")";

        program.setSkinText('now_artist', player.getArtistAtPos());
        program.setSkinText('now_title', player.getTitleAtPos());
        program.setSkinText('now_album', album);

        db.closeQuery();

    }

    while (linenr < INFOLINE_COUNT) program.setSkinText("now_info" + linenr++, "");

    if (player.queueLength > player.queuePos)
    {
        program.setSkinText("now_next", "Next:");
        program.setSkinText("now_next_artist", player.getArtistAtPos(player.queuePos + 1));
        program.setSkinText("now_next_title", player.getTitleAtPos(player.queuePos + 1));
    }
    else
    {
        program.setSkinText("now_next", "");
        program.setSkinText("now_next_artist", "");
        program.setSkinText("now_next_title", "");
    }
	
	
}


// convert decimal value into hex representation (needed for SJ internal filters)
function DecToHex(dec)
{
    var hex = "";

    while (dec)
    {
        switch (dec % 16)
        {
            case 0:  hex = "0" + hex; break;
            case 1:  hex = "1" + hex; break;
            case 2:  hex = "2" + hex; break;
            case 3:  hex = "3" + hex; break;
            case 4:  hex = "4" + hex; break;
            case 5:  hex = "5" + hex; break;
            case 6:  hex = "6" + hex; break;
            case 7:  hex = "7" + hex; break;
            case 8:  hex = "8" + hex; break;
            case 9:  hex = "9" + hex; break;
            case 10: hex = "a" + hex; break;
            case 11: hex = "b" + hex; break;
            case 12: hex = "c" + hex; break;
            case 13: hex = "d" + hex; break;
            case 14: hex = "e" + hex; break;
            case 15: hex = "f" + hex; break;
        }

        dec = (dec - (dec % 16)) / 16;
    }

    return hex;
}


// convert milliseconds into 0:00 human time format
function MsToTime(ms)
{
    var disptime = "";
    var pos = 0;

    ms = (ms - (ms % 1000)) / 1000;

    while (ms)
    {
        var divisor = 10;

        if (pos == 1)
        {
            divisor = 6;
        }

        switch (ms % divisor)
        {
            case 0:  disptime = "0" + disptime; break;
            case 1:  disptime = "1" + disptime; break;
            case 2:  disptime = "2" + disptime; break;
            case 3:  disptime = "3" + disptime; break;
            case 4:  disptime = "4" + disptime; break;
            case 5:  disptime = "5" + disptime; break;
            case 6:  disptime = "6" + disptime; break;
            case 7:  disptime = "7" + disptime; break;
            case 8:  disptime = "8" + disptime; break;
            case 9:  disptime = "9" + disptime; break;
        }

        ms = (ms - (ms % divisor)) / divisor;

        if (++pos == 2)
        {
            disptime = ":" + disptime;
        }
    }

    switch (pos)
    {
    case 0: disptime = "0:00" + disptime; break;
    case 1: disptime = "0:0"  + disptime; break;
    case 2: disptime = "0"    + disptime; break;
    }

    return disptime;
}


function Spaces(length)
{
    buf = "";

    while (length-- > 0)
    {
        buf = buf + " ";
    }

    return buf;
}

function ScreenUpdate()
{	
if (player.queueLength >0) 
	{
	program.setSkinText("artist",player.getArtistAtPos());
	program.setSkinText("album",player.getAlbumAtPos());
	program.setSkinText("title",player.getTitleAtPos());
	url = player.getUrlAtPos();
	var ratingstring ="";
	var year = "";
	var genre = "";
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("select rating,year,genrename from tracks where url ='"+url.replace(quoteExpr,"''")+"';");
	if( db.nextRecord() )  
		{
		rating = parseInt(db.getField(0));
		year = db.getField(1);
		if ( year == 0) 
			{
			year = "";
			}
			program.setSkinText("YearTest", year);
			genre = db.getField(2);
		    program.setSkinText("TestGenre",genre);
			switch (rating) 
			{
			case 0:	
				ratingstring = "";
				break;
			case 1:	
				ratingstring = "*";
				break;
			case 2:	
				ratingstring = "**";
				break;
			case 3:	
				ratingstring = "***";
				break;
			case 4:	
				ratingstring = "****";
				break;
			case 5:	
				ratingstring = "*****";
				break;
			}
		program.setSkinText("rating",ratingstring);
		}
	program.refreshWindows(2);	
	db.closeQuery();
	}
}


function fastbw() { player.time -= 10000; }
function fastfw() { player.time += 10000; }

function Rated() 
{ 
program.musicSel = "Rated"; 
program.setDisplayMsg('Rated selected', 1000); 
} 


function Genre() 
{ 
program.musicSel = "Genre"; 
program.setDisplayMsg('Genre selected', 1000); 
} 


function setRating0()
	{
	url = player.getUrlAtPos();
	if (url != "") 
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=0 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg ('Rating set to 0',1000);
	ScreenUpdate();
	}

function setRating1()
	{
	url = player.getUrlAtPos();
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=1 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg("Rating set to '*'",1000);
	ScreenUpdate();
	}

function setRating2()
	{
	url = player.getUrlAtPos();
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=2 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg("Rating set to '**'",1000);
	ScreenUpdate();
	}

function setRating3()
	{
	url = player.getUrlAtPos();
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=3 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg("Rating set to '***'",1000);
	ScreenUpdate()
	}

function setRating4()
	{
	url = player.getUrlAtPos();
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=4 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg("Rating set to '****'",1000);
	ScreenUpdate();
	}

function setRating5()
	{
	url = player.getUrlAtPos();
	var db = new Database();
	var quoteExpr = new RegExp("'", "g");
	db.openQuery("update tracks set rating=5 where url ='"+url.replace(quoteExpr,"''")+"';");
	db.closeQuery();
	program.refreshWindows();
	program.setDisplayMsg("Rating set to '*****'",1000);
	ScreenUpdate();
	}

function update()
{
 
 if (player.queueLength >0)      
  {      
  var length = 0     
  for (i=0; i < player.queueLength; i++) 
       {
       length += parseInt(player.getDurationAtPos(i));
       }
  obj = new Date(length); 
  std = "" + obj.getHours()-1;
  min = "0" + obj.getMinutes();
  sec = "0" + obj.getSeconds();
  dauer = "" +std + ":" + min.substr(-2,2) + ":" + sec.substr(-2,2);
  program.setSkinText("playlistlength",dauer);        
 
  length = parseInt(player.getDurationAtPos()) - parseInt(player.time);   
  for (i=player.queuePos +1 ; i < player.queueLength; i++) 
       {
       length += parseInt(player.getDurationAtPos(i));
       }


  obj = new Date(length);
  std = "" + obj.getHours()-1;
  min = "0" + obj.getMinutes();
  sec = "0" + obj.getSeconds();
  dauer = "" +std + ":" + min.substr(-2,2) + ":" + sec.substr(-2,2);
  program.setSkinText("playlistremainlength",dauer);    
  program.setSkinText("playlisttotalnumber",player.queueLength);
  program.setSkinText("playlistremainnumber",player.queueLength-player.queuePos);
  } 
}
program.setTimeout(update,1000,true);

