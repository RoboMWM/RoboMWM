## Summary

Songs with a sample rate of 32kHz will play at a significantly lower volume on the Zune HD. I have not tested nor own any other working Zune models. Songs with sample rate of 44.1kHz or 48kHz appear to play as expected.

## Story

Recently I've run mp3gain on my library so I don't need to keep fiddling with the volume between tracks. However, I noticed that some tracks are much quieter than others, even within the same album.

I've tried testing the same files on multiple computers with the same zune earbuds, and the volume sounds even on the computers. I've been testing for over a day with different files and even re-encoding the files. The volume difference is only present on the Zune device itself.

Maybe it's just my ears? I then tested recording the Zune's output using a 3.5mm cable from my Zune to my PC's mic input, using Tenacity (audacity fork), and can also see and hear the difference in volume, whereas the volume difference is not apparent with the actual files. I'm glad I was finally able to confirm my ears are indeed working properly lol.

![tenacity]()
![tenacity]()

I took a look at the files again in MediaInfo. I thought the metadata was identical, but upon looking again, I discovered that the sampling rates are different - some songs used 32kHz, while others used 44.1kHz. Not sure how I missed that detail the first time (a diff tool would be nice in MediaInfo!), though I don't see why this would result in volume differences present only in the Zune device. The songs have the same volume on PC despite the differing sampling rates.

After re-encoding the song and forcing a 48kHz sampling rate, the volume now sounds as expected on the Zune. I had to delete the songs from the Zune device for the software to actually sync over the newly encoded songs.
