#!/bin/bash
echo "Running tests for CarVilla web application"

if [ ! -f index.html ]; then
  echo "Error: index.html not found!"
  exit 1
fi

if [ ! -d assets ]; then
  echo "Error: assets directory not found!"
  exit 1
fi

if [ ! -f assets/js/custom.js ]; then
  echo "Error: custom.js not found!"
  exit 1
fi

if [ ! -f assets/css/style.css ]; then
  echo "Error: style.css not found!"
  exit 1
fi

echo "All tests passed successfully!"
exit 0
