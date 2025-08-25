## Summary

If HDDERR is showing up on your DMR-EH55 (or other similar panasonic DVRs), double check the IDE cable and its connection.

## Story

I apparently did not record many details of this story - only the solution.

I was swapping a hard disk drive from one Panasonic DMR-EH55 that would not boot up, to another. The goal was to retrieve the contents recorded to this hard drive.

After opening it up and disconnecting the cables from each and performing the swap to the working DVR, I found that it requested to format the drive. That's not what we want - we want its data! So, swapping to another DVR isn't the way to retrieve the recordings on this drive; I'll have to find another solution.

I swapped back in the original hard disk drive; upon booting up the DVR, I got an HDDERR. If I recall correctly, it also opens up the DVD Drive when printing this error.

This hard disk drive was working before; it's unlikely it could have gone bad during this swap? I started looking up all sorts of things. Given what I was finding, my hypothesis was that maybe it got messed up when plugging in the other hard disk drive, as it likely has a different identifier, and now no longer recognizes its original drive, maybe? I see that it opening the DVD Drive meant it was requesting a special DVD drive that would initialize whatever it needed to put on the hard disk drive.

I spent the rest of the night trying to locate such a DVD, or a DVD image, or even something to initialize the disk manually. The best I could find was something for PAL DVRs; I have no idea if it would work on my NTSC one.

I was quite dejected. Late at night, a thought came to me: "what if the IDE cable is bad? What happens if it is booted without any HDD plugged in?" Lo and behold, the same HDDERR comes up with no connection. "Alright, let's try swapping the IDE cable." And kablam, it works with the swapped cable.