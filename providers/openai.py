#!/usr/bin/env python3

import os
import logging
import openai
from .base import BaseProvider
from logger import logger

logger = logging.getLogger(__name__)

class OpenAIProvider(BaseProvider):
    """OpenAI provider implementation."""
    
    def __init__(self, config: dict):
        super().__init__(config)
        self.model = config.get('model', 'gpt-4-turbo-preview')
        openai.api_key = os.getenv('OPENAI_API_KEY')
        self.client = self._setup_openai()
        
    def _setup_openai(self):
        """Set up OpenAI client."""
        try:
            if not openai.api_key:
                raise ValueError("OPENAI_API_KEY environment variable not set")
            return openai
        except Exception as e:
            logger.error(f"Failed to initialize OpenAI client: {str(e)}")
            raise

    def get_command(self, user_input: str) -> str:
        """Generate command using OpenAI."""
        try:
            prompt = f"""You are a helpful AI assistant that converts natural language into bash commands.
            Convert the following request into a bash command. Only output the command, no explanations.
            Request: {user_input}"""

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=self.config['command_generation']['temperature'],
                max_tokens=self.config['command_generation']['max_tokens']
            )
            
            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"Error generating command with OpenAI: {str(e)}")
            raise 