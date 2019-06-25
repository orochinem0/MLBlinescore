# MLB Linescore Config File

# API URL
$MLB_URL = "https://statsapi.mlb.com"

# Where to write locally, and whether to write to file or console
$filePath    = "C:\Users\yt\Documents\Twitch Assets\mlbscore.txt"
$debugOn     = $true
$writeOutput = $true

# Teams table
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
$baseOn    = [char]0x25C6
$baseOff   = [char]0x25C7
$outOn     = [char]0x26AB
$outOff    = [char]0x26AA
$top       = [char]0x25B2
$bottom    = [char]0x25BC
$middle    = ""

# Polling delay, in seconds
$diffDelay = 1