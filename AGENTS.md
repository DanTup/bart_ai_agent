# Bart - A simple Dart AI Agent

## Overview

A simple AI agent built in Dart that. Works via the terminal. Uses a Large Language Model (LLM) via the OpenAI API to process user requests and has some basic tools.

## Architecture

### Core Components

- **`Agent`**: Abstract base class that handles the main agent loop, API communication, and tool execution.
- **`CliAgent`**: Concrete implementation of `Agent` for command-line interaction.
- **`Tool`**: Abstract class for tools that the agent can execute.

### Key Files

- `bin/main.dart`: Entry point that sets up logging, parses arguments, and runs the agent.
- `lib/agents/agent.dart`: Base agent class with LLM integration and tool execution.
- `lib/agents/cli_agent.dart`: CLI-based Agent.
- `lib/tools/`: Directory containing all built-in tool implementations.

## Running

## Basic Usage

- `dart bin/main.dart` - run at the terminal

## Running Tests

- `dart test` - run all unit tests
