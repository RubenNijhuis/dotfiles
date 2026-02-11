#!/usr/bin/env bash
# Display SSH key information and status

echo "SSH Public Keys:"
echo "================"
for key in ~/.ssh/*.pub; do
    if [[ -f "$key" ]]; then
        echo ""
        echo "$(basename "$key"):"
        ssh-keygen -lf "$key"
    fi
done

echo ""
echo "Keys in SSH Agent:"
echo "=================="
ssh-add -l 2>/dev/null || echo "No keys loaded in agent"

echo ""
echo "SSH Configuration:"
echo "=================="
echo "Config file: ~/.ssh/config"
echo "Test with: ssh -G github.com"
