echo off
set datesToFind="%~1"
echo Going to search for changesets on dates %datesToFind%

Powershell.exe -executionpolicy Unrestricted -NonInteractive -Command ". .\FindChangesets.ps1; FindChangeSets '"%~1"'"
pause
