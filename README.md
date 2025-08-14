# Multi-Tenant Docker Provisioner



<p align="center">
  A robust boilerplate for creating on-demand, temporary, and isolated application environments using Docker and Traefik.
</p>



---

## 📋 Table of Contents

1.  [Overview & Key Features](#-overview--key-features)
2.  [Prerequisites](#-prerequisites)
3.  [Installation Guide](#-installation-guide)
4.  [Usage and Management](#-usage-and-management)
5.  [Appendix A: Application Gotchas](#-appendix-a-application-gotchas)
6.  [Appendix B: Application Dockerization](#-appendix-b-application-dockerization)

---

## 🌟 Overview & Key Features

This system is designed to be triggered by an external system (like WHMCS) to provide potential customers with a personal demo environment for any containerized web application.

-   **🐳 Containerized & Isolated:** All services (application, database) run in their own Docker containers.
-   **🔁 Automated Routing:** Traefik acts as a reverse proxy, automatically routing traffic to new demo instances based on a unique subdomain (e.g., `instance-name.your-domain.com`).
-   **⚙️ Full Lifecycle Management:** A suite of shell scripts handles the entire lifecycle of an instance: creation, teardown, and cleanup.
-   **🕒 Ephemeral by Design:** A cron job automates the cleanup process, destroying instances after a predefined lifetime (e.g., 24/48 hours).

---

## ✅ Prerequisites

Before starting, ensure you have the following:

1.  **A Clean Virtual Machine:** A server running a modern Linux distribution. This guide assumes **Ubuntu 22.04 LTS**.
2.  **A Domain Name:** You must own a domain name (e.g., `demo.your-company.com`) that you can manage DNS for.
3.  **DNS Provider Access:** You need the ability to add `A` records for the domain and for a wildcard subdomain.
4.  **Application Docker Image:** A working Docker image of your application pushed to a container registry (e.g., Docker Hub).

---

## 🚀 Installation Guide

This guide walks through setting up the server from a blank slate.

### Step 1: Install Docker and Docker Compose

These steps prepare the server to run containers.

1.  **Update the System:**
    ```bash
    sudo apt-get update && sudo apt-get upgrade -y
    ```
2.  **Install Docker Engine & Compose:**
    ```bash
    # Install prerequisite packages
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key and repository
    curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine and Compose
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    ```
3.  **Add Your User to the `docker` Group (Optional but Recommended):**
    This allows you to run `docker` commands without `sudo`.
    ```bash
    sudo usermod -aG docker ${USER}
    # You will need to log out and log back in for this change to take effect.
    newgrp docker
    ```

### Step 2: Deploy Traefik Reverse Proxy

This is a one-time setup for the "traffic cop" of our system.

1.  **Set Up DNS Records:**
    In your DNS provider, create two `A` records pointing to your VM's public IP address:
    -   **Record 1 (Main Domain):** Host: `your-domain.com`, Value: `[Your VM's IP]`
    -   **Record 2 (Wildcard):** Host: `*`, Value: `[Your VM's IP]`

2.  **Create Traefik Files:**
    Create a directory (`/opt/traefik`) and place the configuration files from the `traefik/` directory of this repository inside it.

    > **Note:** Ensure the `acme.json` file has strict permissions.
    > ```bash
    > sudo chmod 600 /opt/traefik/acme.json
    > ```

3.  **Start Traefik:**
    ```bash
    cd /opt/traefik
    docker-compose up -d
    ```

4.  **Verify Traefik:**
    -   Check that the container is running: `docker ps`
    -   Access the dashboard in your browser: `http://<Your_VM_IP>:8080`

### Step 3: Deploy the Provisioning Scripts

1.  **Copy Scripts to Server:**
    Copy the contents of the `app/` directory from this repository to `/opt/app-provisioner` on your server.

2.  **Make Scripts Executable:**
    ```bash
    cd /opt/app-provisioner
    chmod +x *.sh
    ```

3.  **Create Tracking Directory:**
    ```bash
    mkdir -p /opt/app-provisioner/instance_tracker
    ```

### Step 4: Automate Cleanup with Cron

1.  **Open the Crontab Editor:**
    ```bash
    crontab -e
    ```

2.  **Add the Cleanup Job:**
    Add this line to the bottom of the file. This will run the cleanup script every hour and log its output.
    ```crontab
    0 * * * * /opt/app-provisioner/cleanup_expired_instances.sh >> /var/log/app_provisioner_cleanup.log 2>&1
    ```

---

## 🛠️ Usage and Management

All commands should be run from `/opt/app-provisioner` on the server.

### Creating an Instance

```bash
# Usage: ./setup_instance.sh <instance-name>
./setup_instance.sh customer-alpha
```
The script will output a JSON block with the instance URL and credentials.

Destroying an Instance Manually
Bash

### Usage: ./teardown_instance.sh <instance-name>
./teardown_instance.sh customer-alpha
Listing Active Instances
Bash

./list_instances.sh
Extending an Instance's Lifetime
This resets the 24/48-hour cleanup timer.

Bash

### Usage: ./extend_instance.sh <instance-name>
./extend_instance.sh customer-alpha

---


## Appendix A: Application Gotchas

Some applications may have specific requirements or configurations that need to be addressed.

### Forcing HTTPS for Mixed Content Errors
When using Traefik to handle SSL, your application may still generate insecure http:// links for assets (CSS, JS). This is a "Mixed Content" error. The most reliable solution is to force HTTPS at the application level.

### Code Change (Example for Laravel):
Edit app/Providers/AppServiceProvider.php in your application's source code.

```PHP

// app/Providers/AppServiceProvider.php
use Illuminate\Support\Facades\URL;

public function boot(): void {
    // Force HTTPS if the FORCE_HTTPS env var is true
    if (env('FORCE_HTTPS', false)) {
        URL::forceScheme('https');
    }
}
```

Deployment Change:
In app/setup_instance.sh, ensure you pass the FORCE_HTTPS environment variable to your docker run command.

```Bash

docker run -d \
  # ... other flags
  -e "FORCE_HTTPS=true" \
  -e APP_URL="https://${INSTANCE_DOMAIN}" \
  # ... other flags
  "$APP_IMAGE"
```

Important: This requires rebuilding and pushing a new version of your application's Docker image.

## Appendix B: Application Dockerization
The Laravel-Project/ directory in this repository provides a working template for containerizing a PHP/Laravel application. These files belong with your application's source code, not on the production server. Refer to the files in that directory for the complete code.

Dockerfile: The main recipe for building your application image.

docker/vhost.conf: Apache virtual host configuration.

docker/supervisord.conf: Supervisor process manager configuration.

docker/entrypoint.sh: A critical runtime script that runs every time a container starts.
