// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// ************************************************************

// ***************** settings ***************************

var VERSION = "Eagle Black Touch Reloaded 15";
var URL_SUPPORT = "http://www.silverjuke.net/forum/topic-4040.html";
var CONFIGNAME = "eagleblacktouch";

var IMG_COVERFRAME = "coverframe.png";
var IMG_TRACKFRAME = "trackframe.png";
var DEFAULTCOVER = "defaultcover.jpg";
var FRAME_BORDERWIDTH = 2;

var COLOR_LIGHT = 0x000000;
var COLOR_MIDDLE = 0x000000;
var COLOR_DARK = 0x000000;
var DEFAULTFONTCOLOR = 0x666666;
var TITLEFONTCOLOR = 0xEB8921;
var ARTISTFONTCOLOR = 0xCCCCCC;
var ALBUMFONTCOLOR = 0xFFFFFF;
var TIMEFONTCOLOR = 0x00FF00;
var RATINGFONTCOLOR = 0xFFDF00;
var GENREFONTCOLOR = 0x778899;

var TICKMS = 1000;
var LAYOUT_PREFIX = "etv3_";

//***************** configurable settings ******************

var config_version = "unknown";
var config_queuealbum = 0;
var config_confirm = 1;
var config_searchall = 0;
var config_autosearch = 1;
var config_karaoke = 0;
var config_karaoke_selection = '';
var config_cacheload = 0;
var config_idletime = 0;
var config_restricted = 0;
var config_year = 1;
var config_volume = "No preset";
var config_fontface = program.iniRead('main/fontFace', "Arial");
var config_trackcount = "0";
var queue_counter = 0;
var max_message_display_time = 10;
var config_genre = 0;
var config_rating = 0;
var config_time = 1;
var config_radio = 0;

// configurable from inside silverjuke

function IniPreferredCoverTracks() { 
	return program.iniRead("main/skinFlags", 0); 
}

function IniMaxTracksInQueue() { 
	var IniMaxTracksInQueue = Number(program.iniRead('kiosk/maxTracksInQueue', 0));
	if (config_restricted || program.kioskMode) {
		return IniMaxTracksInQueue;
	} else {
		return 0;
	}
}

function IniVistime() { 
	return (program.iniRead("autoctrl/flags", 0) & 0x100000) ? Number(program.iniRead('autoctrl/startvis', 0)) : 0; 
	// 2^20
}

function IniLimitTracks() { 
	return (program.iniRead("kiosk/kioskf", 0) & 0x40000) ? 1 : 0; 
	// 2^18
}

function IniAvoidDoubleTracks() { 
	return (program.iniRead('kiosk/kioskf', 0) & 0x1000000) ? 1 : 0; 
	// 2^24
}

function IniAllowSearch() {
	if ((program.iniRead('kiosk/opf', 0) & 16) == 16) {
		// 2^4
		return 1;
	} else {
		return 0;
	}
}

function IniAllowTime() {
	if ((program.iniRead('kiosk/opf', 0) & 524288) == 524288) {
		// 2^19
		return 1;
	} else {
		return 0;
	}
}

function IniLimitTracksId() { 
	return program.iniRead("kiosk/limitToAdvSearch", -1); 
}

function IniManualTracksOverrideAutoplay() {
	return (program.iniRead("autoctrl/flags", 0) & 0x8000000) ? 1 : 0; 
	// 2^27
}

function IniAllowPause() { 
	if (rights.pause == true) {
		return 1;
	} else {
		return 0;
	}
	//return (program.iniRead('kiosk/opf', 0) & Math.pow(2, 2)) ? 1 : 0; 
	// 2^2
}

function IniAllowVolume() { 
	return (program.iniRead('kiosk/opf', 0) & Math.pow(2, 1)) ? 1 : 0; 
	// 2^1
}

function IniAllowEditQueue() { 
	return (program.iniRead('kiosk/opf', 0) & Math.pow(2, 3)) ? 1 : 0; 
	// 2^3
}

function IniAllowVideo() { 
	return (program.iniRead('kiosk/opf', 0) & Math.pow(2, 5)) ? 1 : 0; 
	// 2^5
}

function IniAllowRemoveFromQueue() { 
	return (program.iniRead('kiosk/opf', 0) & Math.pow(2, 16)) ? 1 : 0; 
	// 2^16
}

function IniRandomPlay() { 
	return (program.iniRead('kiosk/kioskf', 0) & Math.pow(2, 19)) ? 1 : 0; 
	// 2^19
}

function IniKeyboard() { 
	return program.iniRead('virtkeybd/layout', "memory:en.sjk,0");
}

//***************** globals *********************************

var db;

var quotematch = new RegExp("'", "g");

var mode = 0;
var MODE_COVERS    = 1;
var MODE_TRACKS    = 2;
var MODE_SEARCH    = 3;
var MODE_MESSAGE   = 4;
var MODE_CONFIRM   = 5;
var MODE_CACHELOAD = 6;
var MODE_RADIO     = 7;
var MODE_QUEUE     = 8;

var onclick_eventid;
var onkey_charcode;

var filter_expr;
var filter_words;
var filter_trackcount;
var filter_albumcount;

var selected_albumid = -1;
var selected_trackurl = "";

var limit_karaoke = false;
var limit_expr;

var lastwarning = 0;
var vismode = false;

var layout_confirm;

var eagletools_ok = false;

var last_queuelength = 0;



//****************** startup *********************************

program.onLoad = OnLoad;
program.onUnload = OnUnload;

//***************** functions ********************************

function OnLoad()
{
	if (program.layout.indexOf(LAYOUT_PREFIX) != 0)
    {
        alert("This skin will only initialize correctly if Silverjuke is restarted.");
        return;
    }

	TranslateInit();
	
    //Dialog.show('console');

    player.micVolume = 0;
    program.musicSel = "";
    program.search = "";

    ET_Init();
    eagletools_ok = true;

    ET_CoverArtInit();
    ET_KeyboardInit();
	if (program.iniRead("main/language") == 'de') {
		URL_SUPPORT = "http://www.silverjuke.net/forum/topic-4039.html";
	}

    VerifySettings();

    ConfigRead();

    db = new Database();

    SetLimit();
    Filter("");

    program.addSkinsButton(VERSION + " " + t('configuration'), Config);
    program.addMenuEntry(t('layout_configuration'), LocalConfig);

    program.exportFunction(OnSize);
    ET_SetSizeCallback("OnSize");

    program.exportFunction(OnClick);
    ET_SetClickCallback("OnClick");

    program.exportFunction(OnKey);
    ET_SetKeyCallback("OnKey");

    if (config_version != VERSION)
    {
        alert(t('configuration_version_warning_1') + "\n\n'" + config_version + "'\n\n" + t('configuration_version_warning_2'));
        Config();
    }

    player.onTrackChange = OnTrackChange;
    program.onKioskStarted = OnKioskStartEnd;
    program.onKioskEnded = OnKioskStartEnd;
	
	// Translate credits string
	program.setSkinText("credit_label", t('credits'));
	

    if (config_cacheload != 0)
    {
        CacheLoadMode();
    }
    else
    {
        CoversMode();
    }
	// Garbage collection webradio
	program.iniWrite(CONFIGNAME + "/radio_id", '');
}


function OnUnload()
{
    if (eagletools_ok)
    {
        ET_DrawDeleteAll();
        ET_SetSizeCallback("");
        ET_SetClickCallback("");
        ET_SetKeyCallback("");

        player.onTrackChange = undefined;
        program.onKioskStarted = undefined;
        program.onKioskEnded = undefined;
    }
	// Garbage collection webradio
	program.iniWrite(CONFIGNAME + "/radio_id", '');
}


function OnKioskStartEnd()
{
    SetLimit();
    Filter("");
    CoversMode();
}


function OnSize()
{
    // delay 10 ms: only process after resizing is all done
    program.setTimeout(Redraw, 10, false);
}


function Redraw()
{
    ET_DrawDeleteAll();

    program.refreshWindows(3);

    switch (mode)
    {
    case MODE_COVERS: CoversDraw(); break;
    case MODE_TRACKS: TracksDraw(); break;
    case MODE_SEARCH: SearchDraw(); break;
    case MODE_MESSAGE: MessageDraw(); break;
    case MODE_CONFIRM: ConfirmDraw(); break;
    case MODE_CACHELOAD: CacheLoadDraw(); break;
	case MODE_RADIO: RadioDraw(); break;
	case MODE_QUEUE: QueueDraw(); break;
    }
}


function LocalConfig()
{
    switch (mode)
    {
    case MODE_COVERS: CoversConfig(); break;
    case MODE_TRACKS: TracksConfig(); break;
    case MODE_SEARCH: SearchConfig(); break;
	case MODE_RADIO: RadioConfig(); break;
    default: alert(t('screen_has_no_config_options')); break;
    }
}

function OnClick(eventid, onoff)
{
    if (onoff)
    {
        // queue event to process from script, not from DLL (easier debugging)
        onclick_eventid = eventid;
        program.setTimeout(ProcessOnClick, 1, false);
    }
}


function ProcessOnClick()
{
    program.lastUserInput = 0;

    switch (mode)
    {
    case MODE_COVERS: CoversClick(onclick_eventid); break;
    case MODE_TRACKS: TracksClick(onclick_eventid); break;
    case MODE_SEARCH: SearchClick(onclick_eventid); break;
    case MODE_MESSAGE: MessageClick(onclick_eventid); break;
    case MODE_CONFIRM: ConfirmClick(onclick_eventid); break;
	case MODE_RADIO: RadioClick(onclick_eventid); break;
	case MODE_QUEUE: QueueClick(onclick_eventid); break;
    }
}


function OnKey(charcode)
{
    // queue event to process from script, not from DLL (easier debugging)
    onkey_charcode = charcode;
    program.setTimeout(ProcessOnKey, 1, false);
}


function ProcessOnKey()
{
    program.lastUserInput = 0;

    switch (mode)
    {
    case MODE_COVERS: CoversKey(onkey_charcode); break;
    case MODE_SEARCH: SearchKey(onkey_charcode); break;
    }
}


// report SJ stuff that is incompatible with this skin
function VerifySettings()
{
    var msg = "";

    if (program.version < 0x02730002) {
		msg += "- " + t('program_version_warning') + "\n";
	}

    if (msg != "") {
		alert(t('settings_incorrect') + "\n\n" + msg);
	}
}


function OnTrackChange()
{
    last_queuelength = player.queueLength;

    if (mode == MODE_COVERS) {
        CoversDraw();
    }
	
	if (mode == MODE_RADIO) {
        RadioDraw();
    }
}


// periodic timer is used as a one-shot as it is needed for all sorts of other purposes as well
function SetTick()
{
    program.setTimeout(Tick, TICKMS, false);
}


// should be called every TICKMS
function Tick()
{
    // bug workaround: onUnload is not called when skin is changed by user, this test makes sure we quit processing
    if (program.layout && (program.layout.substr(0, LAYOUT_PREFIX.length) == LAYOUT_PREFIX))
    {
        if (player.queueLength != last_queuelength) OnTrackChange();
		if (IniAllowTime() != 0 && (program.layout.substr(LAYOUT_PREFIX.length, 5) == 'cover' || program.layout.substr(LAYOUT_PREFIX.length, 5) == 'queue') && 1==2 ) {
			program.setSkinText("player_remaining_time", "-" + MsToTime(player.duration-player.time));
			program.setSkinText("player_played_time", MsToTime(player.time));
			program.setSkinText("player_total_time", MsToTime(player.duration));
			program.setSkinText("player_time_separator_1", '+');
			program.setSkinText("player_time_separator_2", '=');
			//TimeUpdate();
		}

        SetTick();
		queue_counter++;
		if ((program.layout.substr(LAYOUT_PREFIX.length, 5) == 'cover' || program.layout.substr(LAYOUT_PREFIX.length, 5) == 'radio') && queue_counter >= max_message_display_time) {
			queue_counter = 0;
			program.setSkinText("queue_message", " ");
		} 

        if (program.layout == LAYOUT_PREFIX + "message") {
            if (rights.credits > message_credits) {
                // credits were added, retry queueing
                Queue();
            }
        }

        if (config_idletime && (program.lastUserInput > (config_idletime * 1000)) && (program.layout.indexOf(LAYOUT_PREFIX + "covers") != 0) && (program.layout.indexOf(LAYOUT_PREFIX + "radio") != 0)) {
            Filter("");
            CoversMode();
        }


        if (mode == MODE_SEARCH) {
             if (search_pending > 0) SearchTick();
        }
		
		if (mode == MODE_QUEUE) {
            player.onTrackChange = QueueDraw();
			if (player.isStopped() == true || player.queueLength < 2) {
				QueueExit();
			}
        }

        var vistime = IniVistime() * 60;

        if (vistime && !vismode && (program.lastUserInput > (vistime * 1000)) && !program.visMode) {
            VisMode(true);
        }

        if (vismode && !program.visMode) {
            // fix: SJ does not consider a click on the visual a 'userinput'
            // so without this failsafe the vismode keeps on kicking in
            VisMode(false);
        }
    }
    else
    {
        // they quit this skin, clean up
    }
}


function VisMode(onoff)
{
    if (onoff)
    {
        program.visMode = true;
        vismode = true;
    }
    else
    {
        program.lastUserInput = 0;
        vismode = false;
    }
}


function LimitKaraoke(onoff)
{
    limit_karaoke = onoff;
    SetLimit();
    Filter("");
    CoversMode();
}


function SetLimit()
{
    // set searching to respect kiosk music selection limitation if any
    var limit_expr_kiosk = "1";
    var limit_expr_karaoke = "1";

    if (config_restricted || program.kioskmode)
    {
        if (IniLimitTracks())
        {
            var id = IniLimitTracksId();
            if (id >= 0) limit_expr_kiosk = ET_MusicSearchGet(db, id);
        }
		if (config_volume > 0) {
			player.volume = Math.round((100-(config_volume-1)*10)*(255/100));
		}
    }

    if (config_karaoke!='')
    {
		var musicsel = "";
		db.openQuery("SELECT name, id " +
					 "FROM advsearch " +
					 "WHERE name ='" + config_karaoke_selection + "'");
		//alert("config_karaoke=" + config_karaoke + "|query_result=" + db.getField(0));
		if( db.nextRecord() ) {
			if( limit_karaoke) {
				var id = db.getField(1);
			} else {
				var id = ET_MusicSearchId(db, musicsel);
			}
		}
		db.closeQuery();

        if (id >= 0) {
            limit_expr_karaoke = ET_MusicSearchGet(db, id);
        }
    }

    limit_expr = "(" + limit_expr_kiosk + ") and (" + limit_expr_karaoke + ")";
	//alert("limit_karaoke=" + limit_karaoke + "\nconfig_karaoke=" + config_karaoke + "\nmusicsel=" + musicsel + "\nid=" + id + "\nlimit_expr=" + limit_expr);
}

// read our stored configuration
function ConfigRead()
{
    config_version = program.iniRead(CONFIGNAME + "/version", config_version);
    config_confirm = Number(program.iniRead(CONFIGNAME + "/confirm", config_confirm));
    config_queuealbum = Number(program.iniRead(CONFIGNAME + "/queuealbum", config_queuealbum));
    config_searchall = Number(program.iniRead(CONFIGNAME + "/searchall", config_searchall));
    config_autosearch = Number(program.iniRead(CONFIGNAME + "/autosearch", config_autosearch));
    config_idletime = Number(program.iniRead(CONFIGNAME + "/idletime", config_idletime));
    config_restricted = Number(program.iniRead(CONFIGNAME + "/restricted", config_restricted));
	config_karaoke_selection = program.iniRead(CONFIGNAME + "/karaoke_selection", config_karaoke_selection);
	config_karaoke = Number(program.iniRead(CONFIGNAME + "/karaoke", config_karaoke));
    config_cacheload = Number(program.iniRead(CONFIGNAME + "/cacheload", config_cacheload));
	config_year = Number(program.iniRead(CONFIGNAME + "/year", config_year));
	config_volume = program.iniRead(CONFIGNAME + "/volume", config_volume);
	config_trackcount =  program.iniRead(CONFIGNAME + "/trackcount", config_trackcount);
	config_rating =  program.iniRead(CONFIGNAME + "/rating", config_rating);
	config_genre =  program.iniRead(CONFIGNAME + "/genre", config_genre);
	config_radio =  program.iniRead(CONFIGNAME + "/radio", config_radio);
	if (File.exists("mplayer.exe") != true) {
		config_radio = 0;
	}
}


// edit our configuration, store & apply changes
function Config()
{
    var orgmode = mode;
    mode = 0;

    var dlg = new Dialog();

    dlg.addCheckCtrl("confirm", t('ask_confirmation_before_queing_or_playing'), config_confirm);
	dlg.addSelectCtrl("trackcount", t('album_track_counter_display'), config_trackcount, t('never'), t('depending_on_confirmation_level'), t('always'));
    dlg.addCheckCtrl("queuealbum", t('allow_queing_of_complete_albums'), config_queuealbum);
    dlg.addCheckCtrl("searchall", t('allow_search_beyond_kiosk_music_selection'), config_searchall);
    dlg.addCheckCtrl("autosearch", t('search_after_each_character'), config_autosearch, t('no_wait_for_enter_key'), t('yes'));
    dlg.addTextCtrl("idletime", t('idle_time'), config_idletime);
    
	trackArray = new Array();
	trackArray.push('--' + t('none') + '--');
	var karaoke_setting = 0;
	db.openQuery("SELECT name, id " +
	             "FROM advsearch " +
				 "ORDER BY id");
    
	while (db.nextRecord()) {
		trackArray.push(db.getField(0));
		if (db.getField(0)==config_karaoke_selection) {
			var karaoke_setting=db.getField(1);
		}
	}
	db.closeQuery();
	
	if (trackArray.length == 1) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0]);
	}
	if (trackArray.length == 2) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1]);
	}
	if (trackArray.length == 3) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2]);
	}
	if (trackArray.length == 4) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3]);
	}
	if (trackArray.length == 5) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4]);
	}
	if (trackArray.length == 6) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5]);
	}
	if (trackArray.length == 7) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6]);
	}
	if (trackArray.length == 8) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7]);
	}
	if (trackArray.length == 9) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8]);
	}
	if (trackArray.length == 10) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9]);
	}
	if (trackArray.length == 11) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10]);
	}
	if (trackArray.length == 12) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11]);
	}
	if (trackArray.length == 13) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12]);
	}
	if (trackArray.length == 14) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13]);
	}
	if (trackArray.length == 15) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14]);
	}
	if (trackArray.length == 16) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14], trackArray[15]);
	}
	if (trackArray.length == 17) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14], trackArray[15], trackArray[16]);
	}
	if (trackArray.length == 18) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14], trackArray[15], trackArray[16], trackArray[17]);
	}
	if (trackArray.length == 19) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14], trackArray[15], trackArray[16], trackArray[17], trackArray[18]);
	}
	if (trackArray.length == 20) {
		dlg.addSelectCtrl("karaoke", t('karaoke_music_selection'), karaoke_setting, trackArray[0], trackArray[1], trackArray[2], trackArray[3], trackArray[4],
trackArray[5], trackArray[6], trackArray[7], trackArray[8], trackArray[9], trackArray[10], trackArray[11], trackArray[12], trackArray[13], trackArray[14], trackArray[15], trackArray[16], trackArray[17], trackArray[18], trackArray[19]);
	}
	
    dlg.addCheckCtrl("restricted", t('apply_kiosk_restrictions_in_window_mode'), config_restricted);
    dlg.addCheckCtrl("cacheload", t('cache_album_art_on_startup'), config_cacheload);
	dlg.addSelectCtrl("volume", t('volume_preset'), config_volume, t('no_preset'), "100 %", " 90 %", " 80 %", " 70%", " 60 %", " 50 %", " 40 %", " 30 %", " 20 %", " 10 %", "  0 %");
	dlg.addCheckCtrl("year", t('display_year'), config_year);
	dlg.addCheckCtrl("rating", t('display_rating'), config_rating);
	dlg.addCheckCtrl("genre", t('display_genre'), config_genre);
	if (File.exists("mplayer.exe") == true) {
		dlg.addCheckCtrl("radio", t('enable_webradio'), config_radio);
	} else {
		if (program.iniRead("main/language") == 'de') {
			dlg.addStaticText(t('webradio_cant_be_enabled'));
			dlg.addButton("webradio_announcement", t('webradio_announcement_thread'), function() { program.launchBrowser('http://www.silverjuke.net/forum/post.php?p=16067&highlight=#16067'); });
		} else {
			dlg.addStaticText(t('webradio_cant_be_enabled'));
			dlg.addButton("webradio_announcement", t('webradio_announcement_thread'), function() { program.launchBrowser('http://www.silverjuke.net/forum/post.php?p=16066&highlight=#16066'); });
		}
	}
	
	dlg.addStaticText("_____________________________________________________________________________________");
	//dlg.addStaticText(program.iniRead('kiosk/opf', 0));
    dlg.addStaticText(t('relevant_silverjuke_settings'));
	dlg.addStaticText(t('settings') + ' -> ' + t('playback_queue'));
	if ((program.iniRead('kiosk/kioskf', 0) & 0x00000009) == 9) {
		dlg.addCheckCtrl("max_tracks_in_queue_enable", t('limit_max_tracks_in_queue') , 9);
		// 2^0 + 2^3
	} else {
		dlg.addCheckCtrl("max_tracks_in_queue_enable", t('limit_max_tracks_in_queue') , 0);
	}
	dlg.addTextCtrl("max_tracks_in_queue_number", t('max_tracks_in_queue') , program.iniRead('kiosk/maxTracksInQueue', 0));
	dlg.addCheckCtrl("avoid_double_tracks_in_queue", t('avoid_double_tracks_in_queue'), IniAvoidDoubleTracks());
	dlg.addStaticText("\n" + t('settings') + ' -> ' + t('playback_automatic_control_additional_options'));
	dlg.addTextCtrl("idle_time_before_visualization", t('idle_time_before_visualization') , IniVistime());
	dlg.addStaticText("\n" + t('settings') + ' -> ' + t('kiosk_mode_functionality'));
	dlg.addCheckCtrl("allow_search_in_kiosk_mode", t('search'), IniAllowSearch());
	dlg.addCheckCtrl("toggle_time_display", t('toggle_time_display'), IniAllowTime());
	dlg.addCheckCtrl("allow_pausing", t('pause'), IniAllowPause());
	dlg.addCheckCtrl("allow_volume", t('volume'), IniAllowVolume());
	dlg.addCheckCtrl("allow_edit_queue", t('edit_queue'), IniAllowEditQueue());
	dlg.addCheckCtrl("allow_remove_queue", t('remove_tracks_from_queue'), IniAllowRemoveFromQueue());
	if (IniLimitTracks()) { 
		var track_limitation_info = ET_MusicSearchName(db, IniLimitTracksId()); 
	} else {
		var track_limitation_info = "(" + t('none') + ")";
	}
	
	dlg.addStaticText(t('tracks_limited_to_music_selection') + " " + track_limitation_info);
	
    if (dlg.showModal() == "ok")
    {
        program.iniWrite(CONFIGNAME + "/version", VERSION);
        program.iniWrite(CONFIGNAME + "/searchall", dlg.getValue("searchall"));
        program.iniWrite(CONFIGNAME + "/autosearch", dlg.getValue("autosearch"));
        program.iniWrite(CONFIGNAME + "/confirm", dlg.getValue("confirm"));
        program.iniWrite(CONFIGNAME + "/queuealbum", dlg.getValue("queuealbum"));
        program.iniWrite(CONFIGNAME + "/idletime", dlg.getValue("idletime"));
		program.iniWrite(CONFIGNAME + "/karaoke_selection", trackArray[dlg.getValue("karaoke")]);
        program.iniWrite(CONFIGNAME + "/karaoke", dlg.getValue("karaoke"));
        program.iniWrite(CONFIGNAME + "/restricted", dlg.getValue("restricted"));
        program.iniWrite(CONFIGNAME + "/cacheload", dlg.getValue("cacheload"));
		program.iniWrite(CONFIGNAME + "/year", dlg.getValue("year"));
		program.iniWrite(CONFIGNAME + "/volume", dlg.getValue("volume"));
		program.iniWrite(CONFIGNAME + "/trackcount", dlg.getValue("trackcount"));
		program.iniWrite(CONFIGNAME + "/rating", dlg.getValue("rating"));
		program.iniWrite(CONFIGNAME + "/genre", dlg.getValue("genre"));
		program.iniWrite(CONFIGNAME + "/radio", dlg.getValue("radio"));

		program.iniWrite("kiosk/maxTracksInQueue", dlg.getValue("max_tracks_in_queue_number"));
		
		var config_section = 'kiosk/kioskf';
		
		var config_option_label = 'avoid_double_tracks_in_queue';
		var power = 24;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'max_tracks_in_queue_enable';
		var power = 3;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_section = 'kiosk/opf';
		
		var config_option_label = 'allow_search_in_kiosk_mode';
		var power = 4;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'toggle_time_display';
		var power = 19;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'allow_pausing';
		var power = 2;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'allow_volume';
		var power = 1;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'allow_edit_queue';
		var power = 3;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_option_label = 'allow_remove_queue';
		var power = 16;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}
		
		var config_section = 'autoctrl/flags';
		
		var config_option_label = 'idle_time_before_visualization';
		var power = 20;
		var current_config_value = program.iniRead(config_section, 0);
		if ((dlg.getValue(config_option_label) != 0) && (current_config_value  & Math.pow(2, power)) == 0) {
			program.iniWrite(config_section, current_config_value + Math.pow(2, power));
		} else {
			if ((dlg.getValue(config_option_label) == 0) && (current_config_value  & Math.pow(2, power)) != 0) {
				program.iniWrite(config_section, current_config_value - Math.pow(2, power));
			}
		}

        ConfigRead();
    };

    mode = orgmode;

    if (mode = MODE_COVERS) CoversMode(); // changed config can cause big changes
}

function AboutSkin()
{
    var dlg = new Dialog();

    dlg.addStaticText(VERSION + "\n");
	dlg.addStaticText(t('black_touch_fork') + "\n");
    dlg.addStaticText("\n" + t('eagle_library_explanation'))
    dlg.addButton("support", t('black_touchsupport'), function() { program.launchBrowser(URL_SUPPORT); });
    dlg.addStaticText(t('black_touchcopyrights') + "\n\n" +
                      t('silverjuke_copyrights'));
	dlg.addButton('ok',  t('ok'));


   dlg.show();
}

function StartKiosk() {
	program.kioskMode = true;
}

//************************************************************

// set up our global searchexpression & counts based on the given searchstring and the global limit_expr
function Filter(search, filtermode)
{
    if (search == "")
    {
        filter_expr = limit_expr;
    }
    else
    {
        var wordmatch = new RegExp("[^ ]+", "g");
        filter_words = search.match(wordmatch);
        ET_HilitePhrases(filter_words);
        filter_expr = "1";

        var i;
        for (i = 0; i < filter_words.length; ++i)
        {
            var filterword_expr = "0";
            var search = filter_words[i].replace(quotematch,"''");

            if ((filtermode == 0) || (filtermode == 1))
            {
                filterword_expr += " or tracks.leadartistname like '%" + search + "%'";
            }

            if ((filtermode == 0) || (filtermode == 2))
            {
                filterword_expr += " or tracks.albumname like '%" + search + "%'";
            }

            if ((filtermode == 0) || (filtermode == 3))
            {
                filterword_expr += " or tracks.trackname like '%" + search + "%'";
            }

            filter_expr += " and (" + filterword_expr + ")";
        }

        filter_expr = "(" + filter_expr + ")";

        if (config_searchall == 0)
        {
            filter_expr = "(" + limit_expr + " and " + filter_expr + ")";
        }
    }

    db.openQuery("SELECT COUNT(distinct albums.id), COUNT(tracks.id) " +
	             "FROM albums, tracks " +
                 "WHERE " + filter_expr + " " +
				 "AND albums.id == tracks.albumid " +
				 "ORDER BY albums.id");
    filter_albumcount = Number(db.getField(0));
    filter_trackcount = Number(db.getField(1));
    db.closeQuery();

    search_albumoffset = 0;
}

//************************************************************

function Queue()
{
    if (selected_trackurl == undefined)
    {
        AlbumQueue();
    }
    else
    {
        TrackQueue();
    }
}


function QueueTest(trackcount)
{
    var queuelimit = IniMaxTracksInQueue();

    if ((queuelimit > 1) && ((program.iniRead('kiosk/kioskf', 0) & 0x00000009) == 9) && ((player.queueLength - player.queuePos + trackcount - 1) >= queuelimit))
    {
		MessageMode(t('cannot_queue_x', ((trackcount == 1) ? t('track') : t('album'))),
                    t('queue_size_limited_to_x', queuelimit));
        return false;
    }

    return true;
}


function TrackQueue()
{
    if (config_restricted || program.kioskMode)
    {
        if (!QueueTest(1)) return;

        if (IniAvoidDoubleTracks())
        {
            var pos;
            for (pos = player.queuePos; pos < player.queueLength; ++pos)
            {
                if (player.getUrlAtPos(pos) == selected_trackurl)
                {
                    MessageMode(t('cannot_queue_x', t('track')), t('already_in_queue'));
                    return;
                }
            }
        }

        if (rights.useCredits && (rights.credits < 1))
        {
            MessageMode(t('cannot_queue_x', t('track')), t('no_more_credits'));
            return;
        }

    }

    if (config_confirm != 0)
    {
        ConfirmMode();
    }
    else
    {
        QueueOk();
        CoversMode();
    }
}


function AlbumQueue()
{
    if (config_queuealbum == 0) return; // not allowed

    if (config_restricted || program.kioskMode)
    {
        if (!QueueTest(tracks_albumsize)) return;

        if (IniAvoidDoubleTracks())
        {
            db.openQuery("SELECT url " +
			             "FROM tracks " +
						 "WHERE albumid = " + selected_albumid + " " +
						 "ORDER BY tracknr");

            while (db.nextRecord())
            {
                var pos;
                var url = db.getField(0);

                for (pos = player.queuePos; pos < player.queueLength; ++pos)
                {
                    if (player.getUrlAtPos(pos) == url)
                    {
                        MessageMode(t('cannot_queue_x', t('album')), t('track_already_in_queue'));
                        return;
                    }
                }
            }
        }

        if (rights.useCredits && (rights.credits < tracks_albumsize))
        {
            MessageMode(t('cannot_queue_x', t('album')), t('no_more_credits'));
            return;
        }
    }

    selected_trackurl = "";

    ConfirmMode();
}


// add the selected track or album to the queue, start playing if needed
function QueueOk()
{
    var orgqueuelength = player.queueLength;

    if (IniMaxTracksInQueue() == 1)
    {
        // shopmode
        player.removeAll();
    }

    if (selected_trackurl == "")
    {
        // complete album
        db.openQuery("SELECT url " +
		             "FROM tracks " +
					 "WHERE albumid = " + selected_albumid + " " +
					 "ORDER BY tracknr");

        while (db.nextRecord())
        {
            if (config_restricted || program.kioskMode) {
                if (rights.useCredits) --rights.credits;
            }

            player.addAtPos(-1, db.getField(0));
			if (program.iniRead(CONFIGNAME + "/radio_id", '') != '') {
				program.iniWrite(CONFIGNAME + "/radio_id", '');
				program.run('taskkill /im mplayer.exe');
			}
			program.iniWrite(CONFIGNAME + "/radio_id", '');
        }
    }
    else
    {
        // single track
        if (config_restricted || program.kioskMode)
        {
            if (rights.useCredits) --rights.credits;
        }

        player.addAtPos(-1, selected_trackurl);
		if (program.iniRead(CONFIGNAME + "/radio_id", '') != '') {
			program.iniWrite(CONFIGNAME + "/radio_id", '');
			program.run('taskkill /im mplayer.exe');
		}
		
    }

    program.selectAll(false);

    // when silent or interrupting autoplay move the queuepos to the first added song
    if (!player.isPlaying() || (IniManualTracksOverrideAutoplay() && player.getAutoplayAtPos()))
    {
        player.queuePos = orgqueuelength;
        player.play();
    }
}


//************************************************************

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

        if (++pos == 2) disptime = ":" + disptime;
    }

    switch (pos) {
		case 0: disptime = "0:00" + disptime; break;
		case 1: disptime = "0:0"  + disptime; break;
		case 2: disptime = "0"    + disptime; break;
    }

    return disptime;
}

//************************************************************

// draw an album cover in a frame, return true if created from file (slow)
function DrawCover(albumid, trackurl, x, y, size, transparency, cache, border)
{
    if (cache == undefined) cache = true;
    if (border == undefined) border = true;
    if (IniPreferredCoverTracks() == 0) trackurl = undefined;

    var coversize = border ? (size - FRAME_BORDERWIDTH * 2) : size;
    var slowfile = false;
    var filename;

    if (trackurl == undefined)
    {
        filename = ET_CoverCache(albumid, coversize);
    }

    if (filename == undefined)
    {
        filename = ET_CoverArt(albumid, trackurl, coversize, cache);
        slowfile = true;
    }

    if (border)
    {
        ET_AddImage(filename, x + FRAME_BORDERWIDTH, y + FRAME_BORDERWIDTH, coversize, coversize, 0, transparency);
        ET_AddImage(IMG_COVERFRAME, x, y, size, size, ET_REPEAT_GRID, 0);
    }
    else
    {
        ET_AddImage(filename, x, y, size, size, 0, transparency);
    }
	// Debugging settings. Turn on to see details:
	//ET_SetFont(0xFFFFFF, config_fontface, 16);
	//ET_AddText(filename.substr(58) + "|" + albumid + "|" + trackurl, x, y, 400, DT_END_ELLIPSIS);
	//ET_SetFont(0x000000, config_fontface, 16);
	//ET_AddText(filename.substr(58) + "|" + albumid + "|" + trackurl, x+1, y+1, 400, DT_END_ELLIPSIS);
	
	//ET_SetFont(0xFFFFFF, config_fontface, 12);
	//ET_AddTextArea(filename.substr(58) + " " + albumid, x, y, coversize, coversize, DT_WORDBREAK);

    return slowfile;
}


// format albumname & year for display
function AlbumYear(albumname, year)
{
    if (albumname == "")
    {
        if (year > 0) return "" + year;
        return "";
    }

    if (year == 0) return albumname;

    return albumname + " (" + year + ")";
}

//************************************************************
