#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./run_loadtest.sh <environment>"
    exit 1
fi

ENV=$1
cd ../terraform
API_URL=$(terraform output -raw api_endpoint)

cd ../src/loadtest

echo "Running load test against $API_URL"
# Runs locust in headless mode for 1 minute with 10 users
locust -f locustfile.py --headless -u 10 -r 2 -t 1m --host "$API_URL" --html report.html

echo "Load test complete. Report saved to src/loadtest/report.html"
