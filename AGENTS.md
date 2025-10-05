# Bart - A simple Dart AI Agent

## Overview

A simple AI agent built in Dart that. Works via the terminal or through a simple web app. Uses a Large Language Model (LLM) via the OpenAI API to process user requests and has some basic tools.

## Architecture

### Core Components

- **`Agent`**: Abstract base class that handles the main agent loop, API communication, and tool execution.
- **`CliAgent`**: Concrete implementation of `Agent` for command-line interaction.
- **`WebAgent`**: Concrete implementation of `Agent` for interaction in a browser.
- **`Tool`**: Abstract class for tools that the agent can execute.

### Key Files

- `bin/main.dart`: Entry point that sets up logging, parses arguments, and runs the agent.
- `lib/agents/agent.dart`: Base agent class with LLM integration and tool execution.
- `lib/agents/cli_agent.dart`: CLI-based Agent.
- `lib/agents/web_agent.dart`: Web-based Agent.
- `lib/tools/`: Directory containing all built-in tool implementations.

## Running

## Basic Usage

- `dart bin/main.dart` - run at the terminal
- `dart bin/main.dart --web` - run via a simple web app
- `dart bin/main.dart --canned-responses` - run with a simple bot that provides canned responses

If you find there is no real LLM available in the current environment, use the `--canned-responses` option.

## Running Tests

- `dart test` - run all unit tests
- `dart test integration_test` - run all integration tests

By default, integration tests run using replays of snapshots recorded with a real LLM.
