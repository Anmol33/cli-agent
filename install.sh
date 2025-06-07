#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing CLI Agent...${NC}"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is required but not installed. Please install Python 3 first."
    exit 1
fi

# Create virtual environment
echo -e "${BLUE}Creating virtual environment...${NC}"
python3 -m venv venv

# Activate virtual environment
echo -e "${BLUE}Activating virtual environment...${NC}"
source venv/bin/activate

# Install the package in development mode
echo -e "${BLUE}Installing CLI Agent...${NC}"
pip install -e .

# Create default config if it doesn't exist
if [ ! -f config.yaml ]; then
    echo -e "${BLUE}Creating default configuration...${NC}"
    cat > config.yaml << EOL
# CLI Agent Configuration

# Amazon Bedrock settings
bedrock:
  model: "anthropic.claude-v2"
  temperature: 0.7
  max_tokens: 150
  region: "us-west-2"
  aws_access_key_id: "YOUR_AWS_ACCESS_KEY"
  aws_secret_access_key: "YOUR_AWS_SECRET_KEY"

# Command history settings
history:
  max_entries: 1000
  save_to_file: true
  history_file: ".cli_history"

# UI settings
ui:
  prompt: "🤖 > "
  error_color: "red"
  success_color: "green"
  info_color: "blue"
  warning_color: "yellow"

# Command execution settings
execution:
  timeout: 30  # seconds
  max_retries: 3
  confirm_dangerous_commands: true

# Logging settings
logging:
  level: "INFO"
  file: "cli_agent.log"
  max_size: 10485760  # 10MB
  backup_count: 5
EOL
fi

# Create an alias in .bashrc or .zshrc
SHELL_RC="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

# Add alias if it doesn't exist
if ! grep -q "alias cli-agent=" "$SHELL_RC"; then
    echo -e "${BLUE}Adding CLI Agent alias to $SHELL_RC...${NC}"
    echo "alias cli-agent='source $(pwd)/venv/bin/activate && cli-agent'" >> "$SHELL_RC"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Please update your AWS credentials in config.yaml${NC}"
echo -e "${BLUE}To use CLI Agent, either:${NC}"
echo -e "1. Run 'source $SHELL_RC' to update your current shell"
echo -e "2. Open a new terminal and type 'cli-agent'"
echo -e "3. Or run 'source venv/bin/activate && cli-agent' from this directory" 