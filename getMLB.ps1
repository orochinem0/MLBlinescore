# Includes
. "$PSScriptRoot\cMLB.ps1" # Config file

# The data that sets the wheels into motion - team and date
# You can pick a past date to get a specific game's final outcome
# However, this code is not intended to iterate through a past game
# The intended use is to determine the current day and date and let the script iterate over a live game a specific team is playing
# It should stop when the live game is over
$teamID = $NYM # Team codes and corresponding team IDs stored in the config
$MLB_today = Get-Date -format "MM/dd/yyyy"

# Get the current gamePk, or game specific ID, based on the team and date set above
# You could also set this parameter by any number of inputs, so feel free to get creative
# This works for historical games as well as current ones
# You just have to adjust the dates and timestamps accordingly
$URI_games = $MLB_URL+"/api/v1/schedule?sportId=1&date="+$MLB_today+"&teamId="+$teamID
$mlb_games = Invoke-RestMethod -Uri $URI_games
if ($mlb_games.totalGames) {
    $mlb_gamekey = $mlb_games.dates.games.gamePk
}

# Common URIs
$URI_boxscore  = $MLB_URL+"/api/v1/game/"+$mlb_gamekey+"/boxscore"
$URI_linescore = $MLB_URL+"/api/v1/game/"+$mlb_gamekey+"/linescore"
$URI_pbp       = $MLB_URL+"/api/v1/game/"+$mlb_gamekey+"/playByPlay"
$URI_live      = $MLB_URL+"/api/v1.1/game/"+$mlb_gamekey+"/feed/live/"
$URI_diffPatch = $MLB_URL+"/api/v1.1/game/"+$mlb_gamekey+"/feed/live/diffPatch"

function buildLinescore ([string]$outputfile) { # This is where the magic happens
    clear-host # For visual clarity, duh; only matters if debugging is enabled

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

    for ($i=0; $i -lt $curr_inning; $i++) { # Iterate thru the innings and build the line score
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

    $inningState = switch ($mlb_linescore.inningState) { # Use Unicode arrow characters for "graphics" that indicate top, middle, or bottom of an inning
        "Top"    {$top}
        "Bottom" {$bottom}
        "Middle" {$middle}
        default  {""} # Any other inning status is blank
    }

    # IA IA IA revere and publish the count
    $curr_inning = $mlb_linescore.currentInningOrdinal
    $balls       = $mlb_linescore.balls
    $strikes     = $mlb_linescore.strikes

    # Use Unicode shapes to indicate bases that are occupied
    if ($MLB_linescore.offense.first) { # 1st base
        $firstBase = "1"+$baseOn
    }
    else {
        $firstBase = "1"+$baseOff
    }

    if ($MLB_linescore.offense.second) { # 2nd base
        $secondBase = "2"+$baseOn
    }
    else {
        $secondBase = "2"+$baseOff
    }

    if ($MLB_linescore.offense.third) { # 3rd base
        $thirdBase = "3"+$baseOn
    }
    else {
        $thirdBase = "3"+$baseOff
    }

    $outs = switch ($mlb_linescore.outs) { # Use open and filled circle Unicode characters to indicate outs
        "0" {$outOff+""+$outOff}
        "1" {$outOn+""+$outOff}
        "2" {$outOn+""+$outOn}
        "3" {$outOn+""+$outOn}
        default {""} # This should never happen, but sports are weird
    }

    # Build current inning status line
    $rowS = "$InningState$curr_inning $balls-$strikes $firstBase$secondBase$thirdBase $outs  at $venue in $location"

    if ($mlb_pbp.currentPlay.result.description) {
        $rowP = $mlb_pbp.currentPlay.result.description
    }
    else { # Poll API to get current play-by-play info, and if there isn't any, build pitching and batting stats line for the current players
        $URI_pitcherhistorical = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.pitcher.id+"/stats?stats=season"
        $URI_pitchercurrent    = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.pitcher.id+"/stats/game/current/?group=pitching"
        $URI_batterhistorical  = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.batter.id+"/stats?stats=season"
        $URI_battercurrent     = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.batter.id+"/stats/game/current/?group=hitting"

        $pitcherhistorical = Invoke-RestMethod -Uri $URI_pitcherhistorical
        $pitchercurrent    = Invoke-RestMethod -Uri $URI_pitchercurrent
        $batterhistorical  = Invoke-RestMethod -Uri $URI_batterhistorical
        $battercurrent     = Invoke-RestMethod -Uri $URI_battercurrent

        $rowP  = $mlb_pbp.currentPlay.matchup.pitcher.fullName+" ("+$pitcherhistorical.stats.splits.stat.era+" ERA) pitching to "+$mlb_pbp.currentPlay.matchup.batter.fullName+" ("+$batterhistorical.stats.splits.stat.avg+"/"+$batterhistorical.stats.splits.stat.obp+"/"+$batterhistorical.stats.splits.stat.slg+")"
    }

    if ($debugOn) { # Write line score to the console if debugging is enabled
        write-host $rowI
        write-host $rowA
        write-host $rowH
        write-host $rowS
        write-host $rowP
    }

    if ($writeOutput) { # Write line score to text file for digestion by external apps if enabled
        $rowI | out-file -FilePath $filePath -encoding UTF8
        $rowA | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowH | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowS | out-file -FilePath $filePath -encoding UTF8 -Append
        $rowP | out-file -FilePath $filePath -encoding UTF8 -Append
    }
}

# Get initial timestamp from diffPatch so we're not polling the entire data set until it changes
$diffPatch = Invoke-RestMethod -Uri $URI_diffPatch
$newTime = $diffPatch.metaData.timeStamp
$startTime = $newTime

do { # Run script continuously while game is in session
    # Check game status
    $live = Invoke-RestMethod -Uri $URI_live
    $gameState = $live.gameData.status.abstractGameState

    if ($gameState -eq "Preview") { # If no game is active, output the next game time and date
        clear-host
        write-host $live.liveData.boxscore.teams.away.team.name "at" $live.liveData.boxscore.teams.home.team.name
        write-host "Game starts at" $live.gamedata.datetime.time$live.gamedata.datetime.ampm "ET on" $live.gamedata.datetime.originalDate
        $gameState = "Final" # Fake out the gameState so the loop ends
    }
    else {
        buildLinescore($filePath)

        do { # Optionally pause before polling diffPatch and continue to poll until a new event happens
            Start-Sleep -Second $diffDelay
            $URI_newDiff = $URI_diffPatch+"?startTimecode="+$startTime
            $newDiffPatch = Invoke-RestMethod -Uri $URI_newDiff
        } while (!$newDiffPatch)

        # Set most recent updated event timestamp to startTime for next iteration
        $newTime = $newdiffpatch.metadata.timeStamp
        $startTime = $newTime
    }
} while ($gameState -ne "Final") # Stop the script when the ballgame is over