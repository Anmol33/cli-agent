#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Welcome to CLI Agent Installation!${NC}"
echo -e "${BLUE}This script will help you set up the CLI Agent with your preferred AI provider.${NC}"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

# Check Python version
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
python_major=$(echo $python_version | cut -d. -f1)
python_minor=$(echo $python_version | cut -d. -f2)

if [ "$python_major" -lt 3 ] || ([ "$python_major" -eq 3 ] && [ "$python_minor" -lt 8 ]); then
    echo -e "${RED}Python version $python_version is not supported. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

# Create and activate virtual environment
echo -e "\n${BLUE}Setting up virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate

# Create requirements.txt with all dependencies
echo -e "\n${BLUE}Creating requirements file...${NC}"
cat << EOF > requirements.txt
click>=8.0.0
rich>=10.0.0
pyyaml>=5.0.0
python-dotenv>=0.19.0
colorama>=0.4.4
boto3>=1.26.0
openai>=1.0.0
anthropic>=0.3.0
EOF

# Install dependencies
echo -e "\n${BLUE}Installing dependencies...${NC}"
pip install -r requirements.txt
pip install -e .

# Create logs directory
mkdir -p logs

# Interactive provider selection
echo -e "\n${BLUE}Select your AI provider:${NC}"
echo "1) AWS Bedrock (Claude)"
echo "2) OpenAI (GPT-4)"
echo "3) Anthropic (Claude)"
read -p "Enter your choice (1-3): " provider_choice

# Create .env file
echo -e "\n${BLUE}Setting up API keys...${NC}"
> .env

# Provider-specific configuration
case $provider_choice in
    1)
        echo "ai_provider: bedrock" > config.yaml
        read -p "Enter your AWS Access Key ID: " aws_access_key
        read -p "Enter your AWS Secret Access Key: " aws_secret_key
        echo "AWS_ACCESS_KEY_ID=$aws_access_key" >> .env
        echo "AWS_SECRET_ACCESS_KEY=$aws_secret_key" >> .env
        
        # AWS Bedrock model selection
        echo -e "\n${BLUE}Select AWS Bedrock model:${NC}"
        echo "1) Claude 4 Sonnet (anthropic.claude-sonnet-4-20250514-v1:0)"
        echo "2) Claude 3.5 Sonnet (anthropic.claude-3-5-sonnet-20240620-v1:0)"
        echo "3) Claude 3 Sonnet (anthropic.claude-3-sonnet-20240229-v1:0)"
        echo "4) Claude 3 Haiku (anthropic.claude-3-haiku-20240307-v1:0)"
        echo "5) Claude 2.1 (anthropic.claude-v2:1)"
        read -p "Enter your choice (1-5): " model_choice
        
        case $model_choice in
            1) model_id="anthropic.claude-sonnet-4-20250514-v1:0" ;;
            2) model_id="anthropic.claude-3-5-sonnet-20240620-v1:0" ;;
            3) model_id="anthropic.claude-3-sonnet-20240229-v1:0" ;;
            4) model_id="anthropic.claude-3-haiku-20240307-v1:0" ;;
            5) model_id="anthropic.claude-v2:1" ;;
            *) model_id="anthropic.claude-sonnet-4-20250514-v1:0" ;;
        esac
        
        read -p "Enter AWS region (default: us-east-1): " aws_region
        aws_region=${aws_region:-us-east-1}
        ;;
    2)
        echo "ai_provider: openai" > config.yaml
        read -p "Enter your OpenAI API Key: " openai_key
        echo "OPENAI_API_KEY=$openai_key" >> .env
        
        # OpenAI model selection
        echo -e "\n${BLUE}Select OpenAI model:${NC}"
        echo "1) GPT-4 Turbo (gpt-4-turbo-preview)"
        echo "2) GPT-4 (gpt-4)"
        echo "3) GPT-3.5 Turbo (gpt-3.5-turbo)"
        read -p "Enter your choice (1-3): " model_choice
        
        case $model_choice in
            1) model="gpt-4-turbo-preview" ;;
            2) model="gpt-4" ;;
            3) model="gpt-3.5-turbo" ;;
            *) model="gpt-4-turbo-preview" ;;
        esac
        ;;
    3)
        echo "ai_provider: anthropic" > config.yaml
        read -p "Enter your Anthropic API Key: " anthropic_key
        echo "ANTHROPIC_API_KEY=$anthropic_key" >> .env
        
        # Anthropic model selection
        echo -e "\n${BLUE}Select Anthropic model:${NC}"
        echo "1) Claude 4 Sonnet (claude-sonnet-4-20250514)"
        echo "2) Claude 3.5 Sonnet (claude-3-5-sonnet-20240620)"
        echo "3) Claude 3 Sonnet (claude-3-sonnet-20240229)"
        echo "4) Claude 3 Haiku (claude-3-haiku-20240307)"
        echo "5) Claude 2.1 (claude-2.1)"
        read -p "Enter your choice (1-5): " model_choice
        
        case $model_choice in
            1) model="claude-sonnet-4-20250514" ;;
            2) model="claude-3-5-sonnet-20240620" ;;
            3) model="claude-3-sonnet-20240229" ;;
            4) model="claude-3-haiku-20240307" ;;
            5) model="claude-2.1" ;;
            *) model="claude-sonnet-4-20250514" ;;
        esac
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

# Create default config.yaml
echo -e "\n${BLUE}Creating configuration...${NC}"
cat << EOF >> config.yaml

# Provider-specific settings
bedrock:
  region: "${aws_region:-us-east-1}"
  model_id: "${model_id:-anthropic.claude-sonnet-4-20250514-v1:0}"

openai:
  model: "${model:-gpt-4-turbo-preview}"

anthropic:
  model: "${model:-claude-sonnet-4-20250514}"

# Command Generation Settings
command_generation:
  max_retries: 3
  timeout: 30
  temperature: 0.7
  max_tokens: 1000

# Command history settings
history:
  max_entries: 1000
  save_to_file: true
  history_file: ".cli_history"

# UI settings
ui:
  prompt: "🤖 "
  error_color: "red"
  success_color: "green"
  info_color: "blue"
  warning_color: "yellow"

# Command execution settings
execution:
  timeout: 30
  max_retries: 3
  confirm_dangerous_commands: true

# Logging Configuration
logging:
  level: "INFO"
  log_dir: "logs"
  max_log_size: 10485760
  backup_count: 5
  log_format: "%(asctime)s - %(levelname)s - %(message)s"
EOF

# Create the logger module
if [ ! -f "logger.py" ]; then
    echo -e "\n${BLUE}Creating logger module...${NC}"
    cat << 'EOF' > logger.py
#!/usr/bin/env python3

import logging
from rich.logging import RichHandler

# Set up basic logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(rich_tracebacks=True)]
)

logger = logging.getLogger("cli_agent")
EOF
fi

# Create the main script file if it doesn't exist
if [ ! -f "cli_agent.py" ]; then
    echo -e "\n${BLUE}Creating main script file...${NC}"
    cat << 'EOF' > cli_agent.py
#!/usr/bin/env python3

import os
import sys
import yaml
import click
from rich.console import Console
from rich.prompt import Prompt
from rich.panel import Panel
from dotenv import load_dotenv
from providers import BedrockProvider, OpenAIProvider, AnthropicProvider
from logger import logger

# Load environment variables
load_dotenv()

console = Console()

class CLIAgent:
    def __init__(self):
        self.config = self._load_config()
        self.provider = self._setup_ai_provider()
        self.console = Console()

    def _load_config(self):
        try:
            with open('config.yaml', 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            console.print("[red]Error: config.yaml not found. Please run the installation script first.[/red]")
            sys.exit(1)

    def _setup_ai_provider(self):
        provider = self.config.get('ai_provider', 'bedrock')
        if provider == 'bedrock':
            return BedrockProvider(self.config['bedrock'])
        elif provider == 'openai':
            return OpenAIProvider(self.config['openai'])
        elif provider == 'anthropic':
            return AnthropicProvider(self.config['anthropic'])
        else:
            console.print(f"[red]Error: Unsupported provider '{provider}'[/red]")
            sys.exit(1)

    def run(self):
        console.print(Panel.fit(
            "[bold blue]CLI Agent[/bold blue]\n"
            "Type 'exit' to quit\n"
            "Type 'help' for available commands\n"
            "Type 'switch' to change AI provider",
            title="Welcome"
        ))

        while True:
            try:
                # Get current directory for prompt
                current_dir = os.getcwd()
                user_input = Prompt.ask(f"🤖 {current_dir} >")

                if user_input.lower() == 'exit':
                    break
                elif user_input.lower() == 'help':
                    self._show_help()
                    continue
                elif user_input.lower() == 'switch':
                    self._switch_provider()
                    continue

                # Get command from AI
                console.print("Processing your request...")
                command = self.provider.get_command(user_input)
                
                if not command:
                    console.print("[yellow]No command generated. Please try again.[/yellow]")
                    continue

                # Show the command and ask for confirmation
                console.print(f"\n[bold]Generated command:[/bold] {command}")
                
                if self.config['execution']['confirm_dangerous_commands']:
                    confirm = Prompt.ask("Execute command?", choices=["y", "n"], default="n")
                    if confirm.lower() != 'y':
                        continue

                # Execute the command
                result = os.popen(command).read()
                console.print(f"\n[bold]Output:[/bold]\n{result}")

            except KeyboardInterrupt:
                console.print("\n[yellow]Use 'exit' to quit[/yellow]")
            except Exception as e:
                console.print(f"[red]An error occurred: {str(e)}[/red]")

    def _switch_provider(self):
        console.print("\n[bold]Available Providers:[/bold]")
        console.print("1) AWS Bedrock (Claude)")
        console.print("2) OpenAI (GPT-4)")
        console.print("3) Anthropic (Claude)")
        
        choice = Prompt.ask("Select provider", choices=["1", "2", "3"])
        
        if choice == "1":
            self.config['ai_provider'] = 'bedrock'
            self.provider = BedrockProvider(self.config['bedrock'])
            console.print("[green]Switched to AWS Bedrock[/green]")
        elif choice == "2":
            self.config['ai_provider'] = 'openai'
            self.provider = OpenAIProvider(self.config['openai'])
            console.print("[green]Switched to OpenAI[/green]")
        elif choice == "3":
            self.config['ai_provider'] = 'anthropic'
            self.provider = AnthropicProvider(self.config['anthropic'])
            console.print("[green]Switched to Anthropic[/green]")

    def _show_help(self):
        console.print(Panel.fit(
            "[bold]Available Commands:[/bold]\n"
            "• exit - Quit the CLI agent\n"
            "• help - Show this help message\n"
            "• switch - Change AI provider\n\n"
            "[bold]Example Queries:[/bold]\n"
            "• list all files in current directory\n"
            "• find all python files modified in last 7 days\n"
            "• create a new directory called 'test'",
            title="Help"
        ))

@click.command()
def main():
    """CLI Agent - Convert natural language to bash commands"""
    agent = CLIAgent()
    agent.run()

if __name__ == '__main__':
    main()
EOF
    chmod +x cli_agent.py
fi

# Create a symlink in ~/.local/bin
echo -e "\n${BLUE}Creating global command...${NC}"
mkdir -p ~/.local/bin
ln -sf "$(pwd)/cli_agent.py" ~/.local/bin/cli-agent
chmod +x ~/.local/bin/cli-agent

# Add to PATH if not already present
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "\n${BLUE}Adding ~/.local/bin to your PATH...${NC}"
    
    # Function to add PATH to a shell config file
    add_to_shell_config() {
        local config_file=$1
        if [ -f "$config_file" ]; then
            # Check if the line already exists
            if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$config_file"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$config_file"
                echo -e "${GREEN}Added to $config_file${NC}"
            else
                echo -e "${BLUE}PATH already exists in $config_file${NC}"
            fi
        fi
    }

    # Add to both bash and zsh configs
    add_to_shell_config "$HOME/.bashrc"
    add_to_shell_config "$HOME/.zshrc"
    
    # Source the updated shell configuration
    if [ -n "$BASH_VERSION" ]; then
        source ~/.bashrc
    elif [ -n "$ZSH_VERSION" ]; then
        source ~/.zshrc
    fi
fi

# Create the providers module
if [ ! -d "providers" ]; then
    echo -e "\n${BLUE}Creating providers module...${NC}"
    mkdir -p providers
    touch providers/__init__.py
fi

# Create the base provider
if [ ! -f "providers/base.py" ]; then
    echo -e "\n${BLUE}Creating base provider...${NC}"
    cat << 'EOF' > providers/base.py
#!/usr/bin/env python3

from abc import ABC, abstractmethod

class BaseProvider(ABC):
    def __init__(self, config):
        self.config = config

    @abstractmethod
    def get_command(self, user_input):
        pass
EOF
fi

# Create the Bedrock provider
if [ ! -f "providers/bedrock.py" ]; then
    echo -e "\n${BLUE}Creating Bedrock provider...${NC}"
    cat << 'EOF' > providers/bedrock.py
#!/usr/bin/env python3

import boto3
from .base import BaseProvider

class BedrockProvider(BaseProvider):
    def __init__(self, config):
        super().__init__(config)
        self.region = config.get('region', 'us-east-1')
        self.model_id = config.get('model_id', 'anthropic.claude-sonnet-4-20250514-v1:0')
        self.client = boto3.client('bedrock-runtime', region_name=self.region)

    def get_command(self, user_input):
        try:
            # TODO: Implement actual Bedrock API call
            # For now, return a simple ls command
            return "ls -la"
        except Exception as e:
            raise
EOF
fi

# Create the OpenAI provider
if [ ! -f "providers/openai.py" ]; then
    echo -e "\n${BLUE}Creating OpenAI provider...${NC}"
    cat << 'EOF' > providers/openai.py
#!/usr/bin/env python3

import os
import openai
from .base import BaseProvider

class OpenAIProvider(BaseProvider):
    def __init__(self, config):
        super().__init__(config)
        self.model = config.get('model', 'gpt-4-turbo-preview')
        openai.api_key = os.getenv('OPENAI_API_KEY')

    def get_command(self, user_input):
        try:
            # TODO: Implement actual OpenAI API call
            # For now, return a simple ls command
            return "ls -la"
        except Exception as e:
            raise
EOF
fi

# Create the Anthropic provider
if [ ! -f "providers/anthropic.py" ]; then
    echo -e "\n${BLUE}Creating Anthropic provider...${NC}"
    cat << 'EOF' > providers/anthropic.py
#!/usr/bin/env python3

import os
import anthropic
from .base import BaseProvider

class AnthropicProvider(BaseProvider):
    def __init__(self, config):
        super().__init__(config)
        self.model = config.get('model', 'claude-sonnet-4-20250514')
        self.client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

    def get_command(self, user_input):
        try:
            # TODO: Implement actual Anthropic API call
            # For now, return a simple ls command
            return "ls -la"
        except Exception as e:
            raise
EOF
fi

# Update the providers __init__.py
if [ ! -f "providers/__init__.py" ]; then
    echo -e "\n${BLUE}Creating providers __init__.py...${NC}"
    cat << 'EOF' > providers/__init__.py
#!/usr/bin/env python3

from .bedrock import BedrockProvider
from .openai import OpenAIProvider
from .anthropic import AnthropicProvider

__all__ = ['BedrockProvider', 'OpenAIProvider', 'AnthropicProvider']
EOF
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "${GREEN}You can now use the CLI Agent by typing: cli-agent${NC}"
echo -e "\nExample usage:"
echo "cli-agent"
echo "🤖 > list all files in current directory"
echo "🤖 > find all python files modified in last 7 days"
echo -e "\nType 'exit' to quit the CLI Agent."
echo -e "Type 'switch' to change AI provider." 