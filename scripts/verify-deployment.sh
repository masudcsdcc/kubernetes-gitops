#!/bin/bash

echo "=== VERIFYING GITOPS DEPLOYMENT ==="

# Check FluxCD status
echo "1. FluxCD Status:"
flux get kustomizations
flux get sources git

# Check all namespaces
echo ""
echo "2. Namespaces:"
kubectl get ns

# Check pods
echo ""
echo "3. Pods Status:"
kubectl get pods -A

# Check services
echo ""
echo "4. Services:"
kubectl get svc -A | grep -v kube-system

# Check ingress
echo ""
echo "5. Ingress:"
kubectl get ingress -A

# Get external IP
echo ""
echo "6. Getting External IP:"
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"

# Update /etc/hosts
echo ""
echo "7. Updating /etc/hosts:"
sudo sed -i '/app\.local/d' /etc/hosts
sudo sed -i '/app-monitor\.local/d' /etc/hosts
echo "$EXTERNAL_IP app.local" | sudo tee -a /etc/hosts
echo "$EXTERNAL_IP app-monitor.local" | sudo tee -a /etc/hosts

# Test WordPress
echo ""
echo "8. Testing WordPress:"
curl -s -H "Host: app.local" http://$EXTERNAL_IP | grep -i "wordpress" | head -1 || echo "Testing WordPress access..."

# Test 404 redirect
echo ""
echo "9. Testing 404 Redirect:"
curl -I -H "Host: app.local" http://$EXTERNAL_IP/notfound

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo "WordPress: http://app.local"
echo "Test 404: http://app.local/notfound (should redirect to google.com)"
