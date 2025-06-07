@echo off
setlocal enabledelayedexpansion

echo Welcome to CLI Agent Installation!
echo This script will help you set up the CLI Agent with your preferred AI provider.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed. Please install Python 3.8 or higher.
    exit /b 1
)

REM Create and activate virtual environment
echo.
echo Setting up virtual environment...
python -m venv venv
call venv\Scripts\activate.bat

REM Install dependencies
echo.
echo Installing dependencies...
pip install -e .

REM Create logs directory
mkdir logs 2>nul

REM Interactive provider selection
echo.
echo Select your AI provider:
echo 1) AWS Bedrock (Claude)
echo 2) OpenAI (GPT-4)
echo 3) Anthropic (Claude)
set /p provider_choice="Enter your choice (1-3): "

REM Create .env file
echo.
echo Setting up API keys...
type nul > .env

if "%provider_choice%"=="1" (
    echo ai_provider: bedrock > config.yaml
    set /p aws_access_key="Enter your AWS Access Key ID: "
    set /p aws_secret_key="Enter your AWS Secret Access Key: "
    echo AWS_ACCESS_KEY_ID=%aws_access_key%>> .env
    echo AWS_SECRET_ACCESS_KEY=%aws_secret_key%>> .env
    
    REM AWS Bedrock model selection
    echo.
    echo Select AWS Bedrock model:
    echo 1) Claude 3 Sonnet (anthropic.claude-3-sonnet-20240229-v1:0)
    echo 2) Claude 3 Haiku (anthropic.claude-3-haiku-20240307-v1:0)
    echo 3) Claude 2.1 (anthropic.claude-v2:1)
    set /p model_choice="Enter your choice (1-3): "
    
    if "%model_choice%"=="1" (
        set model_id=anthropic.claude-3-sonnet-20240229-v1:0
    ) else if "%model_choice%"=="2" (
        set model_id=anthropic.claude-3-haiku-20240307-v1:0
    ) else if "%model_choice%"=="3" (
        set model_id=anthropic.claude-v2:1
    ) else (
        set model_id=anthropic.claude-3-sonnet-20240229-v1:0
    )
    
    set /p aws_region="Enter AWS region (default: us-east-1): "
    if "%aws_region%"=="" set aws_region=us-east-1
) else if "%provider_choice%"=="2" (
    echo ai_provider: openai > config.yaml
    set /p openai_key="Enter your OpenAI API Key: "
    echo OPENAI_API_KEY=%openai_key%>> .env
    
    REM OpenAI model selection
    echo.
    echo Select OpenAI model:
    echo 1) GPT-4 Turbo (gpt-4-turbo-preview)
    echo 2) GPT-4 (gpt-4)
    echo 3) GPT-3.5 Turbo (gpt-3.5-turbo)
    set /p model_choice="Enter your choice (1-3): "
    
    if "%model_choice%"=="1" (
        set model=gpt-4-turbo-preview
    ) else if "%model_choice%"=="2" (
        set model=gpt-4
    ) else if "%model_choice%"=="3" (
        set model=gpt-3.5-turbo
    ) else (
        set model=gpt-4-turbo-preview
    )
) else if "%provider_choice%"=="3" (
    echo ai_provider: anthropic > config.yaml
    set /p anthropic_key="Enter your Anthropic API Key: "
    echo ANTHROPIC_API_KEY=%anthropic_key%>> .env
    
    REM Anthropic model selection
    echo.
    echo Select Anthropic model:
    echo 1) Claude 3 Sonnet (claude-3-sonnet-20240229)
    echo 2) Claude 3 Haiku (claude-3-haiku-20240307)
    echo 3) Claude 2.1 (claude-2.1)
    set /p model_choice="Enter your choice (1-3): "
    
    if "%model_choice%"=="1" (
        set model=claude-3-sonnet-20240229
    ) else if "%model_choice%"=="2" (
        set model=claude-3-haiku-20240307
    ) else if "%model_choice%"=="3" (
        set model=claude-2.1
    ) else (
        set model=claude-3-sonnet-20240229
    )
) else (
    echo Invalid choice!
    exit /b 1
)

REM Create default config.yaml
echo.
echo Creating configuration...
(
echo.
echo # Provider-specific settings
echo bedrock:
echo   region: "%aws_region%"
echo   model_id: "%model_id%"
echo.
echo openai:
echo   model: "%model%"
echo.
echo anthropic:
echo   model: "%model%"
echo.
echo # Command Generation Settings
echo command_generation:
echo   max_retries: 3
echo   timeout: 30
echo   temperature: 0.7
echo   max_tokens: 1000
echo.
echo # Command history settings
echo history:
echo   max_entries: 1000
echo   save_to_file: true
echo   history_file: ".cli_history"
echo.
echo # UI settings
echo ui:
echo   prompt: "🤖 "
echo   error_color: "red"
echo   success_color: "green"
echo   info_color: "blue"
echo   warning_color: "yellow"
echo.
echo # Command execution settings
echo execution:
echo   timeout: 30
echo   max_retries: 3
echo   confirm_dangerous_commands: true
echo.
echo # Logging Configuration
echo logging:
echo   level: "INFO"
echo   log_dir: "logs"
echo   max_log_size: 10485760
echo   backup_count: 5
echo   log_format: "%%(asctime)s - %%(levelname)s - %%(message)s"
) >> config.yaml

REM Create a batch file for easy execution
echo @echo off > cli-agent.bat
echo call "%~dp0venv\Scripts\activate.bat" >> cli-agent.bat
echo python "%~dp0cli_agent.py" %%* >> cli-agent.bat

REM Add to PATH
setx PATH "%PATH%;%CD%"

echo.
echo Installation complete!
echo You can now use the CLI Agent by typing: cli-agent
echo.
echo Example usage:
echo cli-agent
echo 🤖 ^> list all files in current directory
echo 🤖 ^> find all python files modified in last 7 days
echo.
echo Type 'exit' to quit the CLI Agent.

endlocal 