#!/usr/bin/env python3

import json
import logging
import boto3
from .base import BaseProvider
from logger import logger

logger = logging.getLogger(__name__)

class BedrockProvider(BaseProvider):
    """AWS Bedrock provider implementation."""
    
    def __init__(self, config: dict):
        super().__init__(config)
        self.region = config.get('region', 'us-east-1')
        self.model_id = config.get('model_id', 'anthropic.claude-sonnet-4-20250514-v1:0')
        self.client = boto3.client('bedrock-runtime', region_name=self.region)
        
    def get_command(self, user_input: str) -> str:
        """Generate command using AWS Bedrock."""
        try:
            # Prepare the messages array
            messages = [
                {
                    "role": "system",
                    "content": "You are a helpful AI assistant that converts natural language into bash commands. Only respond with the bash command, no explanations."
                },
                {
                    "role": "user",
                    "content": user_input
                }
            ]

            # Prepare the request body
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": self.config['command_generation']['max_tokens'],
                "temperature": self.config['command_generation']['temperature'],
                "messages": messages
            }

            # Invoke the model
            response = self.client.invoke_model(
                modelId=self.model_id,
                body=json.dumps(request_body)
            )
            
            # Parse the response
            response_body = json.loads(response['body'].read())
            
            # Extract the response text
            command = ""
            if 'content' in response_body:
                for content in response_body['content']:
                    if content.get('type') == 'text':
                        command += content.get('text', '')
            
            return command.strip()
        except Exception as e:
            logger.error(f"Error generating command with Bedrock: {str(e)}")
            raise 