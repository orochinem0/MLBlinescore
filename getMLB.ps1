# Teams table for later reference
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

# The data that sets the wheels into motion - team and date
$teamID = $NYM
$MLB_today = Get-Date -format "MM/dd/yyyy"

# Local file to write to. Currently, script also writes to the console for debugging purposes
$filePath =  "C:\Users\yt\Documents\Twitch Assets\mlbscore.txt"

# Choose your fighter! This is the unicode box vertical, which is a nice, neat divider
$delimiter = [char]0x2502

# Get the current gamePk, or game identifier, based on the team and date set above
$URI_games = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date="+$MLB_today+"&teamId="+$teamID
$mlb_games = Invoke-RestMethod -Uri $URI_games
if ($mlb_games.totalGames) {
    $mlb_gamekey = $mlb_games.dates.games.gamePk
}

# Set API URIs for later use
$URI_diffPatch = "https://statsapi.mlb.com/api/v1.1/game/"+$mlb_gamekey+"/feed/live/diffPatch"
$URI_boxscore  = "https://statsapi.mlb.com/api/v1/game/"+$mlb_gamekey+"/boxscore"
$URI_linescore = "https://statsapi.mlb.com/api/v1/game/"+$mlb_gamekey+"/linescore"
$URI_live      = "https://statsapi.mlb.com/api/v1.1/game/"+$mlb_gamekey+"/feed/live/"
$URI_pbp       = "https://statsapi.mlb.com/api/v1/game/"+$mlb_gamekey+"/playByPlay"

function buildLinescore { # This is where the magic happens
    # Grab the API data needed to build the line score
    $mlb_boxscore  = Invoke-RestMethod -Uri $URI_boxscore
    $mlb_linescore = Invoke-RestMethod -Uri $URI_linescore
    $mlb_pbp = Invoke-RestMethod -Uri $URI_pbp

    # Build the front part of the line score
    $abbr_away = $mlb_boxscore.teams.away.team.abbreviation
    $abbr_home = $mlb_boxscore.teams.home.team.abbreviation
    if ($abbr_away.length -lt 3) {
        $abbr_away += " "
    }
    if ($abbr_home.length -lt 3) {
        $abbr_home += " "
    }

    $away_record = $mlb_boxscore.teams.away.team.record.winningPercentage
    $home_record = $mlb_boxscore.teams.home.team.record.winningPercentage

    # Capture the RHE data
    $away_runs = $mlb_linescore.teams.away.runs
    $away_hits = $mlb_linescore.teams.away.hits
    $away_errs = $mlb_linescore.teams.away.errors

    $home_runs = $mlb_linescore.teams.home.runs
    $home_hits = $mlb_linescore.teams.home.hits
    $home_errs = $mlb_linescore.teams.home.errors

    # Build the headers for each row in the line score
    $rowI = "           $delimiter"
    $rowA = "$abbr_away ($away_record) $delimiter"
    $rowH = "$abbr_home ($home_record) $delimiter"

    # ...
    $curr_inning = $mlb_linescore.currentInning
    $sche_inning = $mlb_linescore.scheduledInnings

    # Iterate thru the innings and build the line score
    for ($i=0; $i -lt $curr_inning; $i++) { # The intent here is to write an X into the home team's final inning if they win a walk-off
        $runsA = $mlb_linescore.innings[$i].away.runs
        #if (($mlb_linescore.teams.home.runs -gt $mlb_linescore.teams.away.runs) -and (-not $mlb_linescore.innings[$i].home.runs) -and (($i+1) -ge $sche_inning) -and ($curr_inning -eq $sche_inning)) {
        #    $runsH = "X"
        #}
        #else {
            $runsH = $mlb_linescore.innings[$i].home.runs
        #}
        $rowA += "$delimiter"
        $rowH += "$delimiter"
        if ($runsA -lt 10) {
            $rowA += " "
        }
        if (($runsH -lt 10) -or ($runsH -eq "X")) {
            $rowH += " "
        }
        if ($runsA -eq $null) {
            $rowA += "   "
        }
        else {
            $rowA += " $runsA "
        }
        if ($runsH -eq $null) {
            $rowH += "   "
        }
        else {
            $rowH += " $runsH "
        }
        $rowI += "$delimiter  "+($i+1)+" "
    }

    $rowI += "$delimiter$delimiter  R $delimiter  H $delimiter  E $delimiter$delimiter"

    $rowA += "$delimiter$delimiter "
    if ($away_runs -lt 10) {
        $rowA += " "
    }
    if ($away_runs -eq $null) {
        $rowA += " "
    }
    $rowA += "$away_runs $delimiter "

    if ($away_hits -lt 10) {
        $rowA += " "
    }
    if ($away_hits -eq $null) {
        $rowA += " "
    }
    $rowA += "$away_hits $delimiter "

    if ($away_errs -lt 10) {
        $rowA += " "
    }
    if ($away_errs -eq $null) {
        $rowA += " "
    }
    $rowA += "$away_errs $delimiter$delimiter"
    if ($away_runs -lt 10) {
        $rowA += " "
    }

    $rowH += "$delimiter$delimiter "
    if ($home_runs -lt 10) {
        $rowH += " "
    }
    if ($home_runs -eq $null) {
        $rowH += " "
    }
    $rowH += "$home_runs $delimiter "

    if ($home_hits -lt 10) {
        $rowH += " "
    }
    if ($home_hits -eq $null) {
        $rowH += " "
    }
    $rowH += "$home_hits $delimiter "

    if ($home_errs -lt 10) {
        $rowH += " "
    }
    if ($home_errs -eq $null) {
        $rowH += " "
    }
    $rowH += "$home_errs $delimiter$delimiter"

    $venue = $mlb_boxscore.teams.home.team.venue.name
    $location = $mlb_boxscore.teams.home.team.locationName

    # Use a Unicode character for "graphics" to indicate top, middle, or bottom of an inning
    # Any other inning status is blank
    $inningState = switch ($mlb_linescore.inningState) {
        "Top"    {[char]0x2B06}
        "Bottom" {[char]0x2B07}
        "Middle" {[char]0x2B0C}
        default  {" "}
    }

    $curr_inning = $mlb_linescore.currentInningOrdinal

    $balls = $mlb_linescore.balls
    $strikes = $mlb_linescore.strikes

    # Use Unicode triangles to indicate bases that are occupied
    if ($MLB_linescore.offense.first) {
        $firstBase = [char]0x25B6
    }
    else {
        $firstBase = [char]0x25B7
    }

    if ($MLB_linescore.offense.second) {
        $secondBase = [char]0x25B2
    }
    else {
        $secondBase = [char]0x25B3
    }

    if ($MLB_linescore.offense.third) {
        $thirdBase = [char]0x25C0
    }
    else {
        $thirdBase = [char]0x25C1
    }

    # Use open and filled circle Unicode characters to indicate outs
    $outs = switch ($mlb_linescore.outs) {
        "0" {[char]0x26AA+""+[char]0x26AA+""+[char]0x26AA}
        "1" {[char]0x26AB+""+[char]0x26AA+""+[char]0x26AA}
        "2" {[char]0x26AB+""+[char]0x26AB+""+[char]0x26AA}
        "3" {[char]0x26AB+""+[char]0x26AB+""+[char]0x26AB}
        default {""}
    }

    # Build current inning status line
    $rowS = "$InningState $curr_inning $balls-$strikes $thirdBase$secondBase$firstBase $outs at $venue in $location"

    clear-host

    # Poll API to get current play-by-play info, and if there isn't any, build pitching and batting stats for the current players
    if ($mlb_pbp.currentPlay.result.description) {
        $rowP = $mlb_pbp.currentPlay.result.description
    }
    else {
        $URI_pitcherhistorical = "https://statsapi.mlb.com/api/v1/people/"+$mlb_pbp.currentPlay.matchup.pitcher.id+"/stats?stats=season"
        $URI_pitchercurrent    = "https://statsapi.mlb.com/api/v1/people/"+$mlb_pbp.currentPlay.matchup.pitcher.id+"/stats/game/current/?group=pitching"
        $URI_batterhistorical  = "https://statsapi.mlb.com/api/v1/people/"+$mlb_pbp.currentPlay.matchup.batter.id+"/stats?stats=season"
        $URI_battercurrent     = "https://statsapi.mlb.com/api/v1/people/"+$mlb_pbp.currentPlay.matchup.batter.id+"/stats/game/current/?group=hitting"
        $pitcherhistorical     = Invoke-RestMethod -Uri $URI_pitcherhistorical
        $pitchercurrent        = Invoke-RestMethod -Uri $URI_pitchercurrent
        $batterhistorical      = Invoke-RestMethod -Uri $URI_batterhistorical
        $battercurrent         = Invoke-RestMethod -Uri $URI_battercurrent

        $rowP = $mlb_pbp.currentPlay.matchup.pitcher.fullName+" ("+$pitchercurrent.stats.splits.stat.inningsPitched+" IP "+$pitcherhistorical.stats.splits.stat.era+" ERA) pitching to "+$mlb_pbp.currentPlay.matchup.batter.fullName+" ("+$batterhistorical.stats.splits.stat.avg+"/"+$batterhistorical.stats.splits.stat.ops+"/"+$batterhistorical.stats.splits.stat.slg+")"
    }

    # Write line score to the console for debugging
    write-host $rowI
    write-host $rowA
    write-host $rowH
    write-host $rowS
    write-host $rowP

    # Write line score to text file for digestion by external apps
    $rowI | out-file -FilePath $filePath -encoding UTF8
    $rowA | out-file -FilePath $filePath -encoding UTF8 -Append
    $rowH | out-file -FilePath $filePath -encoding UTF8 -Append
    $rowS | out-file -FilePath $filePath -encoding UTF8 -Append
    $rowP | out-file -FilePath $filePath -encoding UTF8 -Append
}

# Get initial timestamp from diffPatch
$diffPatch = Invoke-RestMethod -Uri $URI_diffPatch
$startTime = $diffPatch.metaData.timeStamp

do { # Run script continuously while game is in session
    buildLinescore

    do { # Pause for 5 seconds before polling diffPatch and continue to poll until a new event happens
        Start-Sleep -Second 5
        $URI_newDiff = $URI_diffPatch+"?startTimecode="+$startTime
        $newDiffPatch = Invoke-RestMethod -Uri $URI_newDiff
    } while (!$newDiffPatch)

    # Set most recent updated event timestamp to startTime for next iteration
    $newTime = $newDiffpatch[0].diff[0].value
    $startTime = $newTime

    # Check whether the game is over
    $live = Invoke-RestMethod -Uri $URI_live
} while ($live.gameData.status.abstractGameState -ne "Final")