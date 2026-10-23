[![Greznedge laughs at my crashes:
Oh no! It looks like I've taken Minty's code, and dropped it in the deep fryer! ... It missed another typo and something crashed, like some kind of functions/misc_functions.lua:737: attempt to perform arithmetic on local 'proportionC1' (a nil value). This makes 23 times since I've started paying attention.
soweli Minti:
so that doesn't default to half](example.png)](https://www.tumblr.com/zombiotical/820687964304752640)

Interact with a Discord webhook when Balatro crashes. Comes with a deck to automatically crash, for testing.

## How to use
**You'll need [DebugPlus](https://github.com/WilsontheWolf/DebugPlus) to execute relevant commands.**

If you know lua pretty well, you can look at [the source](crash_webhooks.lua) and figure out what you want to do. For those who don't want to do that, further instructions follow.

1. [Make your Discord webhook.](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
2. Eval `CrashHooks.quick_init("your name")`. Use the string you typed in the `author` field of your mod's metadata. (If you're doing this as a non-modder, [create a stub mod](https://docs.smods.dev/Guides/Your-First-Mod/) to hold your name; it doesn't need to actually do anything.)
3. Open up %appdata% or equivalent, and then the "Balatro" folder inside there. For mod with your name in its `author` field, there should be a `[modname]_crashes.txt` file. Open the ones you care about and then follow the instructions inside. Delete the ones you don't care about. **Do not make these files public**; anyone can send a webhook request if they have the URL.

Once you've done this, the webhook(s) will be sent every time Balatro crashes. Note that this is regardless of whether it's actually your mod responsible for the crash; detecting exactly which mod is at fault will never be 100% reliable and currently Crash Webhooks doesn't check at all.

TODO:
- Interface?
- Fix that thing with the file locations. It works it's just messy.
- At least *try* to detect whether the mod that crashed is one with a webhook file. There's already holes that will definitely make this less than 100% reliable but we can at least detect some cases where it's definitely _not_ one of them.