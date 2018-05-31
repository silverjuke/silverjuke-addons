// ***************** constants *******************************

// ***************** globals *********************************

// keyboard_def[]
//   keys[]
//     width
//     def[]
//       mode
//       command
//       display


var et_keyboard_def;
var et_keyboard_x;
var et_keyboard_y;
var et_keyboard_w;
var et_keyboard_h;
var et_keyboard_key_w;
var et_keyboard_key_h;
var et_keyboard_button;
var et_keyboard_buttonhi;
var et_keyboard_buttonclick;

var et_keyboard_mode;
var et_keyboard_modelock;
var et_keyboard_shift;
var et_keyboard_buffer = "";


//***************** functions ********************************

function ET_KeyboardInit()
{
    var language = program.iniRead("main/language");
	if (language == "") {
		language = "en";
		program.iniWrite("main/language", "en");
	}
    var layout = "memory:" + language + ".sjk,0"

    if (layout.indexOf("memory:") == 0) {
		var layout = layout.substr(7);
	}

    if (layout == "en_GB") {
		var layout = "en";
	}
	if (layout == "en_GB.sjk,0") {
		var layout = "en.sjk,0";
	}

    var kommapos = layout.lastIndexOf(",");
    var kbdef = layout.substr(0, kommapos);
    var layoutnr = layout.substr(kommapos + 1);

    if (!et_keyboard_parse(ET_Skinfile(kbdef), Number(layoutnr)))
    {
        var layout_string = "'" + kbdef + "' (" + t('number_abbreviation') + " " + layoutnr + ")";
		alert(t('cant_open_keyboard_layout', layout_string) + "\nlanguage:" + language + "|layout:" + layout + "|kbdef:" + kbdef + "|layoutnr:" + layoutnr + "|virtkeybd:" + virtkeybd);
    } else {
		//The current layout exists - let's determine if it needs writing back
		var virtkeybd = program.iniRead('virtkeybd/layout'); 
		if (virtkeybd == "" || virtkeybd != ("memory:" + layout)) {
			virtkeybd = "memory:" + layout;
			program.iniWrite("virtkeybd/layout", virtkeybd);
		}
		//alert("language:" + language + "|layout:" + layout + "|kbdef:" + kbdef + "|layoutnr:" + layoutnr + "|virtkeybd:" + virtkeybd); 
	}
}


function et_keyboard_parse(kbdef, layoutnr)
{
    var deffile = new File(kbdef, true);
    if (!deffile) return false;

    et_keyboard_def = new Array();
    var keyrow;
    var key;
    var enterkey;

    var ready = false;
    while ((deffile.pos < deffile.length) && !ready)
    {
        var tokens = deffile.read().match(/[^;]+/g);

        for (var i = 0; (i < tokens.length) && !ready; ++i)
        {
            var setting = tokens[i]
            var name = setting;
            var func = "";

            var equalpos = setting.indexOf("=");
            if (equalpos > 0)
            {
                name = setting.substr(0, equalpos);
                func = setting.substring(equalpos + 1);
                func = func.replace(/^ +/, "");
                func = func.replace(/ +$/, "");
            }

            name = name.replace(/^ +/, "");
            name = name.replace(/ +$/, "");

            if (name.length > 0)
            {
                if (et_keyboard_def.length == 0)
                {
                    if ((name == "layout") && (layoutnr-- == 0))
                    {
                        keyrow = new Array();
                        et_keyboard_def.push(keyrow);
                    }
                }
                else
                {
                    switch (name)
                    {
                    case "nextline":
                        keyrow = new Array();
                        et_keyboard_def.push(keyrow);
                        break;

                    case "spacer":
                        key = new Array(new Array(1, ""));
                        keyrow.push(key);
                        break;

                    }

                    if (func.length > 0)
                    {
                        switch (name)
                        {
                        case "layout":
                            ready = true;
                            break;

                        case "width":
                            key[0] = ((key[0] < 0) ? -1 : 1) * Number(func);
                            break;

                        case "key":
                            key = new Array();
                            key.push(1);
                            keyrow.push(key);
                            // fallthrough

                        default:
                            var display = func;
                            func = func.match(/\S+/g);
                            var modelock = ((func.length > 1) && (func[1] == "lock"));
print(func);
                            func = func[0];
                            var forced = display.match(/\".+\"/);
                            if (forced && (forced.length == 1)) display = forced[0].substring(1, forced[0].length - 1)
                            else if (display.substr(0, 2) == "0x") display = String.fromCharCode(display);
                            else if (display == "alt1") display = "AltGr"
                            else if (display == "backsp") display = tt.back;
                            else if (display == "clearall") display = tt.clear;
                            else if (display == "shift") display = tt.shift;
                            else if (display == "enter")
                            {
                                enterkey = key;
                                display = "org";
                            }
                            else if (display == "entercont")
                            {
                                key[0] = -key[0]; // signals double height

                                // copy enter key definitions
                                for (var k = 1; k < enterkey.length; ++k)
                                {
                                    var keydef = enterkey[k];
                                    key.push(new Array(keydef[0], "enter", tt.ok, false));
                                }

                                enterkey.length = 1; // turn original enterkey into spacer
                                break;
                            }

                            if (func != "nop")
                            {
                                // make modenaming orthogonal
                                if (name == "shift") name = "keyshift";

                                key.push(new Array(name, func, display, modelock));

                                if (func == "shift")
                                {
                                    if (name != "shift")
                                    {
                                        // add implied function to unshift
                                        key.push(new Array(name + "shift", func, display, modelock));
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    return et_keyboard_def.length > 0;
}


function ET_Keyboard(x, y, w, h, button, buttonhi, buttonclick)
{
    var totalwidth = 0;
    for (var i = 0; i < et_keyboard_def.length; ++i)
    {
        var keyrow = et_keyboard_def[i];
        var rowwidth = 0;

        for (var j = 0; j < keyrow.length; ++j) rowwidth += keyrow[j][0];

        if (rowwidth > totalwidth) totalwidth = rowwidth;
    }

    et_keyboard_x = x;
    et_keyboard_y = y;
    et_keyboard_w = w;
    et_keyboard_h = h;
    et_keyboard_key_w = Math.floor(w / totalwidth);
    et_keyboard_key_h = Math.floor(h / et_keyboard_def.length);
    et_keyboard_button = button;
    et_keyboard_buttonhi = buttonhi;
    et_keyboard_buttonclick = buttonclick;
}


function ET_KeyboardReset()
{
    et_keyboard_setmode("key", false, false);
    et_keyboard_buffer = "";
}


function ET_KeyboardSetBuffer(buffer)
{
    et_keyboard_buffer = buffer;
}


function ET_KeyboardGetBuffer()
{
    return et_keyboard_buffer;
}


// return: 0=ignore 1=bufferchange 2=enter, 3=redraw keyboard
function ET_KeyboardProcess(clicknr)
{
    var keydef = et_keyboard_func_clicked(clicknr);
    var func = keydef[1];
    var modelock = keydef[3];
    var reset = false;
    var retcode = 0;

    switch (func)
    {
    case "enter":
    case "entercont":
        retcode = 2;
        break;

    case "backsp":
        if (et_keyboard_buffer.length > 0)
        {
            et_keyboard_buffer = et_keyboard_buffer.substr(0, et_keyboard_buffer.length - 1);
            retcode = 1;
        }
        break;

    case "clearall":
        if (et_keyboard_buffer.length > 0)
        {
            et_keyboard_buffer = "";
            retcode = 1;
            reset = true;
        }
        break;

    case "shift":
        et_keyboard_setmode(et_keyboard_mode, !et_keyboard_shift);
        retcode = 3;
        break;

    default:
        if (func == undefined)
        {
            // undefined key
        }
        else if (func.length == 1)
        {
            et_keyboard_buffer += func;
            retcode = 1;
            reset = true;

        }
        else if (func.substr(0, 2) == "0x")
        {
            et_keyboard_buffer += String.fromCharCode(func);
            retcode = 1;
            reset = true;
        }
        else
        {
            if (et_keyboard_mode == func) et_keyboard_setmode("key", et_keyboard_shift, false);
            else et_keyboard_setmode(func, et_keyboard_shift, modelock);
        }
        break;

    }

    if (reset)
    {
      if (!et_keyboard_modelock && (et_keyboard_mode != "key"))
      {
        et_keyboard_setmode("key", false);
      }
      else if (et_keyboard_shift)
      {
        et_keyboard_setmode(et_keyboard_mode, false);
      }
    }

    return retcode;
}


function ET_KeyboardDraw(clicked_clicknr)
{
    var key_y = 0;
    var clicknr = 1;
    var fullmode = et_keyboard_mode;
    var clicked = (clicked_clicknr != undefined);

    for (var i = 0; i < et_keyboard_def.length; ++i)
    {
        var key_x = 0;
        var keyrow = et_keyboard_def[i];

        for (var j = 0; j < keyrow.length; ++j)
        {
            var key = keyrow[j];
            var width = Math.round(key[0] * et_keyboard_key_w);
            var drawn = false;

            if (key.length > 1)
            {
                if (!clicked || (clicknr == clicked_clicknr))
                {
                    if (et_keyboard_shift) drawn = et_keyboard_draw_key(et_keyboard_mode + "shift", key, key_x, key_y, width, et_keyboard_key_h, clicknr, clicked)

                    if (!drawn) drawn = et_keyboard_draw_key(et_keyboard_mode, key, key_x, key_y, width, et_keyboard_key_h, clicknr, clicked)

                    if (!drawn) ET_AddImage(et_keyboard_button, key_x, key_y, width, et_keyboard_key_h, 3);
                }

                ++clicknr;
             }


            key_x += width;
        }

        key_y += et_keyboard_key_h;
    }
}


function et_keyboard_setmode(mode, shift, modelock)
{
    et_keyboard_mode = mode;
    et_keyboard_shift = shift;
    et_keyboard_modelock = modelock;
}


function et_keyboard_draw_key(mode, key, x, y, w, h, clicknr, clicked)
{
    var drawn = false;

    // negative width signals double height key
    if (w < 0) { y -= h; h *= 2; w *= -1; }

    for (var k = 1; k < key.length; ++k)
    {
        var keydef = key[k];

        var func = keydef[1];
        if (keydef[0] == mode)
        {
            var image;

            if (clicked)
            {
                image = et_keyboard_buttonclick;
            }
            else if ((et_keyboard_shift && (func == "shift")) || (func == et_keyboard_mode))
            {
                image = et_keyboard_buttonhi;
            }
            else
            {
                image = et_keyboard_button;
            }

            ET_AddClickArea(x, y, w, h, clicknr);
            ET_AddImage(image, x, y, w, h, 3);

            var display = keydef[2];

            if (display.length)
            {
                // TODO: make fontsize keyboard-size dependant
                if (display.length == 1)
                { ET_SetFont(0xFFFFFF, config_fontface, 30, 1, 0); }
                else
                { ET_SetFont(0xFFFFFF, config_fontface, 25, 0, 0); }

                ET_AddTextArea(keydef[2], x, y, w, h, DT_CENTER | DT_SINGLELINE | DT_VCENTER);
            }

            return true;
        }
    }

    return false;
}


function et_keyboard_func_clicked(clickednr)
{
    var fullmode = et_keyboard_mode;
    if (et_keyboard_shift) fullmode += "shift";

    var clicknr = 1;
    for (var i = 0; i < et_keyboard_def.length; ++i)
    {
        var keyrow = et_keyboard_def[i];

        for (var j = 0; j < keyrow.length; ++j)
        {
            var key = keyrow[j];

            if (key.length > 1)
            {
                var tested = false;

                if (et_keyboard_shift)
                {
                    for (var k = 1; k < key.length; ++k)
                    {
                        var keydef = key[k];

                        if (keydef[0] == fullmode)
                        {
                            tested = true;
                            if (clicknr == clickednr)
                            {
                                return keydef;
                            }
                        }
                    }
                }

                if (!tested)
                {
                    for (var k = 1; k < key.length; ++k)
                    {
                        var keydef = key[k];

                        if (keydef[0] == et_keyboard_mode)
                        {
                            if (clicknr == clickednr)
                            {
                                return keydef;
                            }
                        }
                    }
                }

                ++clicknr;
            }
        }
    }
}

// ***********************************************************

