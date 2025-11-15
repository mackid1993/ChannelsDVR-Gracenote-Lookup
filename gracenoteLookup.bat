@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

:INIT
CLS
ECHO ========================================
ECHO Channels DVR Gracenote Lookup Tool
ECHO ========================================
ECHO.

REM Prompt for server IP
SET SERVER_IP=
SET /P SERVER_IP=Enter Channels DVR Server IP:
IF "%SERVER_IP%"=="" (
    ECHO Error: Server IP is required!
    GOTO INIT
)

REM Set standard port
SET SERVER_PORT=8089
1
SET SERVER_URL=http://%SERVER_IP%:%SERVER_PORT%
ECHO.
ECHO Using server: %SERVER_URL%
ECHO.

REM Create PowerShell script for searching
CALL :CREATE_POWERSHELL_SCRIPT

:MAIN_MENU
ECHO.
ECHO ========================================
ECHO Main Menu
ECHO ========================================
ECHO 1. Interactive Search Mode
ECHO 2. Batch File Processing
ECHO 3. Exit
ECHO.
SET CHOICE=
SET /P CHOICE=Select option (1-3):

IF "%CHOICE%"=="1" GOTO INTERACTIVE_MODE
IF "%CHOICE%"=="2" GOTO BATCH_MODE
IF "%CHOICE%"=="3" GOTO EXIT
ECHO Invalid choice, please try again.
GOTO MAIN_MENU

:INTERACTIVE_MODE
ECHO.
ECHO ========================================
ECHO Interactive Search Mode
ECHO ========================================
ECHO Type 'EXIT' to return to main menu
ECHO.

:INTERACTIVE_LOOP
SET CHANNEL_NAME=
SET /P CHANNEL_NAME=Enter channel name (or EXIT):

IF /I "%CHANNEL_NAME%"=="EXIT" GOTO MAIN_MENU
IF /I "%CHANNEL_NAME%"=="MENU" GOTO MAIN_MENU
IF "%CHANNEL_NAME%"=="" GOTO INTERACTIVE_LOOP

ECHO.
ECHO Searching for: %CHANNEL_NAME%
ECHO ----------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%_PSSCRIPT%" "%CHANNEL_NAME%" "%SERVER_URL%" ""
ECHO ----------------------------------------
ECHO.
GOTO INTERACTIVE_LOOP

:BATCH_MODE
ECHO.
ECHO ========================================
ECHO Batch File Processing Mode
ECHO ========================================
ECHO.

REM Prompt for input file
SET _INPUTFILE=
SET /P _INPUTFILE=Enter the path to the text file with channel names (one per line):

REM Check if file exists
IF NOT EXIST "%_INPUTFILE%" (
    ECHO Error: File "%_INPUTFILE%" not found!
    GOTO MAIN_MENU
)

REM Set output CSV filename
SET _OUTCSV=channel_ids.csv
ECHO Processing channels from "%_INPUTFILE%"
ECHO Output will be saved to "%_OUTCSV%"
ECHO.

REM Create CSV header
ECHO SearchTerm,Type,Name,CallSign,StationId,Logo > "%_OUTCSV%"

REM Process each line in the input file
FOR /F "usebackq delims=" %%C IN ("%_INPUTFILE%") DO (
    SET "_CHANNEL=%%C"
    ECHO.
    ECHO ========================================
    ECHO Processing: !_CHANNEL!
    ECHO ========================================
    powershell -NoProfile -ExecutionPolicy Bypass -File "%_PSSCRIPT%" "!_CHANNEL!" "%SERVER_URL%" "%_OUTCSV%"
)

ECHO.
ECHO ========================================
ECHO Processing complete!
ECHO Results saved to "%_OUTCSV%"
ECHO ========================================
ECHO.
PAUSE
GOTO MAIN_MENU

:CREATE_POWERSHELL_SCRIPT
SET _PSSCRIPT=%TEMP%\process_channel.ps1
ECHO param($channel, $serverUrl, $outputFile) > "%_PSSCRIPT%"
ECHO Add-Type -AssemblyName System.Web >> "%_PSSCRIPT%"
ECHO $stripped = $channel -replace '[^^a-zA-Z0-9]', '' >> "%_PSSCRIPT%"
ECHO $searchTerms = @() >> "%_PSSCRIPT%"
ECHO $searchTerms += $channel >> "%_PSSCRIPT%"
ECHO $searchTerms += $channel.ToLower() >> "%_PSSCRIPT%"
ECHO $searchTerms += $stripped >> "%_PSSCRIPT%"
ECHO $searchTerms += $stripped.ToLower() >> "%_PSSCRIPT%"
ECHO if ($stripped.Length -le 4) { >> "%_PSSCRIPT%"
ECHO     $baseName = $stripped.ToLower() >> "%_PSSCRIPT%"
ECHO     $searchTerms += $baseName + 'tv' >> "%_PSSCRIPT%"
ECHO     $searchTerms += $baseName + 'network' >> "%_PSSCRIPT%"
ECHO     $searchTerms += $baseName + 'hd' >> "%_PSSCRIPT%"
ECHO     $searchTerms += $baseName + 'channel' >> "%_PSSCRIPT%"
ECHO } >> "%_PSSCRIPT%"
ECHO $searchTerms = $searchTerms ^| Select-Object -Unique >> "%_PSSCRIPT%"
ECHO $allResults = @() >> "%_PSSCRIPT%"
ECHO foreach ($searchTerm in $searchTerms) { >> "%_PSSCRIPT%"
ECHO     $encoded = [System.Web.HttpUtility]::UrlEncode($searchTerm) >> "%_PSSCRIPT%"
ECHO     $url = $serverUrl + '/tms/stations/' + $encoded >> "%_PSSCRIPT%"
ECHO     Write-Host "Trying: $searchTerm" >> "%_PSSCRIPT%"
ECHO     try { >> "%_PSSCRIPT%"
ECHO         $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction SilentlyContinue >> "%_PSSCRIPT%"
ECHO         if ($response) { >> "%_PSSCRIPT%"
ECHO             $json = $response.Content ^| ConvertFrom-Json >> "%_PSSCRIPT%"
ECHO             if ($json) { $allResults += $json } >> "%_PSSCRIPT%"
ECHO         } >> "%_PSSCRIPT%"
ECHO     } catch { } >> "%_PSSCRIPT%"
ECHO } >> "%_PSSCRIPT%"
ECHO if ($allResults.Count -gt 0) { >> "%_PSSCRIPT%"
ECHO     Write-Host "" >> "%_PSSCRIPT%"
ECHO     Write-Host "Found $($allResults.Count) total results:" >> "%_PSSCRIPT%"
ECHO     $uniqueResults = $allResults ^| Group-Object -Property stationId ^| ForEach-Object { $_.Group[0] } >> "%_PSSCRIPT%"
ECHO     Write-Host "Showing all $($uniqueResults.Count) unique results" >> "%_PSSCRIPT%"
ECHO     Write-Host "" >> "%_PSSCRIPT%"
ECHO     $uniqueResults ^| Sort-Object type, name ^| ForEach-Object { >> "%_PSSCRIPT%"
ECHO         Write-Host "  [$($_.type)] $($_.name) - $($_.callSign) - StationID: $($_.stationId)" >> "%_PSSCRIPT%"
ECHO         if ($outputFile -ne '') { >> "%_PSSCRIPT%"
ECHO             $st = $channel -replace ',', ';' >> "%_PSSCRIPT%"
ECHO             $nm = $_.name -replace ',', ';' >> "%_PSSCRIPT%"
ECHO             $cs = if ($_.callSign) { $_.callSign -replace ',', ';' } else { '' } >> "%_PSSCRIPT%"
ECHO             $lg = if ($_.preferredImage.uri) { $_.preferredImage.uri } else { '' } >> "%_PSSCRIPT%"
ECHO             "$st,$($_.type),$nm,$cs,$($_.stationId),$lg" ^| Out-File -FilePath $outputFile -Encoding utf8 -Append >> "%_PSSCRIPT%"
ECHO         } >> "%_PSSCRIPT%"
ECHO     } >> "%_PSSCRIPT%"
ECHO } else { >> "%_PSSCRIPT%"
ECHO     Write-Host 'No results found' >> "%_PSSCRIPT%"
ECHO } >> "%_PSSCRIPT%"
GOTO :EOF

:EXIT
REM Cleanup
DEL "%_PSSCRIPT%" 2>NUL
ECHO.
ECHO Goodbye!
EXIT /B
