// cover art caching

var covercache_folder;
var covercache_db;
var covercache_keywords;


function ET_CoverArtCacheClear()
{
    var files = File.dir(ET_CACHEDIR);

    var i;
    for (i = 0; i < files.length; ++i) File.remove(files[i]);
}


function ET_CoverArtInit(folder)
{
    // while no timestamp checks yet: completely clear cache
    ET_CoverArtCacheClear();

    covercache_db = new Database();

    var wordmatch = new RegExp("[^, ]+", "g");
    var keywords = program.iniRead('library/coverKeywords', "folder, front, vorn, outside, cover");
    covercache_keywords = keywords.match(wordmatch);
}


// locate coverart in cache
function ET_CoverCache(id, size)
{
    var cachefile = ET_CACHEDIR + id + "-" + size + ".bmp";
    if (File.exists(cachefile)) return cachefile;

    return undefined;
}


function ET_CoverArt(albumid, trackurl, size, cache)
{
    var cachefile;
    var i, k, f;

    cachefile = ET_CACHEDIR + "temp.bmp";
    File.remove(cachefile);

    // test trackurl first
    if (trackurl != undefined)
    {
        if (ET_ID3ToBmp(trackurl, cachefile, size, size) == 0) return cachefile;
    }

    if (cache)
    {
        cachefile = ET_CACHEDIR + albumid + "-" + size + ".bmp";
        File.remove(cachefile);
    }

    // collect all urls for the album
    var urls = new Array();
    covercache_db.openQuery("SELECT url " +
	                        "FROM tracks " + 
							"WHERE albumid = " + albumid + " " +
							"ORDER BY tracknr");
    while (covercache_db.nextRecord()) urls.push(covercache_db.getField(0));
    covercache_db.closeQuery();

    // then try the images in the directory
    // (presume first track is in album directory)
    var match_uptolastslash = new RegExp(".*/", "i");
    var folder = urls[0].match(match_uptolastslash)[0];
    var files = File.dir(folder);
    var match_extension = new RegExp(".jpg$", "i");

    // try all images with keywords in order of preference
    for (k = 0; k < covercache_keywords.length; ++k)	
    {
        for (f = 0; f < files.length; ++f)	
        {
            var filename = files[f];

            if (filename.search(covercache_keywords[k]) > 0)
            {
                if (filename.match(match_extension))
                {
                    if (ET_ImageToBmp(filename, cachefile, size, size) == 0) return cachefile;
                }
            }
        }
    }

    // try all images
    for (f = 0; f < files.length; ++f)	
    {
        var filename = files[f];

        if (filename.match(match_extension))
        {
            if (ET_ImageToBmp(filename, cachefile, size, size) == 0) return cachefile;
        }
    }

    // try the ID3 in the track
    if (trackurl != undefined)
    {
        if (ET_ID3ToBmp(trackurl, cachefile, size, size) == 0) return cachefile;
    }

    // finally try the ID3 tag in all the albumfiles
    for (i = 0; i < urls.length; ++i)
    {
        if (ET_ID3ToBmp(urls[i], cachefile, size, size) == 0) return cachefile;
    }

    // fallback to default cover
    ET_ImageToBmp(DEFAULTCOVER, cachefile, size, size);

    return cachefile;
}

