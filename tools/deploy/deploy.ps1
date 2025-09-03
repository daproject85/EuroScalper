Param(
  [string]$Mt4Data = "$env:APPDATA\MetaQuotes\Terminal\<YOUR_TERMINAL_HASH>\MQL4"
)
Write-Host "Deploying to $Mt4Data ..."
New-Item -ItemType Directory -Force -Path "$Mt4Data\Experts" | Out-Null
New-Item -ItemType Directory -Force -Path "$Mt4Data\Include" | Out-Null
# Example: copy rewrite EA mq4/ex4
# Copy-Item -Force "..\..\src\rewrite\YourEA.mq4" "$Mt4Data\Experts\"
# Copy-Item -Force "..\..\src\include\logging\*.mqh" "$Mt4Data\Include\"
Write-Host "Done. Edit this script to match your filenames and terminal path."
