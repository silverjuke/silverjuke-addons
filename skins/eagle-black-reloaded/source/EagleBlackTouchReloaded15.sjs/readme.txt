Eagle Black Touch Reloaded skin
===============================

Some settings must be enabled for this skin to function correctly, the skin will warn about any incorrect settings upon start.
By default the skin expects "Settings->Skins-->fonts&covers" at 90% (the default).
It's also a good idea to set "Settings->Advanced->Further Options->Image cache: Use temporay directory" to "Yes, load images directly and avoid flickering".
To  get even more performance use the skin configuration to enable album art caching at boot, but make sure you set Silverjuke's RAM chache to the max and have enough physical memory for that amount.
For a different coverzoom, especially when using the skin at any other size then 1024x768, the coverzoom & number of visible covers on the mainscreen and the searchresult screen can be changed: outside kioskmode in the mainscreen or searchscreen rightclick->tools->layout-edit.
For the album art caching mechanisms to work properly it is advisable to add files named "folder.jpg" to the top of the list of keywords for cover art files. To accomplish this, go to "Settings->My Music Library->Combine tracks to albums" and add the word "folder" to the beginning of the field "keywords to find the right cover for an album", separated with a comma.


Known limitations:
------------------
- Changes in the music collection will require rescanning with silverjuke and then a restart of the skin (just restarting silverjuke is the easiest).
- It's a touchscreen skin: using the keyboard or doubleclicking might do stuff, but is not supported, and might break things.


Webradio
========
Pre-requisites:
- Silverjuke
- Eagle Black Touch Reloaded v14 or better
- mplayer
- Windows XP Professional (NOT Windows XP Home) or Windows Vista (any version) or Windows 7 (any version) or Windows 8 (any version)
- The Silverjuke folder needs to writable for the user account that silverjuke runs under (which is not the case if you have installed Silverjuke into the Programs folder)

A feature that the "regular" Silverjuke program doesn't come with is the ability to listen to webradio stations. However, the Eagle Black Touch Reloaded skin comes with limited webradio support. However, using the webradio feature is out of the box not possible, because you need an additional piece of software that can not be bundled together with the skin for license reasons: the file in question is the mplayer executable, a command line media player. It can be downloaded and used totally free of charge (no ads, no tricks as far as I can see), however it comes under the GNU GPL 2 license, which means that it can only be bundled with other apps that come under the same license. The skin Eagle Black Touch Reloaded is free to download and use, however it is owned by SilverEagle. As a result, the skin and the mplayer freeware application can not be bundled. That's why you have to download mplayer and save it on your PC. Don't worry though, that's something pretty easy and straightforward and perfectly legal for you to use as long as you don't re-package and make it available to others. In other words: only developers have to worry about those license issues - you as an end user don't have to worry about them.
Mplayer's home page is http://www.mplayerhq.hu/, but as Silverjuke is a Windows-only application you don't have to mind about all the fuzz with different versions for different platforms and operating systems; you just need the music playback features without video playback capabilities, so you will just need the mplayer executable. That's why I created a separate package for you attached to the relevant posting that announces the webradio feature on the silverjuke support board (http://www.silverjuke.net/forum/post.php?p=16066&highlight=#16066); it comes under the GNU GPL 2 license and has been created from the generic build for Intel 486 or better on http://oss.netfarm.it/mplayer-win32.php.
From the package, we only need the file mplayer.exe - just unpack that file and put it into your Silverjuke folder (the folder that silverjuke.exe resides in). Finally, start Silverjuke with the skin Eagle Black Touch Reloaded (v14 or better needed), go to the skin's config dialog and enable webradio usage (the checkbox won't be there if the mplayer file is missing). Once you have enabled webradio usage, a button will be displayed on the cover selection screen that let's you go the the actual web radio screen.
The webradio screen works in a similar manner to the cover screen and contains a dialog in window mode to add or edit radio stations. The edit capabilities don't show in kiosk mode to make sure that your party guests don't mess with the webradio setup.
On the we radio edit screen, the input field "icon" can contain relative paths (seen from the folder that contains silverjuke.exe) or absolute paths to image files. So far, png and jpg have been tested. The field "country code" expects two-digit country code according to ISO in lower case, e.g. "gb" for Great Britain or "au" for Australia.