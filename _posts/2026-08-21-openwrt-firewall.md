I got myself a dirt-cheap LED projector to use as a situational secondary screen. The projector ran Android 13 and had wifi; I wasn't initially planning on having wireless capabilities, but the availability immediately made me want to attempt to use the projector wirelessly.

Upon turning on the projector, I was very much surprised to see an interface that was very very much inspired by Windows 8. I've never seen anything attempt to emulate the Windows 8 interface besides some Windows Phone launcher apps. This one not only had a "tile-like" interface but also used the side flyouts, dialogs, and fonts that were very much metro-inspired. I immediately wanted to get into developer mode and record its screen to show off its interface.

As I was looking up how to get into developer mode for this device, I immediately stumbled upon some git repositories and [blog posts](https://zanestjohn.com/blog/reing-with-claude-code) about how these sorts of projectors have malware! I certainly wasn't planning to put this projector on my home wifi network, but now I don't even want to put it on my IOT network either! The malware primarily turns the projector into a proxy for the attacker to use my internet connection as they please.

I've long procrastinated on finding out a way to monitor and restrict traffic with OpenWRT. Now is a perfect opportunity to learn how to do so if I want to use my projector wirelessly.

## Where do I start?

The first order of business was to create its own network. I decided to do this on a downstream access point (AP) running OpenWrt on my guest/iot network. This prevents me from causing any unintentional downtime to the rest of the guest/IOT network, and I'd be using the projector in this area anyway.

Since I only plan to have just this projector on a network by itself, I only need to create another interface and SSID for it to connect to. This was easy.

Ok... now what? I've isolated local traffic from my local subnets before; I've separated my guest, iot, and home network before with VLANs and firewall rules, but I've never restricted nor monitored any traffic going out to the internet.

## Choosing how to monitor and restrict internet access

### DHCP

I didn't want to deal with setting a static IP on the projector; navigating the menu via its remote is annoying enough. So this downstream AP will indeed serve as a DHCP server - but only for this new isolated interface

### Pi-hole?

The blog author who discovered the malware on the projector had caught it via strange requests in his Pi-hole instance. I don't have a dedicated networking device, but my access point has 64MB of memory for me to install whatever I'd like to run; it isn't doing much as a mere access point. So I looked to see if there was a ready-made package to install Pi-hole in OpenWRT. Everything I found online instead talked about directing traffic to a running Pi-hole instance.

That's when I discovered that Pi-hole is intended to be run on its own machine, with a couple GBs of storage and 512MB RAM... too much for a router. I wanted to be able to at least monitor internet traffic without the need of running any extra devices, so I started looking for some alternatives.

### dnsmasq and AdGuard

The proposal I initially received from one AI session was to use `dnsmasq` to intercept all DNS requests to be logged. But another AI session immediately suggested using AdGuard with no mention of dnsmasq. I didn't know much about AdGuard and whether it would provide the level of protection I needed to fully close off this active RAT. After combining the two sessions, I learned that AdGuard and Pi-hole are moreso for monitoring and managing DNS requests than actively blocking all network traffic to a domain. It proposed that AdGuard's interface is a lot easier to read than dnsmasq logs, and suggested I install AdGuard for DNS request logging.

### DNS Whitelist

I did have to clarify that I wanted a whitelist of approved connections, as both methods were assuming I only wanted a blacklist. AI then suggested a hybrid setup: AdGuard for DNS request monitoring and logging, and dnsmasq to allow whitelisted domains through the firewall. All other traffic from the isolated interface would be blocked, and later on I'd tweak the iptable rules to log these denials.

AdGuard appears to be designed to run in openwrt with its own openwrt package, and since I had the space on my router to install it, I decided to give it a try. But before that, I wanted AI to generate a script for me.

## Paving the network via openwrt CLI commands

Given that this was on my downstream AP on my "experimental" network, I decided to also let AI attempt to generate a script to automatically install, create, and configure all of the networking required to create this isolated interface. It's already cumbersome enough for me to remember how to isolate my existing networks via the LuCI interface, and this would also be a good learning opportunity of using more of the OpenWRT cli; most of my experience with OpenWRT's cli is just editing some config files like /etc/wireless, since it's several clicks in the interface to setup more than one wifi network at a time.

The first script it gave me would modify the AP's existing networking, namely adding masquerading to my existing LAN interface. I planned to test other things on this AP later, so I asked it to modify the script to be localized only to the new projector interface as much as possible. It instead applied the masquerade only to the new projector interface, and created an additional DNAT firewall rule to redirect port 53 requests to port 5353 which I would configure AdGuard to listen on.

Getting this script to be fully idempotent and to work on OpenWRT 25.x took a few back and forths of error logs. This is probably one of the biggest pain points when using AI - it often uses deprecated and outdated methods. I had to get it to use the new `apk` commands, and it improperly assumed some settings could be overwritten without being removed.

AdGuard setup was the only thing that could not be automated from the OpenWRT terminal. I had to visit AdGuard's setup page on port 3000 and configure where the DNS server listens on (port 5353). Then I configured a new management port and to listen to just the new isolated projector interface, and to forward requests to dnsmasq running on port 53 of the AP.

After getting the infrastructure setup, it was time to test whether the network was truly isolated... with another device (a spare android phone).

## Testing and understanding the setup

My phone was able to acquire an IP address and had no internet access at all, exactly as I expected. So I asked how I can add approved domains to the whitelist, and added some sites like google.com. Hmm...  I can't access them. AI is claiming what I see in AdGuard is correct and gives me some commands to verify if things are working. The command returned an empty set of approved IPs, so something was wrong.

### nftset and dnsmasq-full

Openwrt comes with `dnsmasq` by default which is a lightweight version that does not include nftset, which would include the allowed IPs. To fix, I had to install `dnsmasq-full`. After performing this, I had to specify an explicit table identifier for the set... or so the AI thought, as it found out that this was already automatically done and now proposed deleting the entire set and recreating it. At least that's good for idempotency. After a few more turns, finally IP addresses were showing up in the approved domains table in `nft list`

### Understanding how it allows connections

During the troubleshooting, I understood how the isolation worked. The client inside the projector interface makes a DNS query for a domain. This request gets logged by AdGuard and forwarded to dnsmasq. If the domain is on the whitelist, dnsmasq adds the IP addresses it resolves to the nftables set. The client always gets the resolved IP addresses.

### Guiding the troubleshooting

You still very much need to have at least some idea of what's wrong to help steer AI in the right direction. I _still_ was unable to access some whitelisted sites like youtube.com. After it suggested a range of fixes that did not work, I explicitly asked how I would see the logs of this traffic being blocked. After being given logs, it proposed other fixes which also did not work - I had to explicitly point out that these requests should be showing up here if they are indeed being rejected. 5 turns later of it correcting for Openwrt 25.x syntax, I was suddenly getting the opposite issue - everything was being allowed through! This took around 8 turns of debugging to properly configure the firewall to reject everything that isn't in the approved domains list.

## Lessons learned

- Without the ability to test, AI's "results" are often filled with errors, especially moreso if using newer APIs.
- Troubleshooting with AI still requires you to at least have some idea of what you're working with
- AI will make assumptions about your setup until you tell it otherwise

It is useful though, for the most part, getting down the other parts of the script correct, so I don't have to lookup each and every command that corresponds to the configuration I'd like to change or create in OpenWRT - and in general, I've always viewed AI as a useful prototyping tool. My primary motivation for this project, besides being able to wirelessly project to my projector without it reaching out to a chinese command and control server, was to see what sort of configuration and tools I'd need to setup when I eventually plan to do this sort of monitoring for my entire network. I was never motivated to actually execute on that project as I didn't want to incur downtime nor "waste" time on a test network, until now. And now that I have a script to reference from, I can do things via the CLI instead of attempting to remember what I did in the LuCI interface.

I have published the script and relevant commands at this repo: https://github.com/MLG-SERBUR/openwrt-projector-isolation
