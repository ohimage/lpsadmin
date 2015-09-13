# What is this? #

This is the documentation for how to use all the awesome functions in the string library coded by TheLastPenguin


# Functions: #

## PAdmin:TimeToMinutes( str ) ##
this function will return a time in minutes given a formated time code as a string. Ex: 1w2d5h would give 1 week 2 days and 5 hours.

## PAdmin:CheckType( string, TimeCode ) ##
This function given a string will check if its the specified type. The time codes are as follows:
  * PAdmin.types.STEAMID
  * PAdmin.types.STRING
  * PAdmin.types.PLY - note this checks for players on the server. Not offline.
  * PAdmin.types.INT
  * PAdmin.types.TIME