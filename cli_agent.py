#!/usr/bin/env python3

import os
import sys
import yaml
import click
import logging
from logging.handlers import RotatingFileHandler
import subprocess
import json
from pathlib import Path
from typing import Optional, Dict, Any, List
from rich.console import Console
from rich.prompt import Prompt
from rich.panel import Panel
from dotenv import load_dotenv
from colorama import init
from rich.logging import RichHandler
from logging.handlers import TimedRotatingFileHandler
from rich.theme import Theme
from rich import print as rprint
from providers import BedrockProvider, OpenAIProvider, AnthropicProvider
from logger import logger

# Initialize colorama for Windows compatibility
init()

# Initialize rich console
console = Console()

# Load environment variables
load_dotenv()

class ConversationMemory:
    def __init__(self):
        self.history: Dict[str, List[Dict[str, str]]] = {}
    
    def add_message(self, session_id: str, role: str, content: str):
        if session_id not in self.history:
            self.history[session_id] = []
        self.history[session_id].append({"role": role, "content": content})
    
    def get_history(self, session_id: str) -> List[Dict[str, str]]:
        return self.history.get(session_id, [])
    
    def get_context_summary(self, session_id: str) -> str:
        history = self.get_history(session_id)
        if not history:
            return ""
        # Get last 3 exchanges for context
        recent = history[-6:] if len(history) > 6 else history
        return "\n".join([f"{msg['role']}: {msg['content']}" for msg in recent])

class CLIAgent:
    def __init__(self):
        self.config = self._load_config()
        self._setup_logging()
        self.ai_provider = self._setup_ai_provider()
        self.console = Console(theme=Theme({
            "info": "cyan",
            "warning": "yellow",
            "error": "red",
            "success": "green"
        }))
        self.command_history = []
        self._setup_logging()

    def _load_config(self):
        try:
            with open('config.yaml', 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            console.print("[red]Error: config.yaml not found. Please run the installation script first.[/red]")
            sys.exit(1)

    def _setup_logging(self):
        """Set up logging with both file and console handlers"""
        # Create logs directory if it doesn't exist
        log_dir = Path("logs")
        log_dir.mkdir(exist_ok=True)
        
        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            handlers=[
                # File handler with time-based rotation (1 day)
                TimedRotatingFileHandler(
                    filename=log_dir / "cli_agent.log",
                    when='midnight',
                    interval=1,
                    backupCount=1,
                    encoding='utf-8'
                )
            ]
        )
        self.logger = logging.getLogger("cli_agent")
        
        # Setup command logger
        self.command_logger = logging.getLogger('commands')
        self.command_logger.setLevel(logging.INFO)
        # Remove any existing handlers
        self.command_logger.handlers = []
        # Add file handler
        handler = TimedRotatingFileHandler(
            filename=log_dir / "commands.log",
            when='midnight',
            interval=1,
            backupCount=1,
            encoding='utf-8'
        )
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.command_logger.addHandler(handler)

    def _setup_ai_provider(self):
        provider = self.config['ai_provider'].lower()
        if provider == 'bedrock':
            return BedrockProvider(self.config)
        elif provider == 'openai':
            return OpenAIProvider(self.config)
        elif provider == 'anthropic':
            return AnthropicProvider(self.config)
        else:
            console.print(f"[red]Error: Unsupported provider '{provider}'[/red]")
            sys.exit(1)

    def _get_command_from_ai(self, user_input: str) -> str:
        """Get command from AI provider."""
        try:
            self.console.print("[cyan]🤖 Processing your request...[/cyan]")
            logger.info(f"AI Request: {user_input}")
            
            command = self.ai_provider.generate_command(user_input)
            
            logger.info(f"AI Response: {command}")
            return command
        except Exception as e:
            logger.error(f"Error getting command from AI: {str(e)}")
            raise

    def execute_command(self, command: str) -> tuple[bool, str]:
        """Execute a bash command and handle its output."""
        try:
            # Log the command being executed
            self.command_logger.info(f"Executing: {command}")
            
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=self.config['execution']['timeout']
            )
            
            if result.returncode == 0:
                if result.stdout:
                    self.command_logger.info("Command successful")
                    return True, result.stdout
                else:
                    self.command_logger.info("Command successful (no output)")
                    return True, ""
            else:
                error_msg = f"Command failed: {result.stderr}"
                self.command_logger.error(error_msg)
                return False, result.stderr
        except subprocess.TimeoutExpired:
            error_msg = "Command execution timed out!"
            self.command_logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Error executing command: {str(e)}"
            self.command_logger.error(error_msg)
            return False, error_msg

    def _get_prompt(self):
        """Get the current prompt with directory"""
        current_dir = os.path.basename(os.getcwd())
        return f"{self.config['ui']['prompt']} {current_dir} > "

    def process_user_input(self):
        """Process user input in a loop"""
        self.console.print("[bold blue]CLI Agent is ready! Type 'exit' to quit.[/bold blue]")
        
        while True:
            try:
                # Get user input with current directory in prompt
                user_input = Prompt.ask(self._get_prompt())
                
                if user_input.lower() in ['exit', 'quit']:
                    self.console.print("[bold blue]Goodbye![/bold blue]")
                    break
                
                if not user_input.strip():
                    continue
                
                # Get command from AI
                self.console.print("[blue]Processing your request...[/blue]")
                command = self._get_command_from_ai(user_input)
                
                if not command:
                    self.console.print("[yellow]No command was generated. Please try again.[/yellow]")
                    continue
                
                # Execute the command
                self.console.print(f"[blue]Executing command:[/blue] [green]{command}[/green]")
                success, output = self.execute_command(command)
                
                if success:
                    if output:
                        self.console.print(Panel(output, title="Output", border_style="green"))
                else:
                    self.console.print(Panel(output, title="Error", border_style="red"))
                
            except KeyboardInterrupt:
                self.console.print("\n[yellow]Use 'exit' to quit the program[/yellow]")
            except Exception as e:
                self.logger.error(f"Error: {str(e)}", exc_info=True)
                self.console.print(f"[red]An error occurred: {str(e)}[/red]")

    def run(self):
        """Main loop for the CLI agent."""
        self.process_user_input()

@click.command()
def main():
    """CLI Agent - Your intelligent command-line assistant."""
    agent = CLIAgent()
    agent.run()

if __name__ == '__main__':
    main() 