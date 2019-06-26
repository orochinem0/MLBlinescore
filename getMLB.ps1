# Includes
. "$PSScriptRoot\cMLB.ps1" # Config file

# The data that sets the wheels into motion - team and date
# You can pick a past date to get a specific game's final outcome
# However, this code is not intended to iterate through a past game
# The intended use is to determine the current day and date and let the script iterate over a live game a specific team is playing
# It should stop when the live game is over
# If the game is upcoming, it should output the teams playing and when the game will start
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
    <#

    .SYNOPSIS
    Outputs a formatted baseball linescore using live API data from MLB

    .DESCRIPTION
    Using live MLB API data, parses the data into tokens and arranges into a text-based linescore, which can then be written to the console or to a text file for digestion by another application, such as an OBS stream

    .EXAMPLE
               ││  1 │  2 │  3 │  4 │  5 │  6 ││  R │  H │  E ││
    NYM (.468) ││  2 │  1 │  1 │  0 │  0 │  1 ││  5 │  9 │  0 ││ 
    PHI (.513) ││  1 │  0 │  0 │  1 │  0 │    ││  2 │  4 │  2 ││
    ▼6th 1-1 1◆2◇3◇ ⚫⚪  at Citizens Bank Park in Philadelphia
    Rhys Hoskins pops out to catcher Wilson Ramos in foul territory.  

    .NOTES
    Not using proper OOP so far

    .PARAMETER outputfile
    Path to a writeable text file. No validation is made on this step

    #>

    # Start by building the front part of the line score
    $abbr_away = $mlb_boxscore.teams.away.team.abbreviation
    $abbr_home = $mlb_boxscore.teams.home.team.abbreviation
    if ($abbr_away.length -lt 3) { $abbr_away += " " } # Pad shorter team abbreviations
    if ($abbr_home.length -lt 3) { $abbr_home += " " }

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

    for ($i=0; $i -lt $mlb_linescore.currentInning; $i++) { # Iterate thru the innings and build the line score
        $runsA = $mlb_linescore.innings[$i].away.runs
        $runsH = $mlb_linescore.innings[$i].home.runs

        # Write individual inning data
        $rowA += "$delimiter"
        if ($runsA -lt 10) { $rowA += " " } # Pad short numbers
        if ($i -gt 9) { $rowA += " "} # Pad extra innings
        if ($runsA -eq $null) { $rowA += "   " }
        else { $rowA += " $runsA " }

        $rowH += "$delimiter"
        if ($runsH -lt 10) { $rowH += " " }
        if ($i -gt 9) { $rowH += " "}
        if ($runsH -eq $null) { $rowH += "   " }
        else { $rowH += " $runsH " }

        $rowI += "$delimiter  "+($i+1)+" "
    }

    # Write runs, hits, and errors data with proper spacing
    $rowI += "$delimiter$delimiter  R $delimiter  H $delimiter  E $delimiter$delimiter"

    # Away
    $rowA += "$delimiter$delimiter "
    if ($away_runs -lt 10) { $rowA += " " }
    if ($away_runs -eq $null) { $rowA += " " }
    $rowA += "$away_runs $delimiter "

    if ($away_hits -lt 10) { $rowA += " " }
    if ($away_hits -eq $null) { $rowA += " " }
    $rowA += "$away_hits $delimiter "

    if ($away_errs -lt 10) { $rowA += " " }
    if ($away_errs -eq $null) { $rowA += " " }
    $rowA += "$away_errs $delimiter$delimiter"
    if ($away_runs -lt 10) { $rowA += " " }

    # Home Runs
    $rowH += "$delimiter$delimiter "
    if ($home_runs -lt 10) { $rowH += " " }
    if ($home_runs -eq $null) { $rowH += " " }
    $rowH += "$home_runs $delimiter "

    if ($home_hits -lt 10) { $rowH += " " }
    if ($home_hits -eq $null) { $rowH += " " }
    $rowH += "$home_hits $delimiter "

    if ($home_errs -lt 10) { $rowH += " " }
    if ($home_errs -eq $null) { $rowH += " " }
    $rowH += "$home_errs $delimiter$delimiter"

    $inningState = switch ($mlb_linescore.inningState) { # Shapes defined in config
        "Top"    { $top }
        "Bottom" { $bottom }
        "Middle" { $middle }
        default  { "" } # Any other inning status is blank
    }

    # Shapes defined in config
    if ($MLB_linescore.offense.first) { $firstBase = "1"+$baseOn }
    else { $firstBase = "1"+$baseOff }

    if ($MLB_linescore.offense.second) { $secondBase = "2"+$baseOn }
    else { $secondBase = "2"+$baseOff }

    if ($MLB_linescore.offense.third) { $thirdBase = "3"+$baseOn }
    else { $thirdBase = "3"+$baseOff }

    $outs = switch ($mlb_linescore.outs) { # Shapes defined in config
        "0" { $outOff+""+$outOff }
        "1" { $outOn+""+$outOff }
        "2" { $outOn+""+$outOn }
        "3" { $outOn+""+$outOn }
        default { "" } # This should never happen, but sports are weird
    }

    # Build current inning status line
    $rowS = $InningState+$mlb_linescore.currentInningOrdinal+" "+$mlb_linescore.balls+"-"+$mlb_linescore.strikes+" "+$firstBase+$secondBase+$thirdBase+" "+$outs+"  at "+$mlb_boxscore.teams.home.team.venue.name+" in "+$mlb_boxscore.teams.home.team.locationName

    if ($mlb_pbp.currentPlay.result.description) { $rowP = $mlb_pbp.currentPlay.result.description }
    else { # Poll API to get current play-by-play info, and if there isn't any, build pitching and batting stats line for the current players
        $URI_batterstats   = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.batter.id+"/stats/?stats=career&group=hitting&season=2019"
        $URI_pitcherstats  = $MLB_URL+"/api/v1/people/"+$mlb_pbp.currentPlay.matchup.pitcher.id+"/stats?stats=career&group=pitching&season=2019"

        $batterstats  = Invoke-RestMethod -Uri $URI_batterstats
        $pitcherstats = Invoke-RestMethod -Uri $URI_pitcherstats

        $rowP  = $mlb_pbp.currentPlay.matchup.pitcher.fullName+" ("+$pitcherstats.stats.splits.stat.era+" ERA) pitching to "+$mlb_pbp.currentPlay.matchup.batter.fullName+" ("+$batterstats.stats.splits.stat.avg+"/"+$batterstats.stats.splits.stat.obp+"/"+$batterstats.stats.splits.stat.slg+")"
    }

    if ($debugOn) { # Write line score to the console if debugging is enabled
        clear-host
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
$startTime = $diffPatch.metaData.timeStamp

do { # Run script continuously while game is Live
    # Get game state
    $live = Invoke-RestMethod -Uri $URI_live
    $gameState = $live.gameData.status.abstractGameState

    if ($gameState -eq "Preview") { # If no game is Live or Finished, output the next game start time and date
        $mlbtz = $live.gamedata.venue.timezone.tz # Using the venue local time zone, determine the user local time for the game start
        $mlboffset = $live.gamedata.venue.timezone.offset
        $timediff = $mlboffset - $locoffset
        $hr,$mn = $live.gamedata.datetime.time.split(':')
        $hr -= $timediff-1 # Uh...will explain this later

        $row1 = $live.liveData.boxscore.teams.away.team.name+" at "+$live.liveData.boxscore.teams.home.team.name
        $row2 = "Game starts at "+$hr+":"+$mn+" "+$live.gamedata.datetime.ampm+" "+$loctz+" "+$live.gamedata.datetime.originalDate

        if ($debugOn) { # Write pre-game info to console
            clear-host
            write-host $row1
            write-host $row2
        }
        if ($writeOutput) { # Write pre-game info to file
            $row1 | out-file -FilePath $filePath -encoding UTF8
            $row2 | out-file -FilePath $filePath -encoding UTF8 -Append
        }
        $gameState = "Final" # Fake out the gameState so the loop ends
    }
    elseif (($gameState -eq "Live") -or ($gameState -eq "Final")) { 
        $mlb_boxscore  = Invoke-RestMethod -Uri $URI_boxscore
        $mlb_linescore = Invoke-RestMethod -Uri $URI_linescore
        $mlb_pbp       = Invoke-RestMethod -Uri $URI_pbp

        buildLinescore($filePath) # Build a linescore from current or historical data

        if ($gameState -eq "Live") {
            do { # Poll DiffPatch for updated data before running thru the entire loop again
                Start-Sleep -Second $diffDelay
                $URI_newDiff = $URI_diffPatch+"?startTimecode="+$startTime
                $newDiffPatch = Invoke-RestMethod -Uri $URI_newDiff
            } while (!$newDiffPatch)

            # Set most recent updated event timestamp to startTime for next iteration
            $startTime = $newdiffpatch.metadata.timeStamp
        }
    }
} while ($gameState -ne "Final") # Stop the script when the ballgame is over