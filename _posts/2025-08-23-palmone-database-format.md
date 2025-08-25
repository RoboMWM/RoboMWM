# The mysterious "PalmSG Database00RV" format

## Summary

There is nothing on the internet (or at least in any search engine crawlers nor AI) about the `PalmSG Database00RV` format, which is the format my backed-up Palm data uses. After nearly a week of making seemingly no progress in discovering anything about this mystery (not counting the week-long break in between), I have finally solved it!

I have discovered that Palm Desktop data can be stored in at least three different formats:

| Palm Desktop version | Palm .dat header |
|----------------------|------------------|
| up to 4.1 | ` BD8C:\Program Files\Handspring\user\datebook\datebook.dat` |
| PalmOne 4.1.4, 4.1.4E, 4.2... | `¾ºþÊPalmSG Database00RV BD            C          8C:\Program Files\Handspring\user\datebook\datebook.dat` |
| by ACCESS 6.2.2 | ([Microsoft Access format](https://stackoverflow.com/a/11016883/4025452) in `.mdb` files) ``   Standard Jet DB    µnb`	ÂUé©gr@?`` |

After doublechecking some of the sources I used to find out information in the story below, I see there is a vague mention of ["the update to the 4.1 Desktop application" changing the binary format "to handle the new fields that were added".](https://stackoverflow.com/a/434605/4025452)

## Story

I've been deduplicating and decluttering my file backups. One of the sets of duplicated data was my Palm PDA backups. Although most of the duplicates are duplicated apps, I also wanted to check and consolidate or delete the data from the hotsync users I created over the years.

I did not know which version of Palm Desktop I used as I had multiple versions backed up: 3.11 (from a Handspring Visor CD), 4.1, and 6.2.2. I took a guess and installed Palm Desktop 4.1. In case I needed to muck around with different versions of Palm Desktop, I installed this in a fresh new VMware virtual machine running Windows XP Professional SP3.

Palm Desktop doesn't appear to have a way to "import" users, so either I had to make a user with the same name and copy over the folder it creates with the user, or copy in the specific `.dat` files. In each user directory is at least 4 directories of data that gets synchronized with Palm Desktop: address, datebook, memopad, and todo. My oldest user contained a few files in each of these, e.g. for `datebook`:

```
08/27/2011  09:50 PM            13,597 datebook.001.dat
06/16/2012  08:24 PM            20,538 datebook.bak
06/16/2012  08:24 PM            20,538 datebook.dat
06/16/2012  08:22 PM                16 UiPrefs.dat
02/14/2010  04:35 PM             9,843 Unfiled.DBA
```

I quickly discovered that Palm Desktop only cares about `<name>.dat`, so for datebook, it only tries `datebook.dat`. After pasting in `datebook.dat`, I was met with

![Error: Failed to open Date Book database]()

Perhaps there was more I had to do than just merely copy in a `.dat` file? I looked into the `.dat` files themselves. They are binary files, but the contents of my data were in plaintext. Only the organization of said data was not easily decipherable. I noticed that they all included the location of the file. Nothing changed after reinstalling Palm Desktop to use the `Handspring` folder.

I then tried installing the other versions of Palm Desktop I had. I was met with the same error message in Palm Desktop 3.11, and something similar in 6.2.2 (which uses `.mdb` files, so I believe I attempted renaming the `.dat` files to `.mdb).

Annoyed, I took another look into the `.dat`, and also the other files in the directories. After looking at the `.001.dat` file, I noticed something peculiar. The `.dat` files started with `PalmSG Database00RV` and a bit of whitespace before it , while the `.001.dat` (and `.DBA` and similar archive formats) files only had a few characters before listing the file's location. Palm Desktop 3.11 and 4.1 could read this file!

I began the hunt for the mysterious `PalmSG Database00RV`, and just what software could have converted my Palm Desktop data. An internet search for "PalmSG Database00RV" turns up nothing, so after a few minutes I [decided to give AI a shot.](https://chatgpt.com/share/689d75f7-9800-8000-bf87-01b415e982e8) AI also couldn't find anything on this, and strongly suggested it was an internal format. I did mention that these files were stored in the Handspring folder, which led it to suggest me trying some Palm Desktop installers that originated from Handspring-branded discs. (Which is curious to note that my Handspring CD chooses to install to `Palm` by default instead of `Handspring` - Perhaps I was missing another Handspring CD I must've used decades ago that I haven't located and thus would need to find on the internet.) I tried at least 2 or 3 other versions; results were no different. I was at wits end, going as far as having AI attempt to generate a converter using my `.001.dat` file as a reference. It wasn't confident in its own attempt and only did parts of the file such as the header, assuming that the contents didn't need to be changed. (This is not true - the binary data separating the content was definitely different.)

What software could I have possibly used way back then that mysteriously converted my data to this format that does not exist on the internet? I poked around in a backup of the Handspring folder I backed up some years ago from my computer (back before I knew of/was familiar image backups), and didn't find much of anything... at least not the first time I looked at it. I saw that the `Palm.exe` file stated version 4.1.4. I naively assumed that the Palm Desktop I was using - 4.1 - was either the same install, or similar enough.

As I had something planned for the following week, I didn't have an opportunity to continue investigating this issue for a week. After returning, I took another look at my backups, particularly the Handspring folder again. What if I try to paste the contents of this install over my existing Palm Desktop install? And so I did - which would cause Palm Desktop to crash almost instantly upon opening.

However, the splash screen was different:

![palmOne Palm Desktop Software © 1995-2004 Palmsource, Inc. or its subsidiaries. Certain portions © 2003-2004 palmOne, Inc. or its subsidiaries. All rights reserved.]()

That was a big clue. I [asked AI](https://chatgpt.com/share/68ab49d9-dc68-8000-b5e1-0d4c10a20258) what version this was, and it correctly identified it as Palm Desktop 4.1.4. I immediately download 4.1.4E and 4.1.4 from PalmDB, and both greeted me with an installer that uses the palmOne branding. I immediately take a look at the `.dat` files it creates for a new user, and there it is: the `PalmSG Database00RV` header! I wish I paid more attention to the version number of the Palm.exe file in my backup, which also says 4.1.4.

As to how I ended up using Palm Desktop 4.1.4, I can only imagine I decided to upgrade to that version when I was given a Palm Zire, which has PalmOS 4. Given the dates, I likely downloaded this from the internet, and given I didn't use that device as much as the Handspring devices likely explains why I didn't bother to backup this installer version. I never poked into the `.dat` files before, and was thus none the wiser that it had silently converted my `.dat` files, rendering them incompatible with my older Palm Desktop versions.
