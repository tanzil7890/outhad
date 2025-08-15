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
It should not contain: Co-Authored-By: Claude <noreply@anthropic.com>

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

## Development Decision Process

### Pre-Response Analysis Rule
**CRITICAL**: Before generating any response or deciding what action to take, ALWAYS check the following log files to understand the project history and avoid repeating failed approaches:

1. **MUST READ `Logs.md`** - To see all recent operations and their outcomes
2. **MUST READ `worked-debug.md`** - To identify proven working solutions and commands
3. **MUST READ `not-Worked-debug.md`** - To avoid repeating failed approaches and learn from previous attempts

### Decision-Making Process
1. **Analyze Current Request**: Understand what the user is asking for
2. **Check Historical Context**: Review all three log files to understand:
   - What has been tried before
   - What worked successfully
   - What failed and why
   - What fixes were attempted
3. **Plan Informed Response**: Based on log analysis, choose the most appropriate approach that:
   - Leverages known working solutions
   - Avoids previously failed methods
   - Builds upon successful patterns
   - Learns from past debugging attempts

This ensures intelligent, context-aware development decisions and prevents repetitive debugging cycles.

## Command and Response Logging

### Mandatory Logging Rule
Every command executed by the agent, every response received, and every task implementation (whether successful or failed) must be logged to track development progress and debugging information.

#### Log Format for All Operations and Tasks
Log every operation and task in `Logs.md` using this format:
```
[Date | Time] {command/task by agent or tested} {response whether it was correct or not or worked or not}
```

Examples:
- `[2025-01-15 | 14:30] Implemented hot reloading for integrations gem Failed - User reported it's not working yet`
- `[2025-01-15 | 14:35] docker-compose up command Working - All services started successfully`

**IMPORTANT**: Always use actual current date and time, not placeholder text like "Current Time"

**CRITICAL**: Always log the actual command/tool executed (e.g., "Edit tool on file.rb", "Bash: npm install", "Read tool on config.json") not just the task description

#### Successful Operations and Tasks Log
Log successful operations and tasks in `worked-debug.md` using this detailed format:
```
[Date | Time] [Task/Operation Name]
**Commands Used**: [Exact tools/commands executed]
**Response**: [What happened/outcome]
**Files Modified**: [List of files changed]
**Technical Changes**: [Specific code/config changes made]
**Status**: [Working/Success confirmation]
---
```

Examples:
```
[2025-01-15 | 14:30] Rails Hot Reloading Configuration
**Commands Used**: Edit tool on server/config/environments/development.rb
**Response**: Successfully added config.enable_reloading and autoload settings
**Files Modified**: server/config/environments/development.rb
**Technical Changes**: Added config.autoload_lib and config.to_prepare block for gem reloading
**Status**: Working - User confirmed hot reloading works
---

[2025-01-15 | 14:35] Test Suite Execution
**Commands Used**: Bash: bundle exec rspec
**Response**: All tests passed successfully
**Files Modified**: None
**Technical Changes**: None
**Status**: Working - 45 examples, 0 failures
---
```

#### Failed Operations and Tasks Log
Log failed operations and tasks in `not-Worked-debug.md` using this detailed format:
```
[Date | Time] [Task/Operation Name]
**Commands Used**: [Exact tools/commands executed]
**Error/Failure**: [What went wrong/error messages]
**Files Modified**: [List of files that were changed]
**Technical Changes Attempted**: [Specific code/config changes tried]
**Root Cause**: [Why it failed - analysis]
**Attempted Fixes**: [What solutions were tried]
**Status**: [Failed/Not Working - with user feedback]
---
```

Examples:
```
[2025-01-15 | 14:30] Integrations Hot Reloading Setup
**Commands Used**: Edit tool on docker-compose.yml, Edit tool on server/Gemfile
**Error/Failure**: User reported integrations gem changes not reflecting in running container
**Files Modified**: docker-compose.yml, server/Gemfile
**Technical Changes Attempted**: Added volume mounting for integrations directory, modified gem path
**Root Cause**: Path-based gems don't auto-reload in Rails development mode
**Attempted Fixes**: Docker volume mounting, gem path modifications
**Status**: Failed - User confirmed still not working, need Rails-specific gem reloading approach
---

[2025-01-15 | 14:35] Frontend Build Process
**Commands Used**: Bash: npm run build
**Error/Failure**: Build failed with TypeScript compilation errors
**Files Modified**: None (build failed before completion)
**Technical Changes Attempted**: None (error occurred during build)
**Root Cause**: TypeScript type definition mismatches in component files
**Attempted Fixes**: Updated type definitions, fixed import statements
**Status**: Failed initially - Fixed by updating type definitions, then worked
---
```

#### Logging Requirements
1. **All Commands**: Log every bash command, tool execution, file operation, etc.
2. **All Tasks**: Log every task implementation, feature development, debugging session
3. **Actual Tool Names**: Must specify exact tool used (Edit tool, Bash, Read tool, Write tool, etc.)
4. **File Paths**: Include specific files modified when using Edit/Write/Read tools
5. **All Responses**: Log whether the command/task worked, failed, or had issues
6. **User Feedback**: Log when user reports something is/isn't working
7. **Real-time Logging**: Log immediately after each operation or task completion
8. **Success Tracking**: Separately track what worked for future reference in `worked-debug.md`
9. **Failure Tracking**: Separately track what failed for debugging in `not-Worked-debug.md`
10. **Task Status**: Log task progress, user testing results, and implementation outcomes

This comprehensive logging system ensures complete traceability of all development activities, task implementations, and user feedback, helping maintain records of both working solutions and failed attempts for comprehensive debugging and future reference.