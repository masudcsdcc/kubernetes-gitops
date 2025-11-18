#!/bin/bash

echo "=== EXPORTING GRAFANA DASHBOARD ==="

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Port forward to Grafana
echo "Setting up port forward to Grafana..."
kubectl port-forward -n monitoring svc/grafana 3000:80 &
PORT_FORWARD_PID=$!

# Wait for port forward to establish
sleep 5

# Export dashboard using Grafana API
echo "Exporting WordPress dashboard..."
curl -s -u admin:admin http://localhost:3000/api/search?query=WordPress | jq . > /tmp/dashboards-list.json

# Get the dashboard UID
DASHBOARD_UID=$(curl -s -u admin:admin http://localhost:3000/api/search?query=WordPress | jq -r '.[0]?.uid')

if [ "$DASHBOARD_UID" != "null" ] && [ ! -z "$DASHBOARD_UID" ]; then
    # Export the dashboard
    curl -s -u admin:admin http://localhost:3000/api/dashboards/uid/$DASHBOARD_UID | jq '.dashboard' > exported-wordpress-dashboard.json
    echo "Dashboard exported to: exported-wordpress-dashboard.json"
else
    # Create dashboard manually if not found
    echo "Dashboard not found via API, creating export from template..."
    cat > exported-wordpress-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "WordPress Logs Dashboard",
    "tags": ["wordpress", "logs", "loki"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "WordPress Log Stream",
        "type": "logs",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "{namespace=\"wordpress\", container=\"wordpress\"}",
            "refId": "A",
            "queryType": "range"
          }
        ],
        "options": {
          "showTime": true,
          "wrapLogMessage": true,
          "sortOrder": "Descending",
          "enableLogDetails": true,
          "prettifyLogMessage": true,
          "showCommonLabels": false,
          "showLabels": false
        },
        "gridPos": {
          "h": 20,
          "w": 24,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Log Volume - WordPress",
        "type": "logs",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "sum by (container) (rate({namespace=\"wordpress\"} |~ \".\" [1m]))",
            "refId": "A",
            "queryType": "range"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 20
        },
        "renderer": "flamegraph"
      },
      {
        "id": 3,
        "title": "Error Logs Count",
        "type": "stat",
        "datasource": "Loki",
        "targets": [
          {
            "expr": "count_over_time({namespace=\"wordpress\"} |~ \"error|ERROR|Error\" [5m])",
            "refId": "A",
            "queryType": "range"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 20
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "templating": {
      "list": [
        {
          "name": "namespace",
          "type": "query",
          "datasource": "Loki",
          "query": "label_values(namespace)"
        },
        {
          "name": "pod",
          "type": "query",
          "datasource": "Loki",
          "query": "label_values(pod)"
        }
      ]
    },
    "refresh": "5s"
  }
}
EOF
    echo "Dashboard template exported to: exported-wordpress-dashboard.json"
fi

# Kill port forward
kill $PORT_FORWARD_PID

echo "=== DASHBOARD EXPORT COMPLETE ==="
