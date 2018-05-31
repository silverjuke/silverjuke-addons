

var hilite_matches;
var hilite_phrases;


// highlight search text
function ET_HilitePhrases(phrases)
{
    var slashmatch = new RegExp("\\\\", "g");
    hilite_phrases = phrases;
    hilite_matches = new Array();

    var i;
    for (i = 0; i < phrases.length; ++i)
    {
        var phrase = phrases[i];
        phrase = phrase.replace(slashmatch, "\\\\");

        hilite_matches.push(new RegExp(phrase, "i"));
    }
}


function ET_Hilite(text, x, y, w, flags)
{
    while (w > 0)
    {
        var i;
        var pos = -1;
        var len;

        // find leftmost hilited phrase in text
        for (i = 0; i < hilite_matches.length; ++i)
        {
            var matchpos = text.search(hilite_matches[i]);

            if ((matchpos >= 0) && ((matchpos < pos) || (pos == -1)))
            {
                pos = matchpos;
                len = hilite_phrases[i].length;
            }
        }

        if (pos == -1) break;

        if (pos > 0)
        {
            // skip normal text
            var size = ET_SizeText(text, pos);
            x += size;
            w -= size

            if (w <= 0) break;
        }

        // draw hilited phrase
        var subtext = text.substr(pos, len);
        ET_AddText(subtext, x, y, w, flags);

        // skip hilited part
        var size = ET_SizeText(subtext, len);
        x += size;
        w -= size

        text = text.substr(pos + len);
    }
}

//************************************************************