#!/bin/bash

# Test Voice API Endpoints on Raspberry Pi
# Run this script to verify voice endpoints are working

echo "🧪 Testing Voice API Endpoints"
echo "=============================="

# Get Pi IP address
PI_IP=$(hostname -I | awk '{print $1}')
echo "📍 Pi IP Address: $PI_IP"
echo ""

# Test each endpoint
endpoints=(
    "status:Network Status"
    "devices:Device Information"
    "aps:Access Point Data"
    "events:Recent Events"
)

for endpoint_info in "${endpoints[@]}"; do
    IFS=':' read -r endpoint description <<< "$endpoint_info"
    
    echo "🔍 Testing $description (/api/voice/$endpoint)"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "http://$PI_IP/api/voice/$endpoint")
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    if [ "$http_code" -eq 200 ]; then
        echo "✅ Success (HTTP $http_code)"
        # Pretty print JSON if jq is available
        if command -v jq &> /dev/null; then
            echo "$body" | jq -r '. | keys[]' | head -5 | sed 's/^/   📊 /'
        else
            echo "   📊 Response received (install jq for pretty formatting)"
        fi
    else
        echo "❌ Failed (HTTP $http_code)"
        echo "   Error: $body"
    fi
    echo ""
done

# Test dashboard health
echo "🏥 Testing Dashboard Health"
health_response=$(curl -s -w "HTTPSTATUS:%{http_code}" "http://$PI_IP/health")
health_code=$(echo "$health_response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

if [ "$health_code" -eq 200 ]; then
    echo "✅ Dashboard is healthy"
else
    echo "❌ Dashboard health check failed (HTTP $health_code)"
fi

echo ""
echo "📋 Summary:"
echo "   🏠 Pi IP: $PI_IP"
echo "   🎤 Voice endpoints: http://$PI_IP/api/voice/"
echo "   🔧 Dashboard: http://$PI_IP/"
echo ""
echo "🗣️  Ready for Echo commands like:"
echo "   'Alexa, ask Eero Dashboard how many devices are connected'"