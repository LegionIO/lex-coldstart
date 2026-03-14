# lex-example: Test Extension

## Purpose

A test extension for validating the Claude parser.

## What is This?

An async job processing engine built on RabbitMQ.

## Development

```bash
bundle install
bundle exec rspec
```

- Use `bundle exec` for all commands
- Run rubocop before committing

## Key Concepts

- **Runner**: A function that processes a task
- **Actor**: An execution mode (subscription, polling, interval)
- **Extension**: A gem that plugs into the framework
