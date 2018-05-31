//************************************************************************************
// MusicSearch library functions
//
// Global namespace used is limited to MusicSearch* (public) and et_musicsearch_* (private)
//
//************************************************************************************

//*** statics *************************************************************************

// internal state for rules parser
var et_musicsearch_lastrules;

//*** public functions*****************************************************************

// find or create a SJ music search filter to be used for our own SQL expressions
//
// db = databse connection
// filtername = uservisible name for the filter
//
// returns -> internal id for the filter
//
function ET_MusicSearchCreate(db, filtername)
{
    var filterid = ET_MusicSearchId(db, filtername);

    if (filterid == -1)
    {
        db.openQuery("insert into advsearch (name) values ('" + filtername + "');");
        db.closeQuery();

        // getField(-1) does not work, SilverJuke bug?
        // as workaround just run the select again instead
        db.openQuery("SELECT id " +
		             "FROM advsearch " +
					 "WHERE name = '" + filtername + "';");
        filterid = db.getField(0);		
        db.closeQuery();
    }

    return filterid;
}


// find an existing SJ music search filter
//
// db = databse connection
// filtername = uservisible name for the filter
//
// returns -> internal id for the filter
//
function ET_MusicSearchId(db, filtername)
{
    var filterid = -1;

    db.openQuery("SELECT id " +
	             "FROM advsearch " +
				 "WHERE name = '" + filtername + "';");
    if (db.nextRecord())
    {
        filterid = db.getField(0);		
    }
    db.closeQuery();

    return filterid;
}


// find name of an existing SJ music search filter
//
// db = databse connection
// filterid = internal id for the filter
//
// returns -> name of the filter
//
function ET_MusicSearchName(db, filterid)
{
    var filtername = "";

    db.openQuery("SELECT name " +
	             "FROM advsearch " +
				 "WHERE id = '" + filterid + "';");
    if (db.nextRecord())
    {
        filtername = db.getField(0);		
    }
    db.closeQuery();

    return filtername;
}


// set up a SJ music search filter based on a given SQL expression
//
// db = databse connection
// filterid = internal id for the filter
// selecttracks = "1" to select tracks, "0" to select albums
// filter = SQL expression to put in the filter
//
function ET_MusicSearchSet(db, filterid, selecttracks, filter)
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


// get the SQL 'where clause' for a SJ music search filter
//
// db = databse connection
// filterid = internal id for the filter
//
// returns -> SQL 'where' string
//
function ET_MusicSearchGet(db, filterid)
{
    db.openQuery("SELECT rules " +
	             "FROM advsearch " +
				 "WHERE id=" + filterid);
    if (db.nextRecord())
    {
        var rules = db.getField(0);		
        return et_musicsearch_rules_to_sql(rules);
    }
    db.closeQuery();

    return "1";
}


// I really wish there was a public API for this one :-)
// this converts the SJ advsearches.rules field to its SQL expression.
//
// The only thing not supported is limit-clauses (from the Music Selection GUI
// I mean, not SQL 'select ... limit ...')
//
function et_musicsearch_rules_to_sql(rules)
{
    var count = Number(et_musicsearch_rules_get_field(rules));
    var id = Number(et_musicsearch_rules_get_field());
    var name = et_musicsearch_rules_get_field();
    var tracks = Number(et_musicsearch_rules_get_field());
    var combine = Number(et_musicsearch_rules_get_field());
    var subrules = Number(et_musicsearch_rules_get_field());

    count -= 5;
    while (count--) et_musicsearch_rules_get_field();

    var where = "";
    var incl = "";
    var excl = "";

    while (subrules--)
    {
        var subcount = Number(et_musicsearch_rules_get_field());

        var field = Number(et_musicsearch_rules_get_field());
        var action = Number(et_musicsearch_rules_get_field());
        var value1 = et_musicsearch_rules_get_field();
        var value2 = et_musicsearch_rules_get_field();
        var unit = Number(et_musicsearch_rules_get_field());

        if (field == 0) // limit
        {
            alert("SKIN WARNING: The 'limit' clause of a Music Selection\nwill be ignored by this skin");
        }
        else if (field == 6) // include tracks
        {
            if (incl != "") incl += ", ";
            incl += value1;
        }
        else if (field == 6) // include tracks
        {
            if (excl != "") excl += ", ";
            excl += value1;
        }
        else
        {
            if (where != "") { if (combine == 0) { where += " AND "; } else { where += " OR "; } }

            var clause = "";
            if (field == 2) // SQL
            {
                clause = value1;
            }
            else if (field == 3) // title/artist/album
            {
                clause = "((" + et_musicsearch_rules_clause(200, action, value1, value2, unit) + ") OR (" +
                                et_musicsearch_rules_clause(300, action, value1, value2, unit) + ") OR (" +
                                et_musicsearch_rules_clause(400, action, value1, value2, unit) + "))";
            }
            else
            {
                clause = et_musicsearch_rules_clause(field, action, value1, value2, unit);
            }

            where += "(" + clause + ")";
        }

        subcount -= 5;
        while (subcount--) et_musicsearch_rules_get_field();
    }

    if (incl != "")
    {
        if (where != "") where += " OR ";
        where += "id in (" + incl + ")";
    }

    if (excl != "")
    {
        if (where != "") where += " AND ";
        where += "NOT id in (" + excl + ")";
    }

    if (combine == 2) where = "NOT (" + where + ")";

    return where;
}

//*** private functions ***************************************************************

// build a single 'where clause' for the given SJ subrule values
function et_musicsearch_rules_clause(field, action, value1, value2, unit)
{
    var fieldname = et_musicsearch_rules_field(field);
    var fieldtype = et_musicsearch_rules_type(field);
    var value1 = et_musicsearch_rules_value(value1, unit);
    var value2 = et_musicsearch_rules_value(value2, unit);
    var clause;
    var op;

    switch (action)
    {
    case 0: // is equal to
    case 1: // is unequal to
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " = '" + value1 + "'";
            break;
        case 1: // number
            clause = fieldname + " =" + value1;
            break;
        case 2: // date
            clause = fieldname + " >= TIMESTAMP('" + value1 + ") AND " +
                     fieldname + " < TIMESTAMP('" + value1 + " + 1')";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 2: // is set
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " != ''";
            break;
        case 1: // number
        case 2: // date
            clause = fieldname + " != 0";
            break;
        }
        break;

    case 3: // is unset
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " = ''";
            break;
        case 1: // number
        case 2: // date
            clause = fieldname + " = 0";
            break;
        }
        break;

    case 4: // greater than
    case 5: // greater or equal
        op = " > ";
        if (action & 1) op = " >= ";

        switch (fieldtype)
        {
        case 0: // string
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'string greater than'");
            clause = "1";
            break;
        case 1: // number
            clause = fieldname + op + value1;
            break;
        case 2: // date
            clause = fieldname + op + "TIMESTAMP('" + value1 + " 23:59:59')";
            break;
        }
        break;

    case 6: // less than
    case 7: // less or equal
        op = " < ";
        if (action & 1) op = " <= ";

        switch (fieldtype)
        {
        case 0: // string
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'string less than'");
            clause = "1";
            break;
        case 1: // number
            clause = fieldname + op + value1;
            break;
        case 2: // date
            clause = fieldname + " != 0 AND " + fieldname + op + "TIMESTAMP('" + value1 + "')";
            break;
        }
        break;

    case 8: // in range
    case 9: // not in range
        switch (fieldtype)
        {
        case 0: // string
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'string in range'");
            clause = "1";
            break;
        case 1: // number
            clause = "(" + fieldname + " >= " + value1 + " AND " + fieldname + " <= " + value2 + ")";
            break;
        case 2: // date
            clause = fieldname + " >= TIMESTAMP('" + value1 + "') AND " + fieldname + " <= TIMESTAMP('" + value2 + " 23:59:59')";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 10: // contains
    case 11: // does not contain
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " LIKE '%" + value1 + "%'";
            break;
        case 1: // number
        case 2: // date
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'number/date contains'");
            clause = "1";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 12: // starts with
    case 13: // does not start with
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " LIKE '" + value1 + "%'";
            break;
        case 1: // number
        case 2: // date
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'number/date starts with'");
            clause = "1";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 14: // ends with
    case 15: // does not end with
        switch (fieldtype)
        {
        case 0: // string
            clause = fieldname + " LIKE '%" + value1 + "'";
            break;
        case 1: // number
        case 2: // date
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'number/date ends with'");
            clause = "1";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 16: // date in the last
    case 17: // date not in the last
        switch (fieldtype)
        {
        case 0: // string
        case 1: // number
            alert("SKIN WARNING: Unexpected clause in Music Selection: 'string/number in the last'");
            clause = "1";
            break;
        case 2: // date
            clause = fieldname + " >= TIMESTAMP('" + value1 + "')";
            break;
        }
        if (action & 1) clause = "NOT (" + clause + ")";
        break;

    case 18: // is similar to
        clause = "LEVENSTHEIN(" + fieldname + ", '" + value1 + "')=1";
        break;

    case 19: // starts similar to
        clause = "LEVENSTHEIN(SUBSTR(" + fieldname + ", 1, " + value1.length + "), '" + value1 + "')=1";
        break;

    default:
        alert("SKIN WARNING: unsupported action code (" + action + ")");
        break;

    }

    return clause;
}


// give the SQL expression for the given SJ fieldnumber
function et_musicsearch_rules_field(fieldid)
{
    switch (fieldid)
    {
    case 005: return "QUEUEPOS(tracks.url)"; // queue position
    case 004: return "FILETYPE(tracks.url)"; // file type
    case 100: return "tracks.url"; // file name
    case 101: return "tracks.timeadded"; // date added
    case 102: return "tracks.timemodified"; // date modified
    case 103: return "tracks.timesplayed"; // play count
    case 104: return "tracks.lastplayes"; // last played
    case 105: return "tracks.databytes"; // file size
    case 106: return "tracks.bitrate"; // bitrate
    case 107: return "tracks.samplerate"; // samplerate
    case 108: return "tracks.channels"; // channels
    case 109: return "tracks.playtimems"; // duration
    case 110: return "tracks.autovol"; // volume
    case 200: return "tracks.trackname"; // title
    case 201: return "tracks.tracknr"; // track number
    case 202: return "tracks.trackcount"; // track count
    case 203: return "tracks.disknr"; // disc number
    case 204: return "tracks.diskcount"; // disc count
    case 300: return "tracks.leadartistname"; // artist
    case 301: return "tracks.orgartistname"; // original artist
    case 302: return "tracks.composername"; // composer
    case 400: return "tracks.albumname"; // album
    case 500: return "tracks.genrename"; // genre
    case 501: return "tracks.groupname"; // group
    case 502: return "tracks.comment"; // comment
    case 503: return "tracks.beatsperminute"; // BPM
    case 504: return "tracks.rating"; // my rating
    case 505: return "tracks.year"; // year
    default:
        alert("SKIN WARNING: unsupported field code (" + fieldid + ")");
        return "";
    }
}


// give the category for the given fieldnumber
function et_musicsearch_rules_type(fieldid)
{
    switch (fieldid)
    {
    case 004: // file type
    case 100: // file name
    case 200: // title
    case 300: // artist
    case 301: // original artist
    case 302: // composer
    case 400: // album
    case 502: // comment
    case 500: // genre
    case 501: // group
        return 0; // string

    case 005: // queue pos
    case 103: // play count
    case 105: // file size
    case 106: // bitrate
    case 107: // samplerate
    case 108: // channels
    case 109: // duration
    case 110: // volume
    case 201: // track number
    case 202: // track count
    case 203: // disc number
    case 204: // disc count
    case 505: // year
    case 503: // BPM
    case 504: // my rating
        return 1; // number

    case 101: // date added
    case 102: // date modified
    case 104: // last played
        return 2; // date

    default:
        alert("SKIN WARNING: unsupported rule type code (" + typeid + ")");
        return -1;
    }
}


// convert the given SJ value/unit into its SQL equivalent
function et_musicsearch_rules_value(value, unit)
{
    switch (unit)
    {
        case 101: // minutes
            return "now - " + value;
        case 102: // hours
            return "now - " + value * 60;
        case 103: // days
            return "today - " + value;
        case 200: // byte
            return value;
        case 201: // Kbyte
            return value * 1024;
        case 202: // Mbyte
            return value * 1024 * 1024;
        default:
            return value;
    }
}


// get a single value from a SJ rules definition
// (keeps internal state, next calls with
// rules=undefined return next values from definition)
function et_musicsearch_rules_get_field(rules)
{
    if (rules == undefined)
    {
        rules = et_musicsearch_lastrules;
    }

    var length = "0x";
    var pos = 0;

    while (pos < rules.length)
    {
        c = rules.charAt(pos++);
        if (c == ':') break;
        length += c;
    }

    length = parseInt(length);

    et_musicsearch_lastrules = rules.substr(pos + length);

    return rules.substr(pos, length);
}


// convert decimal value into hex representation (needed for SJ internal filters)
//
// dec = decimal value
//
// returns -> string with hex value (no leading 0x)
//
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

//*** end *****************************************************************************

