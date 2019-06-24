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

# Where to write locally, and whether to write to file or console
$filePath    = "C:\Users\yt\Documents\Twitch Assets\mlbscore.txt"
$debugOn     = $true
$writeOutput = $true

# Choose your fighter! This is the Unicode box vertical, which is a nice, neat divider
# But totes pick whatever you want here
# Set to a space or $null if you don't want a delimiter
$delimiter = [char]0x2502

# The data that sets the wheels into motion - team and date
# You can pick a past date to get a specific game's final outcome
# However, this code is not intended to iterate through a past game
# The intended use is to determine the current day and date and let the script iterate over a live game
# It should stop when the live game is over
$teamID = $NYM
$MLB_today = Get-Date -format "MM/dd/yyyy"

# Get the current gamePk, or game specific ID, based on the team and date set above
# You could also set this parameter by any number of inputs, so feel free to get creative
# This works for historical games as well as current ones
# You just have to adjust the dates and timestamps accordingly
$URI_games = "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date="+$MLB_today+"&teamId="+$teamID
$mlb_games = Invoke-RestMethod -Uri $URI_games
if ($mlb_games.totalGames) {
    $mlb_gamekey = $mlb_games.dates.games.gamePk
}

# Get initial timestamp from diffPatch so we're not polling the entire data set until it updates
$diffPatch = Invoke-RestMethod -Uri $URI_diffPatch
$startTime = $diffPatch.metaData.timeStamp

function buildLinescore ([string]$gameKey,[string]$outputfile) { # This is where the magic happens
    # Build URIs
    $URI_boxscore  = "https://statsapi.mlb.com/api/v1/game/"+$gamekey+"/boxscore"
    $URI_linescore = "https://statsapi.mlb.com/api/v1/game/"+$gamekey+"/linescore"
    $URI_pbp       = "https://statsapi.mlb.com/api/v1/game/"+$gamekey+"/playByPlay"

    # Grab the API data needed to build the line score
    $mlb_boxscore  = Invoke-RestMethod -Uri $URI_boxscore
    $mlb_linescore = Invoke-RestMethod -Uri $URI_linescore
    $mlb_pbp       = Invoke-RestMethod -Uri $URI_pbp

    # Start by building the front part of the line score
    $abbr_away = $mlb_boxscore.teams.away.team.abbreviation
    $abbr_home = $mlb_boxscore.teams.home.team.abbreviation
    if ($abbr_away.length -lt 3) {
        $abbr_away += " "
    }
    if ($abbr_home.length -lt 3) {
        $abbr_home += " "
    }

    # Add win/loss percentage to team names
    $away_record = $mlb_boxscore.teams.away.team.record.winningPercentage
    $home_record = $mlb_boxscore.teams.home.team.record.winningPercentage

    # Capture the RHE data for both teams
    $away_runs = $mlb_linescore.teams.away.runs
    $away_hits = $mlb_linescore.teams.away.hits
    $away_errs = $mlb_linescore.teams.away.errors

    $home_runs = $mlb_linescore.teams.home.runs
    $home_hits = $mlb_linescore.teams.home.hits
    $home_errs = $mlb_linescore.teams.home.errors

    # Build the front for each row in the line score
    $rowI = "           $delimiter"
    $rowA = "$abbr_away ($away_record) $delimiter"
    $rowH = "$abbr_home ($home_record) $delimiter"

    # Placeholder for future solution for walk-off home games where an X should be on the line score's home team last inning slot
    $curr_inning = $mlb_linescore.currentInning
    $sche_inning = $mlb_linescore.scheduledInnings

    # Iterate thru the innings and build the line score
    for ($i=0; $i -lt $curr_inning; $i++) { 
        $runsA = $mlb_linescore.innings[$i].away.runs
        #if (($mlb_linescore.teams.home.runs -gt $mlb_linescore.teams.away.runs) -and (-not $mlb_linescore.innings[$i].home.runs) -and (($i+1) -ge $sche_inning) -and ($curr_inning -eq $sche_inning)) {
        #    $runsH = "X" # NOT WORKING: The intent here is to write an X into the home team's final inning if they win a walk-off
        #}
        #else {
            $runsH = $mlb_linescore.innings[$i].home.runs
        #}

        # Write individual inning data
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

    # Write runs, hits, and errors data with proper spacing
    $rowI += "$delimiter$delimiter  R $delimiter  H $delimiter  E $delimiter$delimiter"

    # Away
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

    # Home
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

    # Pull venue info from API
    $venue = $mlb_boxscore.teams.home.team.venue.name
    $location = $mlb_boxscore.teams.home.team.locationName

    # Use Unicode arrow characters for "graphics" that indicate top, middle, or bottom of an inning
    # Any other inning status is blank
    $inningState = switch ($mlb_linescore.inningState) {
        "Top"    {[char]0x2B06}
        "Bottom" {[char]0x2B07}
        "Middle" {[char]0x2B0C}
        default  {" "}
    }

    # IA IA IA revere and publish the count
    $curr_inning = $mlb_linescore.currentInningOrdinal
    $balls       = $mlb_linescore.balls
    $strikes     = $mlb_linescore.strikes

    # Use Unicode triangles to indicate bases that are occupied
    # 1st base
    if ($MLB_linescore.offense.first) {
        $firstBase = [char]0x25B6
    }
    else {
        $firstBase = [char]0x25B7
    }

    # 2nd base
    if ($MLB_linescore.offense.second) {
        $secondBase = [char]0x25B2
    }
    else {
        $secondBase = [char]0x25B3
    }

    # 3rd base
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
        default {""} # This should never happen, but sports are weird
    }

    # Build current inning status line
    $rowS = "$InningState $curr_inning $balls-$strikes $thirdBase$secondBase$firstBase $outs at $venue in $location"

    clear-host # For visual clarity, duh; only matters if debugging is enabled

    # Poll API to get current play-by-play info, and if there isn't any, build pitching and batting stats line for the current players
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

    # Write line score to the console if debugging is enabled
    if ($debugOn) {
        write-host $rowI
        write-host $rowA
        write-host $rowH
        write-host $rowS
        write-host $rowP
    }

    # Write line score to text file for digestion by external apps if enabled
    if ($writeOutput) {
        $rowI | out-file -FilePath $filePath -encoding UTF8
        $rowA | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowH | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowS | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowP | out-file -FilePath $filePath -encoding UTF8 -Append
    }
}

function publishLinescore ([string]$gameKey,[string]$outputfile) {
    do { # Run script continuously while game is in session
        buildLinescore($gamekey,$outputfile)

        $URI_diffPatch = "https://statsapi.mlb.com/api/v1.1/game/"+$gameKey+"/feed/live/diffPatch"

        do { # Pause for 5 seconds before polling diffPatch and continue to poll until a new event happens
            Start-Sleep -Second 5
            $URI_newDiff = $URI_diffPatch+"?startTimecode="+$startTime
            $newDiffPatch = Invoke-RestMethod -Uri $URI_newDiff
        } while (!$newDiffPatch)

        # Set most recent updated event timestamp to startTime for next iteration
        $newTime = $newDiffpatch[0].diff[0].value
        $startTime = $newTime

        # Check whether the game is over
        $URI_live = "https://statsapi.mlb.com/api/v1.1/game/"+$mlb_gamekey+"/feed/live/"
        $live = Invoke-RestMethod -Uri $URI_live
    } while ($live.gameData.status.abstractGameState -ne "Final")
}

publishLinescore($mlb_gamekey,$outputfile)