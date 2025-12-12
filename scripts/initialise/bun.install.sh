# Install Bun only if it's not installed
if ! command -v bun >/dev/null 2>&1; then
    echo "Bun not found. Installing..."
    curl -fsSL https://bun.sh/install | bash
else
    echo "Bun is already installed."
fi
