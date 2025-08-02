
## Outhad Server
**Outhad Server**  repository contains the backend codebase for the Outhad platform. It is built using Ruby on Rails and Temporal Workflow Engine. The server is responsible for handling the API requests, managing the data sync workflows, and orchestrating the data sync jobs.


## Technology Stack

The Outhad Server is built using the following technologies:

- **Ruby on Rails**: The server is built using Ruby on Rails, a popular web application framework.
- **Temporal Workflow Engine**: Temporal is an open-source, stateful, and scalable workflow orchestration platform for developers. It is used to manage the data sync workflows and orchestrate the data sync jobs.
- **PostgreSQL**: The server uses PostgreSQL as the primary database to store the application data.
- **Docker**: The server is deployed using Docker containers.

## Outhad Server - Dependencies Installation


### macOS Installation (Using Homebrew)

#### 1. Install Oracle Instant Client (version 19.8.0.0)
```bash
# Add the Oracle Instant Client tap
brew tap InstantClientTap/instantclient

# Install the basic package
brew install instantclient-basic

# Install the SDK package (required for ruby-oci8 gem)
brew install instantclient-sdk

# Verify installation
ls -la /opt/homebrew/Cellar/instantclient-basic/19.8.0.0.0dbru/lib
```

#### 2. Install DuckDB
```bash
brew install duckdb
```

#### 3. Set Environment Variables
Add these lines to your shell profile file (e.g., `~/.zshrc` or `~/.bash_profile`):
```bash
# Oracle Instant Client configuration
export OCI_DIR=/opt/homebrew/Cellar/instantclient-basic/19.8.0.0.0dbru
export DYLD_LIBRARY_PATH=/opt/homebrew/Cellar/instantclient-basic/19.8.0.0.0dbru/lib:$DYLD_LIBRARY_PATH
export ORACLE_HOME=/opt/homebrew/Cellar/instantclient-basic/19.8.0.0.0dbru
export OCI_LIB_DIR=$OCI_DIR/lib
export OCI_INC_DIR=$OCI_DIR/sdk/include
```

#### 4. Apply Environment Variables
```bash
# Reload your shell configuration
source ~/.zshrc  # or source ~/.bash_profile
```

#### 5. Install Ruby Dependencies
```bash
# Install the ruby-oci8 gem
gem install ruby-oci8

# Install all project dependencies
bundle install
```

#### Notes:
- If you encounter any issues with the `ruby-oci8` gem installation, ensure the SDK package is properly installed and the environment variables are correctly set.
- The version numbers might change over time. Adjust paths accordingly if you install a different version.
- For Apple Silicon Macs, the paths might differ from Intel Macs. Verify the actual installation paths if needed.

---

### Ubuntu Installation

#### 1. Install Oracle Instant Client
```bash
sudo apt update
sudo apt install -y libaio1 unzip

# Download Oracle Instant Client from Oracle's website (requires login)
wget https://download.oracle.com/otn_software/linux/instantclient/198000/instantclient-basic-linux.x64-19.8.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/198000/instantclient-sdk-linux.x64-19.8.0.0.0dbru.zip

# Unzip and move to /opt
sudo unzip instantclient-basic-linux.x64-19.8.0.0.0dbru.zip -d /opt
sudo unzip instantclient-sdk-linux.x64-19.8.0.0.0dbru.zip -d /opt

# Create a symbolic link
sudo ln -s /opt/instantclient_19_8 /opt/instantclient
```

#### 2. Install DuckDB
```bash
sudo apt install -y duckdb
```

#### 3. Set Environment Variables
Add these lines to your shell profile file (e.g., `~/.bashrc` or `~/.profile`):
```bash
# Oracle Instant Client configuration
export OCI_DIR=/opt/instantclient
export LD_LIBRARY_PATH=/opt/instantclient:$LD_LIBRARY_PATH
export ORACLE_HOME=/opt/instantclient
export OCI_LIB_DIR=$OCI_DIR
export OCI_INC_DIR=$OCI_DIR/sdk/include
```

#### 4. Apply Environment Variables
```bash
# Reload your shell configuration
source ~/.bashrc  # or source ~/.profile
```

#### 5. Install Ruby Dependencies
```bash
# Install required packages
sudo apt install -y ruby ruby-dev build-essential

# Install the ruby-oci8 gem
gem install ruby-oci8

# Install all project dependencies
bundle install
```

#### Notes:
- If you face issues with `ruby-oci8`, ensure that `libaio1` is installed and environment variables are correctly set.
- Adjust paths accordingly if Oracle releases a different version.
- Ensure you have `unzip` installed before extracting the Oracle packages.

## Local Setup

To deploy the Outhad Server locally, follow the steps below:

1. **Clone the repository:**

```bash
git clone git@github.com:Outhad/outhad-server.git
```

2. **Go inside outhad-server folder:**

```bash
cd outhad-server
```

3. **Initialize .env file:**

```bash
mv .env.example .env
```

4. **Start the services:**

```bash
docker-compose build && docker-compose up
```

5. **Access the application:**

```bash
http://localhost:3000
```
