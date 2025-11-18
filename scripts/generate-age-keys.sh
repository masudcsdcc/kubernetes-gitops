#!/bin/bash
echo "Generating Age keys for SOPS..."
age-keygen -o age-key.txt
echo "=== PUBLIC KEY (Save this for encryption) ==="
cat age-key.txt | grep "public" | cut -d: -f2 | tr -d ' '
echo "=== PRIVATE KEY (Keep this secure) ==="
cat age-key.txt | grep "private" | cut -d: -f2 | tr -d ' '
echo "Keys saved to age-key.txt"
