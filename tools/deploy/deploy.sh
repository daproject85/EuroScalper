#!/usr/bin/env bash
set -euo pipefail
# Configure your MT4 Data Folder path here:
MT4_DATA="/Users/Rocky/.wine/drive_c/users/Rocky/AppData/Roaming/MetaQuotes/Terminal/604D1D52914D77A215EA00C3F2918DCC/MQL4"
# Copy compiled artifacts (and optionally sources)
echo "Deploying to $MT4_DATA ..."fo
mkdir -p "$MT4_DATA/Experts" "$MT4_DATA/Include"
# Example: copy rewrite EA mq4/ex4
# cp -v ../../src/rewrite/YourEA.mq4 "$MT4_DATA/Experts/"
# cp -v ../../src/include/logging/*.mqh "$MT4_DATA/Include/"
echo "Done. Edit this script to match your filenames and terminal path."
