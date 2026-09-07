I got myself a dirt-cheap LED projector to use as a situational secondary screen. The projector ran Android 13 and had wifi; I wasn't initially planning on having wireless capbailities, but the availability immediately made me want to attempt to use the projector wirelessly.

Upon turning on the projector, I was very much surprised to see an interface that was very very much inspired by Windows 8. I've never seen anything attempt to emulate the Windows 8 interface besides some Windows Phone launcher apps. This one not only had a "tile-like" interface but also used the side flyouts, dialogs, and fonts that were very much metro-inspired. I immediately wanted to get into developer mode and record its screen to show off its interface.

As I was looking up how to get into developer mode for this device, I immediately stumbled upon some git repositories and blog posts about how these sorts of projectors have malware! I certainly wasn't planning to put this projector on my home wifi network, but now I don't even want to put it on my IOT network either! The malware primarily turns the projector into a proxy for the attacker to use my internet connection as they please.

I've long procrastinated on finding out a way to monitor and restrict traffic with OpenWRT. Now is a perfect opportunity to learn how to do so if I want to use my projector wirelessly.

## Where do I start?

The first order of business was to create its own network. I decided to do this on a downstream access point (AP) running OpenWrt on my guest/iot network. This prevents me from causing any unintentional downtime to the rest of the guest/IOT network, and I'd be using the projector in this area anyway.

Since I only plan to have just this projector on a network by itself, I only need to create another interface and SSID for it to connect to. This was easy.

Ok... now what? I've isolated local traffic from my local subnets before; I've separated my guest, iot, and home network before with VLANs and firewall rules, but I've never restricted nor monitored any traffic going out to the internet.

## Choosing how to monitor and restrict internet access

### Pi-hole?

The blog author who discovered the malware on the projector had caught it via strange requests in his Pi-hole instance. I don't have a dedicated networking device, but my access point has 64MB of memory for me to install whatever I'd like to run; it isn't doing much as a mere access point. So I looked to see if there was a ready-made package to install Pi-hole in OpenWRT. Everything I found online instead talked about directing traffic to a running Pi-hole instance.

That's when I discovered that Pi-hole is intended to be run on its own machine, with a couple GBs of storage and 512MB RAM... too much for a router. I wanted to be able to at least monitor internet traffic without the need of running any extra devices, so I started looking for some alternatives.

### Adguard

