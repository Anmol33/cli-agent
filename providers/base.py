#!/usr/bin/env python3

from abc import ABC, abstractmethod
from logger import logger

class BaseProvider(ABC):
    """Abstract base class for AI providers."""
    
    def __init__(self, config):
        self.config = config
        logger.info(f"Initializing {self.__class__.__name__}")

    @abstractmethod
    def get_command(self, user_input: str) -> str:
        """Generate a command based on user input."""
        pass 