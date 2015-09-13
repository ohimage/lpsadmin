# What Are Plugins #
Plugins are a way for users to add commands and functionality to LPSAdmin.
Plugins have a custom protected hook system aswell as properties used by PAdmin to load them and know what to do with them.
Depending on the way thease properties are configured PAdmin will handle plugins in different ways. The most common configuration is for commands

# How to make a Plugin #
A plugin is simply a table containing a functions and some properties telling PAdmin how to load and handle the plugins. PAdmin will automatically call a plugin's functions when appropriate. This eliminates alot of overhead work for plugin developers.

Important: Simply putting a plugin in the PAdmin/plugins/ folder isnt enough! For PAdmin to recognize it you must register the plugin with the
PAdmin:RegisterPlugin( name, tbl ) function. As it's arguements it takes the Plugin's name ( make this something short but descriptive. Less than 20 chars is best ), and the plugin table ( the table where all the plugin's functions and properties are ).

## Naming ##
NOTE: This format may be subject to change.

As with any file, PAdmin needs to know where a file should be run ( Client, Server or Shared ). PAdmin uses the plugin's name to determine this. If a plugin ends with _sh it will run shared,_cl runs clientside, and _sv runs serverside. ( Ex: helloworld\_cl.lua )_

All plugins should go in the PAdmin/plugins/ folder.

## Plugin Resource ##
PAdmin is constructed to provide many resources that plugins can use to make tasks easier.

### Plugin Hooks ###
PAdmin offers a set functions that are automatically called on plugins that act like hooks.
The Functions are as follows:
  * Hook\_PlayerSpawn
  * Hook\_PlayerInitialSpawn
  * Hook\_PlayerDeath
  * Hook\_HUDPaint
  * Hook\_HUDPaintBackground
  * Hook\_PlayerSay - dont confuse this with the chat command system. It shouldnt be used for commands
  * Hook\_PlayerConnect
Thease are used as follows:
Ex: pluginTable.Hook\_PlayerSpawn = function( ply ) end