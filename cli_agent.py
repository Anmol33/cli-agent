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
import boto3
from colorama import init
from rich.logging import RichHandler
from logging.handlers import TimedRotatingFileHandler
from botocore.config import Config

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
        self._setup_bedrock()
        self.history = []
        self.console = Console()
        self.memory = ConversationMemory()

    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from YAML file."""
        try:
            with open('config.yaml', 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            console.print("[red]Error: config.yaml not found![/red]")
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

    def _setup_bedrock(self):
        """Initialize Amazon Bedrock client."""
        try:
            self.bedrock = boto3.client(
                service_name='bedrock-runtime',
                region_name=self.config['bedrock']['region']
            )
        except Exception as e:
            console.print(f"[red]Error initializing Bedrock client: {str(e)}[/red]")
            sys.exit(1)

    def _get_command_from_ai(self, user_input: str) -> str:
        """Use Claude through Bedrock to convert natural language to bash command."""
        try:
            # Get conversation history
            history = self.memory.get_history("default")
            
            # Build messages array with history
            messages = []
            
            # Add system message
            system_message = """You are a helpful assistant that converts natural language to bash commands.
            Only respond with the bash command, no explanations.
            Your response should be a single line containing only the bash command."""
            
            messages.append({
                "role": "user",
                "content": system_message
            })
            messages.append({
                "role": "assistant",
                "content": "I understand. I will only respond with the bash command, no explanations."
            })
            
            # Add recent conversation history (last 4 exchanges)
            recent_history = history[-4:] if len(history) > 4 else history
            for msg in recent_history:
                if msg["role"] in ["user", "assistant"]:
                    messages.append(msg)
            
            # Add current prompt
            messages.append({
                "role": "user",
                "content": user_input
            })
            
            # Log the request
            self.command_logger.info(f"Request: {user_input}")
            
            # Prepare the request body
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": self.config['bedrock']['max_tokens'],
                "temperature": self.config['bedrock']['temperature'],
                "messages": messages
            }
            
            # Convert to JSON string
            request_body_json = json.dumps(request_body)
            
            # Invoke the model
            response = self.bedrock.invoke_model(
                modelId=self.config['bedrock']['model'],
                body=request_body_json
            )
            
            # Parse the response
            response_body = json.loads(response['body'].read())
            
            # Extract the response text
            command = ""
            if 'content' in response_body:
                for content in response_body['content']:
                    if content.get('type') == 'text':
                        command += content.get('text', '')
            
            command = command.strip()
            
            # Log the response
            self.command_logger.info(f"Command: {command}")
            
            # Store the conversation
            self.memory.add_message("default", "user", user_input)
            self.memory.add_message("default", "assistant", command)
            
            return command
        except Exception as e:
            error_msg = f"Bedrock API error: {str(e)}"
            self.logger.error(error_msg)
            return ""

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