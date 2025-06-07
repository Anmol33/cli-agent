#!/usr/bin/env python3

import os
import logging
from anthropic import Anthropic
from .base import BaseProvider
from logger import logger

logger = logging.getLogger(__name__)

class AnthropicProvider(BaseProvider):
    """Anthropic provider implementation."""
    
    def __init__(self, config: dict):
        super().__init__(config)
        self.model = config.get('model', 'claude-sonnet-4-20250514')
        self.client = self._setup_anthropic()
        
    def _setup_anthropic(self):
        """Set up Anthropic client."""
        try:
            api_key = os.getenv('ANTHROPIC_API_KEY')
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable not set")
            return Anthropic(api_key=api_key)
        except Exception as e:
            logger.error(f"Failed to initialize Anthropic client: {str(e)}")
            raise

    def get_command(self, user_input: str) -> str:
        """Generate command using Anthropic."""
        try:
            prompt = f"""You are a helpful AI assistant that converts natural language into bash commands.
            Convert the following request into a bash command. Only output the command, no explanations.
            Request: {user_input}"""

            response = self.client.messages.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=self.config['command_generation']['temperature'],
                max_tokens=self.config['command_generation']['max_tokens']
            )
            
            return response.content[0].text.strip()
        except Exception as e:
            logger.error(f"Error generating command with Anthropic: {str(e)}")
            raise 