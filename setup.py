from setuptools import setup, find_packages

setup(
    name="cli-agent",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "click>=8.0.0",
        "rich>=10.0.0",
        "pyyaml>=6.0.0",
        "python-dotenv>=0.19.0",
        "boto3>=1.28.0",
        "colorama>=0.4.4"
    ],
    entry_points={
        'console_scripts': [
            'cli-agent=cli_agent:main',
        ],
    },
    author="Your Name",
    author_email="your.email@example.com",
    description="A smart CLI agent that helps with bash commands and task automation",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/cli-agent",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.7",
) 