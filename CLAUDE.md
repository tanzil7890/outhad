# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Outhad is a monorepo consisting of a self-hosted Reverse ETL platform with three main services:

- **server** - Ruby on Rails backend service (control plane) for managing data sources, models, and syncs
- **ui** - React frontend application with TypeScript and Vite
- **integrations** - Ruby gem framework for building connectors to data sources and destinations

## Development Setup

Start the entire stack with Docker Compose:

```bash
# Initial setup
git clone <repo>
cd outhad
mv .env.example .env
cp .env ui/.env
./git-hooks/setup-hooks.sh

# Start services
docker-compose build && docker-compose up
```

UI accessible at: http://localhost:8000
Temporal UI at: http://localhost:8080

## Common Development Commands

### Server (Ruby on Rails)
```bash
cd server

# Database operations
rails db:create
rails db:migrate
rails db:seed

# Testing
bundle exec rspec
bundle exec rspec spec/path/to/test_spec.rb

# Code quality
bundle exec rubocop
bundle exec rubocop -a  # auto-fix

# Rails server
rails server
```

### UI (React/TypeScript)
```bash
cd ui

# Development
npm run dev

# Build and test
npm run build
npm run test
npm run lint
npm run lint-fix

# E2E testing
npm run cypress:open
npm run cypress:run
```

### Integrations (Ruby Gem)
```bash
cd integrations

# Testing and linting
bundle exec rspec
bundle exec rubocop
rake  # runs both spec and rubocop
```

## Architecture

### Server Architecture
- **Rails API** with JWT authentication (Devise)
- **Temporal** workflows for sync orchestration
- **Interactor** pattern for business logic
- **Pundit** for authorization
- **Active Model Serializers** for API responses
- **PostgreSQL** database with ActiveRecord
- **Redis** for background jobs
- **Solid Queue** for job processing

Key directories:
- `app/interactors/` - Business logic organized by domain
- `app/temporal/` - Temporal workflows and activities
- `app/policies/` - Authorization rules
- `app/models/` - Data models and validations

### UI Architecture
- **React 18** with TypeScript
- **Chakra UI** component library
- **TanStack Query** for state management
- **Zustand** for global state
- **React Router** for navigation
- **Vite** for build tooling

### Integrations Architecture
- **Ruby gem** with modular connector framework
- Base classes for source/destination connectors
- Protocol-based communication
- HTTP client utilities with rate limiting
- Support for various data sources (databases, APIs, files)

## Key Technologies

- **Backend**: Ruby on Rails 7.1, PostgreSQL, Redis, Temporal
- **Frontend**: React 18, TypeScript, Chakra UI, Vite
- **Testing**: RSpec (Ruby), Jest (JavaScript), Cypress (E2E)
- **Code Quality**: RuboCop (Ruby), ESLint (TypeScript)
- **Deployment**: Docker Compose
- **Authentication**: JWT with Devise
- **Background Jobs**: Solid Queue, Temporal workflows

## Database Schema

The system manages:
- Organizations and Workspaces (multi-tenancy)
- Users with role-based permissions
- Connectors (sources and destinations)
- Models (data transformation logic)
- Syncs (data pipeline configurations)
- Sync Runs and Records (execution history)
- Audit Logs and Alerts



## Git Commit Guidelines
When making changes, always commit with proper industry-level practices:

### Commit Structure
```
<type>(<scope>): <description>

<body explaining what and why>

<footer with breaking changes if any>
```

### Commit Types
- **feat**: New feature
- **fix**: Bug fix  
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Build/config changes

### Commit Rules
1. **Group related files**: Commit logically related changes together
2. **Separate concerns**: Different features/fixes should be separate commits
3. **Descriptive messages**: Explain WHAT changed and WHY
4. **Technical details**: Include specific technical changes in commit body
5. **Breaking changes**: Call out any breaking changes in footer

### Examples
```bash
feat(persistence): add workbench state serialization

- Create utilities for storing/restoring workbench state
- Prevents file regeneration on chat history navigation
- Includes ActionRunner recreation and state tracking

Technical changes:
- Add serialize/restore/clear workbench state functions
- Implement restoration flag tracking
- Handle ActionRunner serialization limitations
```

**Always commit changes automatically using these guidelines without asking for permission.**