#!/bin/bash

# Detect OS
OS_TYPE="$(uname -s)"

# Check for Python
if ! command -v python3 &>/dev/null; then
    echo "❌ python3 is not installed or not in PATH."
    exit 1
fi

# Check for pip
if ! command -v pip3 &>/dev/null; then
    echo "❌ pip3 is not installed. Please install pip for Python 3."
    exit 1
fi

# Ensure virtualenv is installed (locally if needed)
if ! python3 -m virtualenv --version &>/dev/null; then
    echo "📦 Installing virtualenv locally (no root)..."
    pip3 install --user virtualenv
    export PATH="$HOME/.local/bin:$PATH"
fi

# Set venv directory
VENV_DIR="venv"

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "🔧 Creating virtual environment using virtualenv..."
    python3 -m virtualenv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment."
        exit 1
    fi
else
    echo "✅ Virtual environment already exists at ./$VENV_DIR"
fi

# Activate (cross-platform)
echo "⚙️ Activating virtual environment..."
if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
    source "$VENV_DIR/bin/activate"
elif [[ "$OS_TYPE" == *"MINGW"* || "$OS_TYPE" == *"MSYS"* || "$OS_TYPE" == *"CYGWIN"* ]]; then
    source "$VENV_DIR/Scripts/activate"
else
    echo "❌ Unsupported OS: $OS_TYPE"
    exit 1
fi

# Install dependencies if available
if [ ! -f "requirements.txt" ]; then
    echo "⚠️ requirements.txt not found. Skipping installation."
else
    echo "📦 Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
fi

echo ""
echo "✅ Setup complete!"
echo "To activate the virtual environment, run:"
echo ""
echo "    source venv/bin/activate"
echo ""
echo "Then you can run your Python scripts like:"
echo ""
echo "    python src/access_control.py "
echo ""
echo " To deactivate the virtual environment,, run:"
echo ""
echo "    deactivate"