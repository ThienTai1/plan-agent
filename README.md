# Planning Agent Monorepo

Welcome to the **Planning Agent Monorepo**! This repository hosts the complete, unified codebase of the **Planning Agent** — an advanced, production-grade, AI-powered personal planning and scheduling assistant ecosystem designed to deliver cognitive automation, intelligent task orchestration, and seamless calendar management.

By combining cutting-edge AI architectures with a robust enterprise-ready microservices layout, the Planning Agent ecosystem integrates:
* **Advanced Multi-Agent Orchestration:** Powered by **LangGraph** and **LangChain** in `agent-orchestrator`, supporting stateful multi-turn reasoning, streaming responses, and real-time distributed tool execution on the client.
* **Type-Safe Prompt Engineering & Structured Outputs:** Powered by **BoundaryML (BAML)** in `agent-prototype-baml` to deliver high-performance, structured LLM parses and robust, reliable outputs.
* **Reactive Flutter Client:** A modern Riverpod-architected, offline-ready, cross-platform Flutter application with a smooth, high-fidelity user interface supporting real-time assistant chat, task scheduling, and user profile management.
* **Modular Microservices Infrastructure:** A secure gateway and BFF (Backend-for-Frontend) built on **FastAPI**, connecting calendar integrations, JWT-based authentication, and shared common libraries (`libs/python-common`).
* **Production-Ready Deployment Configurations:** Fully containerized Docker Compose configurations for local development and scalable Kubernetes manifests for high-availability cloud deployments.

This repository is structured as a monorepo to ensure tight synchronization, streamlined dependency management, and a secure, enterprise-grade developer experience.

---

## 📁 Repository Directory Structure

```text
.
├── apps/
│   ├── frontend/              # 📱 Flutter mobile application (Frontend Client)
│   ├── agent-orchestrator/    # 🤖 Production AI Agent Orchestrator (LangGraph)
│   ├── agent-prototype-baml/  # 🧪 Legacy/Prototype AI Agent (BAML)
│   ├── calendar-service/      # 📅 Calendar Integration Service (Google Calendar, etc.)
│   └── auth-service/          # 🔑 Authentication Service
├── libs/
│   ├── python-common/         # 📦 Shared Python Library (config, logging, schemas)
│   └── api-contracts/         # 📑 OpenAPI Contracts shared across teams
├── infra/
│   ├── docker/                # 🐳 Dockerfiles per microservice
│   ├── k8s/                   # ☸️ Kubernetes Deployment Manifests
│   └── scripts/               # 🛠️ Operation Helper Scripts (dev_up/dev_down)
├── .env.example               # 📄 Core Environment Variable Template
└── README.md                  # 📘 This documentation file
```

Each Python-based microservice implements a standardized layout under the `app/` folder for consistency and easy onboarding:
```text
app/
├── main.py            # FastAPI Entry Point
├── api/               # Routers containing endpoints organized by domain/version
├── core/              # Configuration and Logger helpers
├── models/            # Pydantic models describing service request/response API contracts
├── services/          # HTTP/RPC clients for cross-service communication
└── ...                # Service-specific directories (agent/, db/, providers/, ...)
```

---

## 🔒 Security & Environment Variable Configuration

To secure sensitive keys and access tokens (such as OpenAI/Gemini/OpenRouter API Keys, PostgreSQL passwords, and Supabase credentials), this codebase utilizes strict security rules. Actual configuration files are blocked by Git to prevent public exposure. 

To run the applications locally, copy and configure the respective templates:

### 1. Root Configuration Setup
Copy the core environment variable template at the root directory and configure it:
```bash
cp .env.example .env
```

### 2. Backend Microservices Configuration Setup
* **Agent Orchestrator:**
  ```bash
  cd apps/agent-orchestrator
  cp .env.example .env
  ```
* **Agent Prototype BAML:**
  ```bash
  cd apps/agent-prototype-baml
  cp .env.example .env
  ```
*(Open the newly created `.env` files and supply your real API Keys and connection strings).*

### 3. Flutter Frontend Configuration Setup
Create the localized secrets configuration file for the mobile application:
```bash
cd apps/frontend/lib/core/secrets
cp app_secrets.dart.example app_secrets.dart
```
Edit `app_secrets.dart` and replace the placeholder values with your actual project keys:
```dart
class AppSecrets {
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const revenueCatApiKey = 'YOUR_REVENUE_CAT_API_KEY';
}
```

---

## 🚀 Getting Started & Local Development

### System Requirements
Before running the system, please ensure you have the following tools installed:
* **Python** (version >= 3.10) with [uv](https://github.com/astral-sh/uv) package manager.
* **Flutter SDK** (for running the Flutter mobile application).
* **Docker Desktop** (for running the containerized infrastructure).

### Running the Services

#### Step 1: Install & Sync the Shared Python Library
Navigate to the shared library directory, sync the packages, and establish an editable environment:
```bash
cd libs/python-common
uv sync
```

#### Step 2: Install Microservice Dependencies
To run any Python service under the `apps/` directory, navigate to the specific service folder and sync packages:
```bash
cd apps/agent-orchestrator # Example service
uv sync
```

#### Step 3: Run the Backend Services Stack
We provide automated helper scripts located in the `infra/scripts/` directory to quickly spin up dependencies (FastAPI, PostgreSQL, Redis, RabbitMQ, etc.):
```bash
# Start the complete backend container stack
./infra/scripts/dev_up.sh

# Stop and tear down all container resources
./infra/scripts/dev_down.sh
```
If you wish to spin up a single service directly in reload mode for debugging:
```bash
uv run uvicorn app.main:app --reload
```

#### Step 4: Run the Flutter Mobile Application
Navigate to the frontend directory, install Flutter packages, and launch the application on a simulator or physical device:
```bash
cd apps/frontend
flutter pub get
flutter run
```

---

## ☁️ Secure GCP Cloud Run Deployment

To deploy the production-ready `agent-orchestrator` service to Google Cloud Run, we provide a smart deployment script located at [deploy.sh](file:///Users/taipham/Projects/planning_agent/planning_agent/apps/agent-orchestrator/scripts/deploy.sh).

This script dynamically queries your local active GCP project authenticated in the `gcloud` CLI instead of utilizing hardcoded keys:

```bash
# Navigate to the deployment scripts folder
cd apps/agent-orchestrator/scripts

# Grant execution permissions and run deployment
chmod +x deploy.sh
./deploy.sh
```

---

## 🛠️ Code Quality & Tooling

* **Python:** Uses `ruff` for fast linting and formatting. Unit and integration test suites are written and verified with `pytest`.
* **Flutter:** Follows static Dart code rules configured in the localized `analysis_options.yaml` file in the frontend folder.
* **Shared Logic:** Core modules regarding logging, shared configurations, and mutual schemas must be developed in the `libs/python-common/` directory to prevent duplications.

Have a great time hacking and developing on the Planning Agent! If you run into any issues, please open an issue or reach out to the development team directly.
