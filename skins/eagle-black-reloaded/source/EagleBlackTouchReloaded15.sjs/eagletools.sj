// 'header' file for EagleTools library

var ET_VERSION = "0.15";

// flags for ET_DrawAddText()
// NOTE : not everything makes sense from script
var DT_TOP             = 0x00000000;
var DT_LEFT            = 0x00000000;
var DT_CENTER          = 0x00000001;
var DT_RIGHT           = 0x00000002;
var DT_VCENTER         = 0x00000004;
var DT_BOTTOM          = 0x00000008;
var DT_WORDBREAK       = 0x00000010;
var DT_SINGLELINE      = 0x00000020;
var DT_EXPANDTABS      = 0x00000040;
var DT_TABSTOP         = 0x00000080;
var DT_NOCLIP          = 0x00000100;
var DT_EXTERNALLEADING = 0x00000200;
var DT_CALCRECT        = 0x00000400;
var DT_NOPREFIX        = 0x00000800;
var DT_INTERNAL        = 0x00001000;
var DT_EDITCONTROL     = 0x00002000;
var DT_PATH_ELLIPSIS   = 0x00004000;
var DT_END_ELLIPSIS    = 0x00008000;
var DT_MODIFYSTRING    = 0x00010000;
var DT_RTLREADING      = 0x00020000;
var DT_WORD_ELLIPSIS   = 0x00040000;

// repeatmode for ET_AddImage()
var ET_REPEAT_STRETCH    = 0;
var ET_REPEAT_TILE       = 1;
var ET_REPEAT_GRIDBORDER = 2;
var ET_REPEAT_GRID       = 3;

var ET_CACHEDIR;

var et_skin;
var et_zipskin;


function ET_DLL_Error()
{
    alert("ERROR: Could not load 'EagleTools.dll'");
}


function ET_Init()
{
    program.setTimeout(ET_DLL_Error, 1, false);
    var version = program.callExported("ET");
    program.setTimeout(undefined);

    if (version != ET_VERSION) alert("EagleTools library DLL " + version + " found, expected " + ET_VERSION);

    var skin = program.iniRead('main/skinFile');

    var hashpos = skin.indexOf("#zip:");
    if (hashpos >= 0)
    {
        et_skin = skin.substr(0, hashpos);
        et_zipskin= true;
    }
    else
    {
        et_skin = skin.match(new RegExp(".*\\\\"));
        et_zipskin= false;
    }

    ET_CACHEDIR = program.iniRead("main/temp", ET_GetTempPath() + "Silverjuke\\") + "EagleTools\\";

    if (!File.isdir(ET_CACHEDIR))
    {
        File.mkdir(ET_CACHEDIR);
    }
}

// find a file from inside the skin (can be in a skindirectory or unzipped in the cache)
function ET_Skinfile(filename)
{
    if (File.exists(filename)) return filename;

    var skinfile = et_skin + filename;

    if (!et_zipskin && File.exists(skinfile)) return skinfile;

    var cachefile = ET_CACHEDIR + filename;

    if (!File.exists(cachefile)) ET_Unzip(et_skin, filename, cachefile);

    return cachefile;
}

function ET_GetWindowTop()
{ return Number(program.callExported("ET", 1, 0)); }

function ET_GetWindowLeft()
{ return Number(program.callExported("ET", 1, 1)); }

function ET_GetWindowWidth()
{ return Number(program.callExported("ET", 1, 2)); }

function ET_GetWindowHeight()
{ return Number(program.callExported("ET", 1, 3)); }

function ET_GetTempPath()
{ return program.callExported("ET", 2); }

function ET_SetFont(color, font, size, bold, italic)
{ return program.callExported("ET", 3, color + "|" + size + "|" + bold + "|" + italic + "|" + font); }

function ET_AddFill(x, y, w, h, color)
{ return program.callExported("ET", 4, x + "|" + y + "|" + w + "|" + h + "|" + color); }

function ET_AddText(text, x, y, w, flags, transparency)
{
    if (flags == undefined) flages = 0;
    flags |= DT_NOPREFIX;
    return program.callExported("ET", 5, x + "|" + y + "|" + w + "|0|" + flags + "|" + transparency + "|" + text);
}

function ET_AddTextArea(text, x, y, w, h, flags, transparency)
{
    if (flags == undefined) flages = 0;
    flags |= DT_NOPREFIX;
    return program.callExported("ET", 5, x + "|" + y + "|" + w + "|" + h + "|" + flags + "|" + transparency + "|" + text);
}

function ET_SizeText(text, charcount)
{ return Number(program.callExported("ET", 15, charcount + "|" + text)); }

function ET_AddImage(filename, x, y, w, h, repeatmode, transparency)
{ return program.callExported("ET", 6, x + "|" + y + "|" + w + "|" + h + "|" + repeatmode + "|" + transparency + "|" + ET_Skinfile(filename)); }

function ET_DrawAll()
{ return program.callExported("ET", 7); }

function ET_DrawDeleteAll()
{ return program.callExported("ET", 8); }

function ET_DrawDeleteArea(nr)
{ return program.callExported("ET", 17, nr); }

function ET_ImageToBmp(fromfile, tofile, w, h)
{ return program.callExported("ET", 9, ET_Skinfile(fromfile) + "|" + tofile + "|" + w + "|" + h); }

function ET_ID3ToBmp(fromfile, tofile, w, h)
{ return program.callExported("ET", 10, fromfile + "|" + tofile + "|" + w + "|" + h); }

function ET_SetCallback(event, callback)
{ return program.callExported("ET", 11, event + "|" + callback); }

function ET_SetSizeCallback(callback)
{ return ET_SetCallback(0, callback); }

function ET_SetClickCallback(callback)
{ return ET_SetCallback(1, callback); }

function ET_SetKeyCallback(callback)
{ return ET_SetCallback(2, callback); }

function ET_SetWindowSize(w, h)
{ return program.callExported("ET", 12, w + "|" + h); }

function ET_NewArea(x, y, w, h, color)
{ return program.callExported("ET", 13, x + "|" + y + "|" + w + "|" + h + "|" + color); }

function ET_AddClickArea(x, y, w, h, id)
{ return program.callExported("ET", 14, x + "|" + y + "|" + w + "|" + h + "|" + id); }

function ET_Unzip(zipfile, fromfile, tofile)
{ return program.callExported("ET", 16, ((zipfile == "") ? et_skin : zipfile) + "|" + fromfile + "|" + tofile); }
