# MLB Linescore Config File

# API URL
$MLB_URL = "https://statsapi.mlb.com"

# Time zone constants
$loctz = [Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1')
$locoffset = [System.TimeZoneInfo]::Local.BaseUtcOffset.Hours

# Teams IDs table
$LAA = 108
$ARI = 109
$BAL = 110
$BOS = 111
$CHC = 112
$CIN = 113
$CLE = 114
$COL = 115
$DET = 116
$HOU = 117
$KC	 = 118
$LAD = 119
$WSH = 120
$NYM = 121
$OAK = 133
$PIT = 134
$SD	 = 135
$SEA = 136
$SF	 = 137
$STL = 138
$TB	 = 139
$TEX = 140
$TOR = 141
$MIN = 142
$PHI = 143
$ATL = 144
$CWS = 145
$MIA = 146
$NYY = 147
$MIL = 148

# Delimeters and other common symbols
$delimiter = [char]0x2502 # This is the Unicode box vertical, which is a nice, neat divider
$baseOn    = [char]0x25C6 # Filled diamond
$baseOff   = [char]0x25C7 # Open diamond
$outOn     = [char]0x26AB # Filled circle
$outOff    = [char]0x26AA # Open circle
$top       = [char]0x25B2 # Upward pointing filled triangle
$bottom    = [char]0x25BC # Downward pointing filled triangle
$middle    = [char]0x2B0C # Horizontal double-headed arrow

# Assorted interface bits
$lineMax = 94

# Polling delay, in seconds
# Currently getting this from the live API's "wait" property
#$diffDelay = 1

# The data that sets the wheels into motion - team and date
# You can pick a past date to get a specific game's final outcome
# However, this code is not intended to iterate through a past game
# The intended use is to determine the current day and date and let the script iterate over a live game a specific team is playing
# It should stop when the live game is over
# If the game is upcoming, it should output the teams playing and when the game will start
$teamID = $STL # Team codes and corresponding team IDs stored in the config
$MLB_today = Get-Date -format "MM/dd/yyyy"