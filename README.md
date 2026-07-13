# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# AI-Powered Task Platform

A fully functional task management system with:
- Rails API
- Neo4j graph database
- Groq LLM integration
- n8n automation
- Feedback loops for self-improvement


# AI-Powered Task Management Platform

[![Ruby](https://img.shields.io/badge/Ruby-3.2.2-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.0.10-red.svg)](https://rubyonrails.org/)
[![Neo4j](https://img.shields.io/badge/Neo4j-5.x-blue.svg)](https://neo4j.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A self‑improving, AI‑powered task management platform that converts natural language requests into actionable tasks, stores them in a graph database, learns from feedback, and automatically notifies your team via Slack.

**Built with:** Ruby on Rails, Neo4j, Groq LLM, n8n, Sidekiq, Redis, PostgreSQL, Slack API

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Testing with Postman](#testing-with-postman)
- [n8n Workflow Setup](#n8n-workflow-setup)
- [Slack Integration](#slack-integration)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This platform allows users to describe tasks in natural language, and an AI agent:

1. **Parses** the request into a structured plan (subtasks, dependencies, priorities)
2. **Creates** tasks as nodes in Neo4j with relationships (creator, blockers, assignees)
3. **Learns** from feedback through a reflection loop
4. **Notifies** team members via Slack
5. **Recovers** gracefully with fallback mechanisms when LLMs fail

### Key Features

| Feature | Description |
| :--- | :--- |
| **Natural Language Processing** | Uses Groq LLM to extract structured tasks from plain English |
| **Graph Database** | Neo4j stores tasks, users, and relationships (blocks, created_by) |
| **Feedback Loop** | Agent collects ratings, reflects, and improves future plans |
| **Automation** | n8n workflows send real‑time Slack notifications |
| **Async Processing** | Sidekiq handles long‑running planning tasks |
| **Fallback Mechanism** | Works even when LLM is unavailable |

### Market Context

The project management software market is projected to grow from **$11.27 billion in 2026** to **$23.09 billion by 2031**. This platform demonstrates how AI‑native tools can disrupt traditional project management by replacing clicks with conversation.

---

## Architecture

### High‑Level Diagram

```mermaid
flowchart TB
    subgraph Client["Client Layer"]
        User[User]
        API[Postman / Web UI]
    end

    subgraph Rails["Rails Application"]
        Auth[Authentication]
        Controller[AiController]
        Agent[TaskPlannerAgent]
        Tools[Neo4jTools]
        Sidekiq[Sidekiq Worker]
    end

    subgraph Databases["Data Layer"]
        PG[(PostgreSQL)]
        Neo[(Neo4j)]
        Redis[(Redis)]
    end

    subgraph External["External Services"]
        Groq[Groq LLM]
        n8n[n8n Workflow]
        Slack[Slack]
    end

    User -->|"POST /ai/plan"| Controller
    Controller --> Agent
    Agent -->|"understand_request"| Groq
    Agent -->|"execute_plan"| Tools
    Tools -->|"Cypher queries"| Neo
    Agent -->|"webhook"| n8n
    n8n -->|"notify"| Slack
    Controller --> Sidekiq
    Sidekiq --> Redis

Technology Stack
Component	Technology	Purpose
API	Ruby on Rails 7.0	Backend framework
Authentication	JWT (token‑based)	Secure API access
Graph Database	Neo4j 5.x	Store tasks and relationships
Relational DB	PostgreSQL	Users, feedback, attachments
Cache/Queue	Redis 7.x	Sidekiq job queue & caching
Background Jobs	Sidekiq 7.x	Async task processing
LLM	Groq (llama-3.3-70b)	Natural language understanding
Automation	n8n 2.x	Workflow orchestration
Notifications	Slack API	Team notifications

Prerequisites

Ruby 3.2.2+

Rails 7.0+

Docker & Docker Compose

PostgreSQL 14+

Neo4j 5.x (via Docker)

Redis 7.x (via Docker)

Groq API Key (free at console.groq.com)

Slack App (for notifications)

⚡ Quick Start
1. Clone the Repository
bash
git clone https://github.com/your-username/task-platform.git
cd task-platform
2. Set Up Environment Variables
bash
cp .env.example .env
Edit .env with your credentials:

# Redis
REDIS_URL=redis://localhost:6379/0

# Groq API
GROQ_API_KEY=gsk_...

# Slack
SLACK_API_TOKEN=xoxb-...

# n8n
N8N_TASK_CREATED_WEBHOOK=http://localhost:5678/webhook/task-created

# Optional (for future use)

OPENAI_API_KEY=
ANTHROPIC_API_KEY=
GOOGLE_GEMINI_API_KEY=

3. Start Docker Services

bash

docker compose up -d

This starts:

PostgreSQL on port 5433

Neo4j on ports 7474 (HTTP) and 7687 (Bolt)

Redis on port 6379

n8n on port 5678

4. Install Dependencies
bash
bundle install
5. Set Up the Database
bash
rails db:create db:migrate
6. Start Rails Server
bash
rails server -b 0.0.0.0 -p 3000
7. Start Sidekiq (for Async)
bash
bundle exec sidekiq
8. Configure n8n Workflow
Open http://localhost:5678

Create a new workflow

Add a Webhook node with path task-created

Add a Slack node with your credentials

Connect Webhook → Slack

Save, Publish, and Activate the workflow

9. Test the API
bash
# Register
curl -X POST http://localhost:3000/register \
     -H "Content-Type: application/json" \
     -d '{"user": {"email": "test@example.com", "password": "secret123", "password_confirmation": "secret123"}}'

# Login to get token
curl -X POST http://localhost:3000/login \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com", "password": "secret123"}'

# Call the AI planning endpoint
curl -X POST http://localhost:3000/ai/plan \
     -H "Authorization: Bearer <YOUR_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"request": "Create a marketing campaign with three tasks: social media, email, ads."}'
🔑 Environment Variables
Variable	Description	Required	Default
DATABASE_URL	PostgreSQL connection string	✅	-
NEO4J_URL	Neo4j HTTP endpoint	✅	http://localhost:7474
NEO4J_USER	Neo4j username	✅	neo4j
NEO4J_PASSWORD	Neo4j password	✅	password
REDIS_URL	Redis connection URL	✅	redis://localhost:6379/0
GROQ_API_KEY	Groq LLM API key	✅	-
SLACK_API_TOKEN	Slack Bot User OAuth Token	⚠️	-
N8N_TASK_CREATED_WEBHOOK	n8n webhook URL	⚠️	-
ANTHROPIC_API_KEY	Claude API key (optional)	❌	-
GOOGLE_GEMINI_API_KEY	Gemini API key (optional)	❌	-
📡 API Endpoints
Authentication
Method	Endpoint	Description	Auth
POST	/register	Register new user	❌
POST	/login	Login and get token	❌
AI Planning
Method	Endpoint	Description	Auth
POST	/ai/plan	Synchronous task planning	✅
POST	/ai/plan_async	Asynchronous task planning	✅
GET	/ai/status	Get async job status	✅
GET	/ai/tasks	Query tasks (filters: status, priority, completed, assignee_email)	✅
POST	/ai/feedback	Submit feedback for a task (task_id, rating, comments)	✅
Example Requests
Synchronous Planning
bash
curl -X POST http://localhost:3000/ai/plan \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"request": "Create a blog post plan with introduction, main content, and conclusion."}'
Async Planning
bash
curl -X POST http://localhost:3000/ai/plan_async \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"request": "Plan a product launch with 5 phases"}'

# Response: {"job_id":"abc123","message":"Planning started. Poll /ai/status for result."}

# Poll status
curl -X GET http://localhost:3000/ai/status \
     -H "Authorization: Bearer YOUR_TOKEN"
Query Tasks
bash
curl -X GET "http://localhost:3000/ai/tasks?status=open&priority=High" \
     -H "Authorization: Bearer YOUR_TOKEN"
Submit Feedback
bash
curl -X POST http://localhost:3000/ai/feedback \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"task_id": "abc-123", "rating": 4, "comments": "Great plan, but add more details."}'
🧪 Testing with Postman
Collection Structure
text
📁 Task Platform
├── 📁 Auth
│   ├── POST /register
│   └── POST /login
├── 📁 AI
│   ├── POST /ai/plan
│   ├── POST /ai/plan_async
│   ├── GET /ai/status
│   ├── GET /ai/tasks
│   └── POST /ai/feedback
└── 📁 Admin (optional)
    └── GET /admin/feedback
Environment Variables
json
{
  "base_url": "http://localhost:3000",
  "token": ""
}
Automatically set token after login:

javascript
if (pm.response.code === 200 || pm.response.code === 201) {
    pm.environment.set("token", pm.response.json().token);
}
🔧 n8n Workflow Setup
Step 1: Create Workflow
Open http://localhost:5678

Click New Workflow

Step 2: Add Webhook Node
HTTP Method: POST

Path: task-created

Production URL: http://localhost:5678/webhook/task-created

Step 3: Add Slack Node
Action: Send a Message

Channel: #general (or your channel)

Message:

New task: {{ $json.body.task.title }}
Description: {{ $json.body.task.description }}
Priority: {{ $json.body.task.priority }}
Due Date: {{ $json.body.task.due_date }}
Step 4: Connect and Publish
Drag connector from Webhook → Slack

Click Publish

Toggle Active to green

Step 5: Invite Slack Bot
In Slack:


/invite @TaskPlatformBot
🔔 Slack Integration
What Is Sent to Slack
When a task is created, the platform sends a JSON payload to n8n:

json
{
  "task": {
    "id": "abc-123-def",
    "title": "Define Campaign Objectives",
    "description": "Identify key campaign objectives and target audience",
    "due_date": "2024-01-01",
    "priority": "High",
    "creator": "alice@example.com"
  }
}
Purpose
Real‑time awareness: Team members see new tasks instantly.

Accountability: Creators and assignees are clearly identified.

Reduced friction: No need to check the app manually.

Integration: Slack becomes the notification hub for your team.

🛠️ Development
Running Tests
bash
bundle exec rspec
Code Style
bash
bundle exec rubocop
Database Management
bash
rails db:migrate
rails db:rollback
Console Access
bash
rails console
Neo4j Console
Open http://localhost:7474 and login with neo4j / password.

🚀 Deployment
Docker Production
bash
docker compose -f docker-compose.prod.yml up -d
Heroku
bash
heroku create task-platform
heroku addons:create heroku-postgresql
heroku addons:create rediscloud
heroku addons:create neo4j:essential-1
heroku config:set GROQ_API_KEY=...
heroku config:set SLACK_API_TOKEN=...
git push heroku main
VPS (DigitalOcean / AWS)
Install Docker, Ruby, Rails

Clone the repository

Set up environment variables

Run with Docker Compose

Add SSL with Let's Encrypt (Nginx reverse proxy)

🤝 Contributing
We welcome contributions! Please follow these steps:

Fork the repository

Clone your fork

Create a feature branch (git checkout -b feature/amazing-feature)

Commit your changes (git commit -m 'Add amazing feature')

Push to the branch (git push origin feature/amazing-feature)

Open a Pull Request

Contribution Guidelines
Use Ruby style guide (RuboCop)

Write tests for new features

Update documentation for changes

Keep commits atomic and descriptive

📄 License
This project is licensed under the MIT License – see the LICENSE file for details.

🙏 Acknowledgments
Groq for free LLM access

n8n for workflow automation

Neo4j for graph database

Slack for team notifications

🔗 Links

Blog Post: https://medium.com/@aitzazakmal/from-to-do-list-to-ai-agent-building-a-self-improving-task-platform-5eb166ec58e8

📊 Project Status

Component	Status
Authentication	✅ Complete
AI Planning (Sync)	✅ Complete
AI Planning (Async)	✅ Complete
Neo4j Integration	✅ Complete
n8n Automation	✅ Complete
Slack Notifications	✅ Complete
Feedback Collection	✅ Complete
Reflection Loop	✅ Complete
API Documentation	✅ Complete
Postman Collection	✅ Complete

Deployment Guide	⏳ In Progress
Web UI	⏳ Planned
WebRTC Integration	⏳ Planned


Built with ❤️ for the open‑source community.