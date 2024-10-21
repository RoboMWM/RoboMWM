# Rescuing a CD held hostage by Roxio DirectDisc

![Back of a DirectDisc-burned CD]()

Little did I know just how involved I'd have to be to get the data off of this burned CD.

During the weekend I decided to organize the multitude of discs I had stored away.

Upon flipping through one of the CD cases, I found a marked CD that supposedly contained a PowerPoint of a relative's birthday. I remember seeing this file before as a PowerPoint, as it had existed on the floppy disks I went through earlier (this becomes relevant later).

However, I see that the majority of this disc looks like it's been burned; there must be more than just a mere 2MB PowerPoint...

## 12pm

I decided to pop in the disc into my CD-ROM drive in my Windows XP machine. It spins up for a very short time and then promptly spins down. Windows Explorer says it can't read the disc. "Hmm, perhaps it's damaged or unfinalized" I think to myself. I immediately look online to see if there's a way to read unfinalized discs. I come across https://superuser.com/questions/148647/how-to-read-old-non-finalized-cds and try some of the software, most of which report that it does not see any disc in the drive. I even tried Roxio Easy CD Creator 5, since I also have a copy of that software in my collection of discs - but it too didn't see anything in the drive.

Some of the software wouldn't install on my Windows XP machine, so I decided to try my old Windows 8 laptop with an external eSATA drive. Before I did that, I decided to try the disc in my primary Windows 10 machine that has a DVD-RW burner drive. Here, it doesn't fail immediately. Instead, I hear it grinding, spinning up and down, as if it's struggling to read the disc. Eventually, Windows reports that the disc is blank - instead of erroring out immediately. So now I'm nearly certain it's some unfinalized disc, but it doesn't explain why I can't read it.

Nonetheless, the external eSATA drive for my Windows 8.1 machine is also a DVD+RW Multi Recorder etc. drive (which also becomes important later). I find that ISOBuster is able to read the files - a 1.86MB bday ppt file, and some Outlook backups. All totaling less than 3MBs. However... ISOBuster refuses to copy the files for free and requests payment. I try another software... CDRoller is also able to see the three files, and a deleted fourth file... so this disc was indeed used unconventionally. But it too refuses to recover the files for free. It does reveal that the disc is a UDF 1.50 format. So I begin the hunt for some other software, free software that is willing to recover at least some portion of the data for free.

And... all the other software effectively doesn't see the disc in the drive. I went as far as trying data recovery software that was proported to be extended to support CD drives, but alas it too "didn't see a disc" in the drive. I also attempted installing Roxio software, both the UDF Reader and Easy CD Creator, but these both failed. The former claimed to not find a UDFReader drive, and the latter failed to run its setup program, with Windows stating it's incompatible. (This, too, becomes relevant later... much later.)

## 2pm

"Well, all I gotta do is find the floppy disk version of this PowerPoint file, try to extract it from its pkzip container, and see if it matches the size." Or so I thought.

I soon discover that I, for whatever reason, did not decide to save the PowerPoint file from the floppy disks. I spend some time quickly thinking and trying some USB drives that I possibly was using to transfer the files from the floppy disks, but the USB drive I believe I used was already formatted for a different purpose. I'm sure I already wiped the floppy disks. I search my OneDrive deperately for any sign of a "bday" or "pkzip" file... there is none.

At this point I'm annoyed, and start the search yet again. How is it possible that only a couple of paid software can read these discs? Surely someone has to have made something to read these UDF discs?

I ponder installing an older version of Windows on the laptop; not something I want to do as I'd have to fix the boot order to boot back into Windows 8.1 again. I started a RescueZilla backup while continuing my search. After an hour of searching, and being tired and annoyed, I give up. After a brief nap, I go to Mass as scheduled in the evening. At Mass, it was on my mind, but I somehow was able to let the frustration go and be at peace; I reoriented my desire to be what God wills, not what I will. (And what I willed was an easy solution and to not be defeated by whatever this UDF unfinalized formatted disc is!!) Near the end of Mass, I had a new plan and felt reinvigorated.

## 7pm

Even though this new plan was not ideal, I was not expecting all of the obstacles and hurdles I'd have to work through to proceed with this plan. The goal was to install the Roxio Easy CD Creator software on this laptop; during my searches, I discovered that Roxio's format requires a CD _burner_ to read the disc, which is something that I do not have on the Windows XP machine. (Its CD burner drive is broken and does not spin.)

First, I needed to install Windows 7 onto the PC. I know I have a Windows 7 disc... or not, because I apparently decided it wasn't something I needed to keep around. I didn't know if older versions of Windows would work with the drivers on the PC, and I figured Windows 7 would be old enough to work with Roxio.

"Well, I'll try Windows Vista I suppose." I hit the setup screen, it sees the partition I created for it, and... it can't install. The hard drive is GPT, and it requires MBR. I can't easily change the hard drive disk type to MBR without data loss. I didn't bother to look up if Windows 7 would work with GPT and just guessed that maybe it would. So I spend time looking for a Windows 7 disc.

## 10pm

I find some burned copies of Windows 7 Beta and RC1. RC1 also refuses the same as Vista. "I guess GPT support started with Windows 8." So it was time for the first modification to the plan.

I had an extra unused hard drive lying around, and a Seagate USB adapter I could borrow. "Perhaps I can install a Windows To Go version of Windows 7, and boot off of that?" The answer was yes. WinToUSB existed, and was able to make a Windows 7 To Go... but it would not do it with the Professional edition for free. I search a bit, and find that perhaps an older version would do it. Thanks to the Internet Archive's Wayback machine, I was able to grab an older version that permitted me to create a Windows 7 Professional To Go image onto my USB hard drive.

## 11pm

The laptop successfully boots from it! While I wait for it to install drivers, I play a round of Wii Sports Resort Bowling (I wanted to see how much the gyroscope affects my usual Wii Sports Bowling throw.)

![Wii Sports Resort Bowling score, seven consecutive strikes from frames 2-8, and screwing it all up with frames 9 and 10 open.]()

Windows 7 is running on the laptop, without me having to mess with the primary hard drive! Now let's install Roxio Easy CD Creator... what?! It's also incompatible?? I search online to see what Roxio software is [compatible with Windows 7](https://kb.corel.com/en/128418)... and none, except maybe one, sounds similar to "Easy CD Creator". The situation is even [grimmer for Windows 8](https://kb.corel.com/en/128423) with phrasing that makes it appear as if they aren't interested in updating their products. A forum thread of another user with discs trapped in this Roxio format [also echoes the same sentiments.](https://www.sevenforums.com/music-pictures-video/354631-roxio-easy-cd-creator-v-6-1-a.html) I was so fed up at this point that I considered piracy, but I didn't feel like having to sift through potential malware.

So I now know for sure I need to try an older version, and I'm likely not going to be able to make a To Go install of Vista or XP. I wonder if Windows XP setup would be able to recognize the USB hard drive and install to it. Indeed it does! But... it still requires writing some data to the primary hard drive, which it can't because it's GPT. After briefly looking up ways to convert the hard drive to MBR without data loss, I end up just making another system image backup, this time using Windows, just to give it a try in case the RescueZilla backup doesn't work.

## 1am

After changing the BIOS to use BIOS instead of UEFI, Windows XP eventually installs! Roxio Easy CD Creator installs as well! Let's pop in the disc and... there it is! The disc has a label, and there's the three files! I copy them out. I am thankful, and victorious, but exhausted.

I see that the format is called "DirectDisc," now etched in my mind as a garbage properietary format that holds old, burned, data CDs hostage.

![Screenshot of the DirectDisc eject dialog]()

(Even after selecting that option, the disc was still not readable by any other machine - besides showing how much space left the disc has.)

Since I had a setup capable of reading these "DirectDisc" burned discs, I decided to see if I potentially had any others like this sitting around. Unfortunately (or fortunately, for now), there were no others.

After switching back to UEFI and making a Windows 8 setup USB, I successfully recovered the system back to Windows 8.1 with the system image.

I'm sure I'll eventually come across another "unreadable" disc at some point - and now do I not only know how to (painfully) rescue its data, but exactly who to blame, lol. But this adventure, besides learning a ton of things I didn't expect to be learning, is another testament to the need for open, universal, and most of all, supported, standards. It's appalling to me that this format existed and holds your data hostage behind a paywall, and to this day, is still behind a paywall. Almost feels like ransomware.