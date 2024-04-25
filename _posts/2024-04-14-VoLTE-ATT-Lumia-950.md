# Activating VoLTE for AT&T-branded Microsoft Lumia 950

**TL;DR:** If you want to activate service for VoLTE calls (VoLTE is required on AT&T) on an AT&T-Branded Microsoft Lumia 950 on an AT&T MVNO, make sure the Mobile Network Code (MNC) of the sim card is 410. The MNC can be found near the beginning of the sim card ICCID; it will look like this: 8901**410**. My new provider provided this sim card to me when I asked for an AT&T sim after ordering.

Also a mini rant on Red Pocket support. They used to be good, but I guess they cut down on support staff in recent years or haven't scaled to their user base.

---

I had been using my AT&T-branded Microsoft Lumia 950 for several years with Red Pocket GSMA (AT&T network). Other than support registering my IMEI to allow my phone to register with IMS services and allow for Voice over LTE (VoLTE) calling (which is now a requirement to make and receive calls on AT&T's network due to the 3G shutdown), I had no issues, until recently.

For some days, I noticed my phone would not be able to make any calls, instantly stating call dropped as I placed a call. I noticed that `IMS status: unregistered` would be present by the HD Voice toggle. Rebooting the phone fixed this and it would be reregistered. But on a Saturday afternoon, a reboot would not fix this. I could still send SMS, MMS, and use data, but I was no longer able to make or receive calls.

Seeing this persist over the entire weekend, I started chatting with Red Pocket support. The chat widget was getting laggy as it didn't clear my previous chat with them and the responses were very slow, a few minutes per message. The agent kept asking questions she asked before and I had provided multiple times; she likely was handling several other chats at the same time. I even tried using the sim card in an old unused iPhone 6s, which also couldn’t make or receive a call. After refusing to factory reset my Lumia 950 (factory resetting the iPhone made no difference), she made an escalation ticket, asking for all of the info again. The chat finally concluded after what was about 3-4 hours total.

After that, it was one email per day with the escalation team, which kept claiming it was due to tower issues. They sent a new sim card as part of troubleshooting, and this is where I discovered a new issue: The Lumia 950 (and perhaps other Windows 10 mobile devices) use the Mobile Network Code (MNC) of the sim, or at least some portion of it, to determine what type of sim card it is. The MNC can be found as part of the ICCID number on your sim card. The old sim card I had used MNC 410, while the new card I received used 280, which online search results state this is a relatively new MNC from AT&T. However, my Lumia 950 assumed this was a T-mobile sim card and only offered T-mobile connection profiles. This caused my phone to disable and hide the VoLTE toggle and IMS status.

Regardless, I was still unable to use the new sim card for calls in neither my Lumia 950 nor iPhone, same as before. After more back and forths, Iwas already starting to look to port out. While searching and trying other providers, they had somehow fixed the IMS registration issue on their end, which I knew was the issue the entire time. It had been over 1 1/2 weeks at this point. Thus, the iPhone was now able to make and receive calls with the sim. But now my Lumia 950 can't since it doesn’t think the sim is an at&t sim and won't provide VoLTE.

Support claimed they did not have any sim cards with MNC 410. I eventually tried and received a sim card with MNC 410 from my new provider. I ported over, and my Lumia 950 now works for calls once again after two weeks.

Other providers I tried was US Mobile (Confirmed that tmobile volte does not work with my Lumia 950, unless I want to rely on 2G networks - which means phone has to switch to 2G if on LTE and oftentimes will miss calls since it doesn’t always switch; not to mention tmobile is gradually shutting down 2G…), AT&T prepaid (does work, they sent a sim with MNC 410) and Boost Mobile (which sent a tmobile card, and didn’t even connect to 2G networks).
