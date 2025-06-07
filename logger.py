#!/usr/bin/env python3

import os
import logging
from rich.logging import RichHandler

def setup_logger():
    logger = logging.getLogger("cli_agent")
    logger.setLevel(logging.INFO)

    # Create logs directory if it doesn't exist
    os.makedirs("logs", exist_ok=True)

    # Add file handler
    file_handler = logging.FileHandler("logs/cli_agent.log")
    file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
    logger.addHandler(file_handler)

    # Add console handler with rich formatting
    console_handler = RichHandler(rich_tracebacks=True)
    console_handler.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(console_handler)

    return logger

# Create global logger instance
logger = setup_logger()
