
## Outhad Integrations

Outhad integrations is the collection of connectors built on top of [Outhad protocol]

Outhad protocol is an open source standard for moving data between data sources to any third-part destinations.
Anyone can build a connetor with basic ruby knowledge using the protocol.

## Prerequisites

Before you begin the installation, ensure you have the following dependencies installed:

- **MySQL Client**
  - Command: `brew install mysql-client`
  - Description: Required for database interactions.

- **Zstandard (zstd)**
  - Command: `brew install zstd`
  - Description: Needed for data compression and decompression.

- **OpenSSL 3**
  - Command: `brew install openssl@3`
  - Description: Essential for secure communication.

- **Oracle Instant Client**
  - Download Link: https://www.oracle.com/database/technologies/instant-client/downloads.html
  - Description: Required for database interactions.


### Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add outhad-integrations


### Usage

#### Source
```
source = Outhad::Integrations::Source::[CONNECTOR_NAME]::Client.new
source.read(sync_config)
```
#### Destination

```
destination = Outhad::Integrations::Destination::[CONNECTOR_NAME]::Client.new
destination.write(sync_config, records)
```

#### Supported methods 
Please refer [Outhad Protocol](https://docs.outhad.com/guides/architecture/outhad-protocol) to understand more about the supported methods on source and destination

## Development

- **Install Dependencies**
  - Command: `bin/setup`
  - Description: After checking out the repo, run this command to install dependencies.

- **Run Tests**
  - Command: `rake spec`
  - Description: Run this command to execute the tests.

- **Interactive Prompt**
  - Command: `bin/console`
  - Description: For an interactive prompt that allows you to experiment, run this command.

- **Install Gem Locally**
  - Command: `bundle exec rake install`
  - Description: To install this gem onto your local machine, run this command.

- **Release New Version**
  - Steps:
    1. Update the version number in `rollout.rb`.
    2. Command: `bundle exec rake release`
    3. Description: This command will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

