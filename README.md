
## Why Outhad?

Outhad simplifies self-hosting a secure, scalable Reverse ETL platform on your cloud infrastructure like AWS, Azure, or GCP. With one-click deployment and customizable connectors, you can easily sync data from your warehouse to business tools.

## Getting Started

Outhad is a monorepo that consists of three main services:

- <b>server</b> - The backend service that acts as a control plane for managing data sources, models, and syncs.

- <b>ui</b> - The frontend react application that provides a user interface to manage data sources, destinations, and confgure syncs.

- <b>integrations</b> - A Ruby Gem that provides a framework to build connectors to support a wide range of data sources and destinations.

### Local Setup

To get started with Outhad, you can deploy the entire stack using Docker Compose.

1. **Clone the repository:**

```bash
git clone git@github.com:Outhad/outhad.git
```

2. **Go inside outhad folder:**

```bash
cd outhad
```

3. **Initialize .env file:**

```bash
mv .env.example .env
```

4. **Copy .env file to ui folder:**

```bash
cp .env ui/.env
```

5. **Setup git hooks:**

```bash
./git-hooks/setup-hooks.sh
```

6. **Start the services:**

```bash
docker-compose build && docker-compose up
```

UI can be accessed at the PORT 8000 :

```bash
http://localhost:8000
```
