// ************************************************************
//
// EagleBlackTouchReloaded Silverjuke skin
// (c) SilverEagle
//
// Message layout
//
// ************************************************************

// ***************** settings ***************************

//var MESSAGE_FONTCOLOR = 0x000979;
var MESSAGE_FONTCOLOR = DEFAULTFONTCOLOR;
var MESSAGE_FONTSIZE = 30;

//***************** globals *********************************

var message_area_x;
var message_area_y;
var message_area_w = 740;
var message_area_h = 500;

var message_y;

var message_line1;
var message_line2;

var message_prevmode;
var message_credits;

//***************** functions ********************************


function MessageCalculate()
{
    message_area_x = Math.floor((ET_GetWindowWidth() - message_area_w) / 2);
    message_area_y = Math.floor((ET_GetWindowHeight() - message_area_h) / 2);

    //message_y = Math.floor((message_area_h - 2 * MESSAGE_FONTSIZE) / 2);
	message_y = 0;
}


// switch layout to message display
function MessageMode(line1, line2)
{
    message_prevmode = mode;
    mode = MODE_MESSAGE;

    ET_DrawDeleteAll();

    if (line1 == undefined) line1 = "";
    if (line2 == undefined) line2 = "";

    message_line1 = line1;
    message_line2 = line2;
    message_credits = rights.credits;

    program.layout = LAYOUT_PREFIX + "message";

    // this avoids nasty flickering
    program.setTimeout(MessageDraw, 1, false);
}


function MessageDraw()
{
    ET_DrawDeleteAll();
    MessageCalculate();
    MessageBuild();
    ET_DrawAll();
    SetTick();
}


function MessageBuild()
{
    ET_NewArea(message_area_x, message_area_y, message_area_w, message_area_h, COLOR_LIGHT);

    var x = 0;
    var y = message_y;

    ET_SetFont(MESSAGE_FONTCOLOR, config_fontface, MESSAGE_FONTSIZE);
    ET_AddTextArea(message_line1 + "\n\n" + message_line2, x, y, message_area_w, message_area_h, DT_VCENTER | DT_CENTER | DT_END_ELLIPSIS | DT_WORDBREAK);

}


function MessageClick()
{
    MessageExit();
}


function MessageExit()
{
    switch (message_prevmode)
    {
    case MODE_COVERS: CoversMode(); break;
    case MODE_TRACKS: TracksMode(); break;
    case MODE_SEARCH: SearchMode(); break;
	case MODE_RADIO: RadioMode(); break;
    }
}

//************************************************************
