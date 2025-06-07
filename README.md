# CLI Agent

A smart CLI agent that helps with bash commands and task automation using Amazon Bedrock's Claude model.

## Features

- Natural language to bash command conversion
- Command execution with detailed feedback
- Command history tracking
- Daily log rotation
- Clean and informative output

## Prerequisites

- Python 3.7 or higher
- AWS account with Bedrock access
- AWS credentials configured

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Anmol33/cli-agent.git
cd cli-agent
```

2. Set up AWS credentials:
```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

3. Run the installation script:
```bash
./install.sh
```

## Usage

After installation, you can use the CLI agent in three ways:

1. Run `source ~/.zshrc` (or `source ~/.bashrc`) to update your current shell, then type `cli-agent`
2. Open a new terminal and type `cli-agent`
3. Run `source venv/bin/activate && cli-agent` from the project directory

## Configuration

The `config.yaml` file contains all the necessary settings:

- Amazon Bedrock settings (model, temperature, etc.)
- Command history settings
- UI settings
- Command execution settings
- Logging settings

## License

Apache-2.0 license 
