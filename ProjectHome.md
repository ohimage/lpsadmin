# Themis Admin #
Simple but powerful Garrysmod 13 Server Administration tool!
## What is it? ##
Themis Admin mod is designed specificity for garrysmod 13.
It's highly plugin based and extendable allowing for users to easily make their own commands and add their own functionality. The core of the mod is simply a large library and plugin loader. This makes Themis a very powerful tool dramatically cutting down development times.

## Why should I use it? ##
Due to the very simple nature of its plugin system we are continually developing more functionality for the admin mod, focusing on user experience and making it the most effective management tool possible. Its plugins are all designed based on demand from staff members of multiple respected gaming communities.

## Our Goals ##
I descided to make Themis because I looked at all the mods out there, and they all lack something like a list of all staff members, or autocomplete, or simple and well documented plugin systems. With Aves I hope to fix all of that. Aves will focus on providing the best tool possible for administrating your servers effectively.

## Getting Started ##
Firstly use a tool such as tortus SVN to download the mod.
Once you have the mod installed in your garrysmod beta addon folder the mod will set it's self up with default settings. If you are running a listen server it will auto rank you as owner.
To rank yourself on a MultiPlayer server use lua\_run for k,v in pairs(player.GetAll())do v:SetNWInt("GroupID",2) end
console command on the server, then use !rank in chat to rank yourself as owner. This solution is temporary as running concommands through the server is broken right now. We will have it fixed soon.

## Feature List ##
Main features of the mod:
> ### Plugins ###
    * !god - god mode
    * !ungod - remove godmode
    * !freeze - freeze a user
    * !unfreeze - unfreeze a user.
    * !ban - ban a user.
    * !unban - unban a user.
    * !kick - kick a user.
    * !slap - slap a user
    * !slay - slay a user.
    * !whip - whip a user.
    * PAdmin\_LuaPad - lua pad converted for gmod 13 with PAdmin permissions to use it's features.


### PAdmin is still being developed, but is functional and we only commit after extensive testing ###