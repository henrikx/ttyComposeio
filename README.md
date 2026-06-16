# TtyComposeio

A simple way to manage Docker-Compose homelab stacks in your web browser.

## Features

- **Web-based TUI Manager** - Access via browser using ttyd
- **Stack Management** - Start, stop, create, and edit Docker Compose stacks
- **Port Dashboard** - View all exposed ports across running containers
- **Live Logs** - Attach to container logs in real-time
- **Container Shell** - Execute interactive bash/sh sessions in running containers
- **Micro Editor** - Edit compose files with the lightweight Micro editor
- **Modular Design** - Clean separation of concerns with library modules

## Project Structure

```
ttyComposeio/
├── bin/
│   └── manager              # Entry point wrapper script
├── lib/
│   ├── constants.sh         # Configuration constants
│   ├── ui.sh               # Terminal UI utilities
│   ├── stacks.sh           # Docker Compose stack operations
│   ├── docker.sh           # Docker operations
│   └── editor.sh           # Text editor interactions
├── src/
│   └── main.sh             # Main application logic
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile              # Container image definition
└── README.md               # This file
```

## Quick Start

### Using Docker Compose

```bash
docker-compose up
```

Then access the web interface at `http://localhost:8080`

### Local Installation

Requirements:
- bash
- dialog
- docker-cli
- docker-cli-compose
- ttyd
- micro

```bash
./bin/manager
```

## Menu Options

1. **List Active Stacks (Status)** - View running containers and their status
2. **View Port Dashboard** - See all exposed ports
3. **Start a Stack** - Deploy a stack using `docker-compose up`
4. **Stop a Stack** - Stop a stack using `docker-compose down`
5. **Edit Stack Configuration** - Edit compose file with Micro editor
6. **View Container Logs** - Stream logs from running containers
7. **Create Stack & Data Folders** - Create new stack with data directories
8. **Open Terminal** - Interactive bash in stacks directory
9. **Execute Shell in Container** - Open interactive shell inside a container
10. **Exit** - Close the manager

## Stack Directory Structure

Stacks are located in `/opt/stacks` (or `STACKS_DIR` environment variable):

```
/opt/stacks/
├── mystack1/
│   ├── docker-compose.yml
│   ├── config/
│   └── data/
└── mystack2/
    ├── compose.yml
    └── data/
```

## Features Detail

### Container Shell Execution

When executing a shell in a container, the system automatically:
1. Attempts to use `/bin/bash` (better UX)
2. Falls back to `/bin/sh` if bash is unavailable
3. Provides clear error messages if neither is available

### Editor Integration

The application uses **Micro** as the primary editor:
- Lightweight and fast
- Intuitive keybindings (Ctrl+Q to quit, Ctrl+S to save)
- Syntax highlighting for YAML

Fallback to Nano if Micro is unavailable.

## Configuration

### Environment Variables

- `STACKS_DIR` - Directory containing compose stacks (default: `/opt/stacks`)
- `TEMP_DIR` - Temporary directory (default: `/tmp`)

### Dockerfile Customization

Edit `Dockerfile` to add additional tools or change the base image.

## Development

### Adding New Features

1. Create new module in `lib/` if needed
2. Add handler function in `src/main.sh`
3. Add menu option to main menu
4. Source new modules at the top of `src/main.sh`

### Code Organization

- **constants.sh** - All configuration in one place
- **ui.sh** - Reusable UI components
- **stacks.sh** - Stack-related operations
- **docker.sh** - Docker/container operations
- **editor.sh** - Editor utilities
- **main.sh** - Application orchestration

## License

MIT
