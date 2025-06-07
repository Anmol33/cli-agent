# CLI Agent

A command-line interface agent that uses AI to convert natural language into bash commands. Simply describe what you want to do, and the agent will convert it into the appropriate bash command.

## Quick Start

### For Linux/macOS:
```bash
# Clone the repository
git clone https://github.com/Anmol33/cli-agent.git
cd cli-agent

# Run the installation script
./install.sh
```

### For Windows:
```batch
# Clone the repository
git clone https://github.com/Anmol33/cli-agent.git
cd cli-agent

# Run the installation script
install.bat
```

The installation script will:
1. Set up a Python virtual environment
2. Install all dependencies
3. Guide you through selecting your AI provider
4. Help you configure your API keys
5. Set up the CLI agent for global use

## Supported Platforms

- **Linux**: Tested on Ubuntu 20.04+, Debian 10+, and other major distributions
- **macOS**: Tested on macOS 10.15+ (Catalina and newer)
- **Windows**: Tested on Windows 10/11

## Prerequisites

- Python 3.8 or higher
- Git
- One of the following AI provider accounts and credentials:
  - AWS Bedrock access
  - OpenAI API key
  - Anthropic API key

## Platform-Specific Notes

### Linux/macOS
- The installation script will create a symlink in `~/.local/bin`
- You may need to restart your terminal or run `source ~/.bashrc` (or `source ~/.zshrc`)

### Windows
- The installation script will add the CLI agent to your system PATH
- You may need to restart your terminal for PATH changes to take effect
- If you're using PowerShell, you might need to set the execution policy:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

## Example Usage

```bash
# Start the CLI agent
cli-agent

# Example commands you can try:
🤖 /Users/user/projects > list all files in current directory
🤖 /Users/user/projects > find all python files modified in last 7 days
🤖 /Users/user/projects > create a new directory called 'test' and cd into it
```

## Features

- Natural language to bash command conversion
- Support for multiple AI providers:
  - AWS Bedrock (Claude)
  - OpenAI (GPT-4)
  - Anthropic (Claude)
- Command execution with safety checks
- Command history tracking
- Detailed logging
- Colorful terminal interface

## Configuration

The `config.yaml` file allows you to customize:
- AI provider and model settings
- Command generation parameters
- Logging preferences
- Command history settings

## Logging

The agent maintains two types of logs in the `logs` directory:
- `commands.log`: Records all commands and their outputs
- `cli_agent.log`: General application logs

Logs are automatically rotated daily and kept for 5 backup files.

## Troubleshooting

### Common Issues

1. **Command Not Found**:
   - Linux/macOS: Run `source ~/.bashrc` or `source ~/.zshrc`
   - Windows: Restart your terminal or run `refreshenv`

2. **Python Version Issues**:
   - Ensure Python 3.8+ is installed
   - Check with `python --version`

3. **API Key Issues**:
   - Verify your API keys in the `.env` file
   - Check provider-specific requirements

4. **Permission Issues**:
   - Linux/macOS: Run `chmod +x install.sh`
   - Windows: Run as administrator if needed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
