<#
.SYNOPSIS
Using the MLB API, grab live data and build a summary in the style of a line score

.DESCRIPTION

.EXAMPLE

.NOTES
This is meant to iterate over a live game, not a historical one. It only displays the most recent event.

.PARAMETER filePath
Path to write file. Default is my own local.

.PARAMETER debugOn
Write to console while running if true

.PARAMETER writeOutput
Write to file location defined above if true

.PARAMETER verbose
Output verbose logging to the console

#>

[CmdletBinding()]
Param (
    $filePath          = 'C:\Users\yt\Documents\Twitch Assets\mlbscore.txt',
    [bool]$debugOn     = $true,
    [bool]$writeOutput = $true
)

# Includes
. "$PSScriptRoot\cMLB.ps1" # Config file

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
$URI_live    = $MLB_URL+"/api/v1.1/game/"+$mlb_gamekey+"/feed/live/"
$URI_newDiff = $URI_live+"?fields=metaData%2CtimeStamp"

function buildLinescore ([PSObject]$live,[string]$outputfile) { # This is where the magic happens
    <#

    .SYNOPSIS
    Outputs a formatted baseball linescore using live API data from MLB

    .DESCRIPTION
    Using live MLB API data, parses the data into tokens and arranges into a text-based linescore, which can then be written to the console or to a text file for digestion by another application, such as an OBS stream

    .EXAMPLE
───────────┬─ 1 ┬─ 2 ┬─ 3 ┬─ 4 ┬─ 5 ┬─ 6 ┬─ 7 ╥─ R ┬─ H ┬─ E ╖
ATL (.602) │  1 │  0 │  0 │  2 │  0 │  0 │    ║  3 │  5 │  0 ║ 
NYM (.528) │  3 │  0 │  0 │  0 │  0 │  0 │    ║  3 │  7 │  0 ║
▲7th  1-2  1◆  2◇  3◇  ⚫⚫⚪  at  Citi Field in New York
Noah Syndergaard (4.29 ERA) pitching to Dansby Swanson (.251/.325/.423) 

    .NOTES
    Not using proper OOP so far

    .PARAMETER live
    Array of live data from the MLB AP

    .PARAMETER outputfile
    Path to a writeable text file. No validation is made on this step

    #>

    # Start by building the front part of the line score
    $abbr_away = $live.gameData.teams.away.abbreviation
    $abbr_home = $live.gameData.teams.home.abbreviation
    if ($abbr_away.length -lt 3) { $abbr_away += " " } # Pad shorter team abbreviations
    if ($abbr_home.length -lt 3) { $abbr_home += " " }

    # Add win/loss percentage to team names
    $away_record = $live.gameData.teams.away.record.winningPercentage
    $home_record = $live.gameData.teams.home.record.winningPercentage

    # Capture the RHE data for both teams
    $away_runs = $live.liveData.linescore.teams.away.runs
    $away_hits = $live.liveData.linescore.teams.away.hits
    $away_errs = $live.liveData.linescore.teams.away.errors

    $home_runs = $live.liveData.linescore.teams.home.runs
    $home_hits = $live.liveData.linescore.teams.home.hits
    $home_errs = $live.liveData.linescore.teams.home.errors

    # Build the front for each row in the line score
    $rowI = "$line$line$line$line$line$line$line$line$line$line$line"
    $rowA = "$abbr_away ($away_record) "
    $rowH = "$abbr_home ($home_record) "

    for ($i=0; $i -lt $live.liveData.linescore.currentInning; $i++) { # Iterate thru the innings and build the line score
        $runsA = $live.liveData.linescore.innings[$i].away.runs
        $runsH = $live.liveData.linescore.innings[$i].home.runs

        # Write individual inning data
        $rowA += "$delimiter"
        if ($runsA -lt 10) { $rowA += " " } # Pad short numbers
        if ($i -gt 8) { $rowA += " "} # Pad extra innings
        if ($runsA -eq $null) { $rowA += "   " }
        else { $rowA += " $runsA " }

        $rowH += "$delimiter"
        if ($runsH -lt 10) { $rowH += " " }
        if ($i -gt 8) { $rowH += " "}
        if ($runsH -eq $null) { $rowH += "   " }
        else { $rowH += " $runsH " }

        $rowI += "$ttop$line "+($i+1)+" "
    }

    # Write runs, hits, and errors data with proper spacing
    $rowI += "$dbltop$line R $ttop$line H $ttop$line E $dblL"

    # Away
    $rowA += "$dblline "
    if ($away_runs -lt 10) { $rowA += " " }
    if ($away_runs -eq $null) { $rowA += " " }
    $rowA += "$away_runs $delimiter "

    if ($away_hits -lt 10) { $rowA += " " }
    if ($away_hits -eq $null) { $rowA += " " }
    $rowA += "$away_hits $delimiter "

    if ($away_errs -lt 10) { $rowA += " " }
    if ($away_errs -eq $null) { $rowA += " " }
    $rowA += "$away_errs $dblline"
    if ($away_runs -lt 10) { $rowA += " " }

    # Home Runs
    $rowH += "$dblline "
    if ($home_runs -lt 10) { $rowH += " " }
    if ($home_runs -eq $null) { $rowH += " " }
    $rowH += "$home_runs $delimiter "

    if ($home_hits -lt 10) { $rowH += " " }
    if ($home_hits -eq $null) { $rowH += " " }
    $rowH += "$home_hits $delimiter "

    if ($home_errs -lt 10) { $rowH += " " }
    if ($home_errs -eq $null) { $rowH += " " }
    $rowH += "$home_errs $dblline"

    $inningState = switch ($live.liveData.linescore.inningState) { # Shapes defined in config
        "Top"    { $top }
        "Bottom" { $bottom }
        "Middle" { $middle }
        default  { "  " } # Any other inning status is blank
    }

    # Shapes defined in config
    if ($live.liveData.linescore.offense.first) { $firstBase = "1"+$baseOn }
    else { $firstBase = "1"+$baseOff }

    if ($live.liveData.linescore.offense.second) { $secondBase = "2"+$baseOn }
    else { $secondBase = "2"+$baseOff }

    if ($live.liveData.linescore.offense.third) { $thirdBase = "3"+$baseOn }
    else { $thirdBase = "3"+$baseOff }

    $outs = switch ($live.liveData.linescore.outs) { # Shapes defined in config
        "0" { $outOff+""+$outOff+""+$outOff }
        "1" { $outOn+""+$outOff+""+$outOff }
        "2" { $outOn+""+$outOn+""+$outOff }
        "3" { $outOn+""+$outOn+""+$outOn }
        default { "  " } # This should never happen, but sports are weird
    }

    # Build current inning status line
    # Pad inning numbers if needed
    $rowS = $InningState+$live.liveData.linescore.currentInningOrdinal+"  "+$live.liveData.linescore.balls+"-"+$live.liveData.linescore.strikes+"  "+$firstBase+"  "+$secondBase+"  "+$thirdBase+"  "+$outs+"  at  "+$live.gameData.teams.home.venue.name+" in "+$live.gameData.teams.home.locationName

    $currentPlay = $live.liveData.plays.currentPlay.result.description

    if ($currentPlay) { # Break the play-by-play row if it's long
        $tempArray = ($currentPlay.substring(0,$currentPlay.length)) -split "\s+" # Kill any excess whitespace
        $rowP = "" # Zero the play-by-play row in case it has kruft
        for ($i = 0; $i -lt $tempArray.length; $i++) { $rowP += $tempArray[$i]+" " } # Rebuild with appropriate spacing

    }
    else { # Poll API to get current play-by-play info, and if there isn't any, build pitching and batting stats line for the current players        
        $pitcherID  = "ID"+$live.liveData.plays.currentPlay.matchup.pitcher.id
        if ($live.liveData.boxscore.teams.home.players.$pitcherID) { $pitcherState = "home" } else { $pitcherState = "away" }
        $ERA        = $live.liveData.boxscore.teams.$pitcherState.players.$pitcherID.seasonStats.pitching.era 
        $IP         = $live.liveData.boxscore.teams.$pitcherState.players.$pitcherID.stats.pitching.inningsPitched
        $pitchCount = $live.liveData.boxscore.teams.$pitcherState.players.$pitcherID.stats.pitching.numberOfPitches

        $batterID = "ID"+$live.liveData.plays.currentPlay.matchup.batter.id
        if ($live.liveData.boxscore.teams.home.players.$batterID) { $batterState = "home" } else { $batterState = "away" }
        $AVG      = $live.liveData.boxscore.teams.$batterState.players.$batterID.seasonStats.batting.avg
        $OBP      = $live.liveData.boxscore.teams.$batterState.players.$batterID.seasonStats.batting.obp
        $SLG      = $live.liveData.boxscore.teams.$batterState.players.$batterID.seasonStats.batting.slg

        $rowP = $live.liveData.plays.currentPlay.matchup.pitcher.fullName+" ("+$ERA+" ERA) pitching to "+$live.liveData.plays.currentPlay.matchup.batter.fullName+" ("+$AVG+"/"+$OBP+"/"+$SLG+")"
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
        $rowLength = $rowI.length
        if ($rowLength -lt $lineMax) { $rowLength = $lineMax }
        if ($rowP.length -gt $rowLength) {
            # Split play description into two lines if it's longer than the line score
            $tempArray = ($rowP.substring(0,$rowLength)) -split "\s+"
            for ($i = 0; $i -lt $tempArray.length-1; $i++) { $rowO += $tempArray[$i]+" " }
            $rowO | out-file -FilePath $filePath -encoding UTF8 -Append
            $rowP = $rowP.substring($rowO.length,$rowP.length-$rowO.length)
        }
        $rowP | out-file -FilePath $filePath -encoding UTF8 -Append
    }
}

# Get initial data
$liveData = Invoke-RestMethod -Uri $URI_live

do { # Run script continuously while game is Live
    # Get game state
    $gameState = $liveData.gameData.status.abstractGameState
    $wait      = $liveData.metadata.wait

    if ($gameState -eq "Preview") { # If is neither Live nor Finished, output the next game start time and date
        $mlboffset = $liveData.gamedata.venue.timezone.offset
        $timediff = $locoffset - $mlboffset # Get the time difference
        $hr,$mn = $liveData.gamedata.datetime.time.split(':')
        $startTime = ""+$hr+":"+$mn+$liveData.gamedata.datetime.ampm # Reassemble into a digestable time format
        $startTimeObj = [datetime]::parseexact($startTime, 'h:mmtt', $null) # Make it into a time object for magic time math
        $startTimeObj = $startTimeObj.AddHours($timediff+1)
        $startTime = $startTimeObj.ToString('hh:mm tt')

        # Use the local time to edit scheduled task to run this script again when the game starts
        # Another scheduled task will run this script at one minute after midnight every day to get the schedule
        $trigger = New-ScheduledTaskTrigger -At $startTime -Once
        Set-ScheduledTask -TaskName "Run MLB Linescore" -Trigger $trigger

        $row1 = $liveData.liveData.boxscore.teams.away.team.name+" at "+$liveData.liveData.boxscore.teams.home.team.name
        $row2 = "Game starts at "+$startTime+" "+$loctz

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
    elseif (($gameState -eq "Live") -or ($gameState -eq "Final")) { # If there is game data, play ball!
        $liveData = Invoke-RestMethod -Uri $URI_live

        buildLinescore($liveData,$filePath) # Build a linescore from API data

        if ($gameState -eq "Live") {
            do { # Poll DiffPatch for updated data before running thru the entire loop again
                Start-Sleep -Second $wait
                $newDiffPatch = Invoke-RestMethod -Uri $URI_newDiff
            } while ($newDiffPatch.metadata.timeStamp -eq $startTime)

            # Set most recent updated event timestamp to startTime for next iteration
            $startTime = $newdiffpatch.metadata.timeStamp
        }
    }
} while ($gameState -ne "Final") # Stop the script when the ballgame is over