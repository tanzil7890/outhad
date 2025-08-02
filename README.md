<p align="center">
  <img src="https://res.cloudinary.com/dspflukeu/image/upload/v1714997618/AIS/outhad_-_logo_-_light_eewnz3.svg" alt="Outhad" width="228" />
</p>

<h1 align="center">Open Source Reverse ETL & Data Activation Platform</h1>

<p align="center">
Outhad is an open-source alternative to <b>HighTouch</b>, <b>Census</b>, and <b>RudderStack</b>. It lets you easily sync data from your warehouse to any business tool, unlocking the full potential of your data.
</p>


<p align="center">
<a href="https://github.com/Outhad/outhad/stargazers"><img src="https://img.shields.io/github/stars/Outhad/outhad?style=for-the-badge" alt="GitHub stars"></a>
<a href="https://github.com/Outhad/outhad/releases">
  <img src="https://img.shields.io/github/v/release/Outhad/outhad?display_name=release&style=for-the-badge" alt="GitHub release (latest)">
</a>
  <a href="https://github.com/Outhad/outhad/graphs/commit-activity"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/Outhad/outhad/main?style=for-the-badge"></a>
  <a href="https://github.com/Outhad/outhad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Outhad/outhad?style=for-the-badge" alt="License"></a>
  <br />
  <a href="https://github.com/Outhad/outhad/actions/workflows/server-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Outhad/outhad/server-ci.yml?branch=main&style=for-the-badge&label=server-build" alt="server-ci"></a>
  <a href="https://github.com/Outhad/outhad/actions/workflows/integrations-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Outhad/outhad/integrations-ci.yml?branch=main&style=for-the-badge&label=integrations-build" alt="integrations-ci"></a>
  <a href="https://github.com/Outhad/outhad/actions/workflows/ui-ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Outhad/outhad/ui-ci.yml?branch=main&style=for-the-badge&label=ui-build" alt="ui-ci"></a>
</p>

<p align="center">
  <a href="https://qlty.sh/gh/Outhad/projects/outhad">
    <img src="https://qlty.sh/badges/133d1667-dc6e-4ede-8601-3120be5f175e/maintainability.svg" alt="Maintainability" /></a>
  <a href="https://qlty.sh/gh/Outhad/projects/outhad">
    <img src="https://qlty.sh/badges/133d1667-dc6e-4ede-8601-3120be5f175e/coverage.svg" alt="Code Coverage" /></a>
  </a>
</p>

<p align="center">
    <br />
    <a href="https://docs.squared.ai/open-source/introduction" rel=""><strong>Explore the docs »</strong></a>
    <br />
  <br/>
  <a href="https://join.slack.com/t/outhad/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g">Slack</a>
   •
    <a href="https://squared.ai/outhad-reverse-etl">Website</a>
    •
    <a href="https://blog.squared.ai">Blog</a>
   •
    <a href="https://github.com/orgs/Outhad/projects/4">Roadmap</a>
  </p>

  <hr />

## Why Outhad?

Outhad simplifies self-hosting a secure, scalable Reverse ETL platform on your cloud infrastructure like AWS, Azure, or GCP. With one-click deployment and customizable connectors, you can easily sync data from your warehouse to business tools.

⭐ *Consider giving us a star! Your support helps us continue innovating and adding new, exciting features.*

### Connect to sources

Connect to your data sources like Databricks, Redshift, BigQuery, and more.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Sources_ttijzv.png "Sources")

### Prepare your data

Create models to transform and prepare your data for syncing.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Models_ee7as8.png "Example Title")

### Sync with destinations

Sync your data with destinations like Salesforce, HubSpot, Slack, and more.

![Example Image](https://res.cloudinary.com/dspflukeu/image/upload/v1716464797/AIS/Destinations_ebpt0n.png "Example Title")


## Table of Contents

- [Getting Started](#getting-started)
  - [Local Setup](#local-setup)
  - [Self-hosted Options](#self-hosted-options)
- [Connectors](#connectors)
  - [Sources](#sources)
  - [Destinations](#destinations)
    - [CRM](#crm)
    - [Marketing Automation](#marketing-automation)
    - [Customer Support](#customer-support)
    - [Advertising](#advertising)
    - [Collaboration](#collaboration)
    - [Analytics](#analytics)
    - [Others](#others)
- [Contributing](#contributing)
- [Need Help?](#need-help)
  - [Development Status: Under Active Development](#️-development-status-under-active-development)
- [License](#license)
- [Contributors](#contributors)

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

For more details, check out the local [deployment guide](https://docs.squared.ai/open-source/guides/setup/docker-compose-dev) in the documentation.

### Self-hosted Options

Outhad can be deployed in a variety of environments, from fully managed cloud services to self-hosted solutions. Refer to the deployment guides below to deploy Outhad on your preferred cloud provider.

| Provider                          | Documentation                                                               |
| :-------------------------------- | :-------------------------------------------------------------------------- |
| **Docker**                        | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/docker-compose) |
| **Helm Charts**                   | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/helm)           |
| **AWS EC2**                       | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/ec2)            |
| **AWS ECS**                       | Coming soon.                                                       |
| **AWS EKS (Kubernetes)**          | Coming soon.                                                      |
| **Azure VMs**                     | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/avm)                                                       |
| **Azure AKS (Kubernetes)**        | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/aks)            |
| **Google Cloud GKE (Kubernetes)** | Coming soon.                                                             |
| **Google Cloud Compute Engine**   | [Deployment Guide](https://docs.squared.ai/open-source/guides/setup/gce)            |
| **Digital Ocean Droplets**        | Coming soon.                                                        |
| **Digital Ocean Kubernetes**      | Coming soon.                                                             |
| **OpenShift**                     | Coming soon.                                                             |

## Connectors

🔥 Outhad is rapidly expanding its list of connectors to support a wide range of data sources and destinations. Head over to the [Integrations](https://github.com/Outhad/outhad/tree/main/integrations) directory to explore the available connectors. If you don't see the connector you need, please [open an issue](https://github.com/Outhad/outhad/issues) to request it.

### Sources

- [x] [Amazon Redshift](https://docs.squared.ai/guides/data-integration/sources/redshift)
- [x] [Google BigQuery](https://docs.squared.ai/guides/data-integration/sources/bquery)
- [x] [Snowflake](https://docs.squared.ai/guides/data-integration/sources/snowflake)
- [x] [Databricks](https://docs.squared.ai/guides/data-integration/sources/databricks)
- [x] [PostgreSQL](https://docs.squared.ai/guides/data-integration/sources/postgresql)

### Destinations

#### CRM

- [x] [Salesforce](https://docs.squared.ai/guides/data-integration/destinations/crm/salesforce)
- [ ] Zoho CRM
- [x] [HubSpot](https://docs.squared.ai/guides/data-integration/destinations/crm/hubspot)

#### Marketing Automation

- [x] [Klaviyo](https://docs.squared.ai/guides/data-integration/destinations/marketing-automation/klaviyo)
- [ ] Braze
- [ ] Salesforce Marketing Cloud

#### Customer Support

- [x] [Zendesk](https://docs.squared.ai/guides/data-integration/destinations/customer-support/zendesk)
- [ ] Freshdesk
- [ ] Intercom

#### Advertising

- [ ] Google Ads
- [x] [Facebook Ads](https://docs.squared.ai/guides/data-integration/destinations/adtech/facebook-ads)

#### Collaboration

- [x] [Slack](https://docs.squared.ai/guides/data-integration/destinations/team-collaboration/slack)
- [x] [Google Sheets](https://docs.squared.ai/guides/data-integration/destinations/productivity-tools/google-sheets)
- [x] [Airtable](https://docs.squared.ai/guides/data-integration/destinations/productivity-tools/airtable)

#### Analytics

- [x] Google Analytics
- [ ] Mixpanel
- [ ] Amplitude

#### Others

🧵...Weaving in more connectors to support a wide range of destinations.

## Contributing

We ❤️ contributions and feedback! Help make Outhad better for everyone!

Before contributing to Outhad, please read our [Code of Conduct](https://github.com/Outhad/outhad/blob/main/CODE_OF_CONDUCT.md) and [Contributing Guidelines](https://github.com/Outhad/outhad/blob/main/CONTRIBUTING.md). As a contributor, you are expected to adhere to these guidelines and follow the best practices.

## Need Help?

If you have any questions or need help with Outhad, please feel free to reach out to us on [Slack](https://join.slack.com/t/outhad/shared_invite/zt-2bnjye26u-~lu_FFOMLpChOYxvovep7g). We are open to discuss new ideas, features, and improvements.

### ⚠️ Development Status: Under Active Development

This project is under active development, As we work towards stabilizing the project, you might encounter some bugs or incomplete features. We greatly value your contributions and patience during this phase. Thank you for your support!

## Contributors

<a href="https://github.com/Outhad/outhad/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Outhad/outhad&max=400&columns=20" />
</a>

## License

Outhad is licensed under the AGPLv3 License. See the [LICENSE](https://github.com/Outhad/outhad/blob/main/LICENSE) file for details.
