# MLBlinescore
Powershell app to pull data from the MLB API in order to build a linescore that can then be added to an OBS stream

    .EXAMPLE
    ───────────┬─ 1 ┬─ 2 ┬─ 3 ┬─ 4 ┬─ 5 ┬─ 6 ┬─ 7 ╥─ R ┬─ H ┬─ E ╖
    ATL (.602) │  1 │  0 │  0 │  2 │  0 │  0 │    ║  3 │  5 │  0 ║ 
    NYM (.528) │  3 │  0 │  0 │  0 │  0 │  0 │    ║  3 │  7 │  0 ║
    ▲7th  1-2  1◆  2◇  3◇  ⚫⚫⚪  at  Citi Field in New York
    Noah Syndergaard (4.29 ERA) pitching to Dansby Swanson (.251/.325/.423) 
