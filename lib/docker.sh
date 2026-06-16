#!/bin/bash

# TtyComposeio - Docker Module
# Handles Docker and Docker Compose operations

# Get formatted port map
# Returns: formatted port information
docker_get_port_map() {
    {
        echo "CONTAINER NAME           | ASSIGNED PORTS"
        echo "----------------------------------------------------"
        docker ps --format "{{.Names}}|||{{.Ports}}" 2>/dev/null | while IFS="|||" read -r name ports; do
            if [ -z "$ports" ]; then
                local clean_ports="None"
            else
                local clean_ports
                clean_ports=$(echo "$ports" | sed -E 's/0.0.0.0://g; s/:::([0-9]+->[0-9]+\/(tcp|udp))(, )?//g; s/\/tcp//g; s/\/udp//g')
            fi
            printf "%-24s | %s\n" "$name" "$clean_ports"
        done
    }
}

# Select a running container
# Args: title, prompt
# Returns: container name
docker_select_container() {
    local title="$1"
    local prompt="$2"
    
    local containers
    containers=$(docker ps --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$containers" ]; then
        ui_show_msgbox "$title" "No running containers found."
        return 1
    fi
    
    local menu_items=()
    while read -r name; do
        if [ -n "$name" ]; then
            menu_items+=("$name" "Running Container")
        fi
    done <<< "$containers"
    
    ui_show_menu "$title" "$prompt" "${menu_items[@]}"
}

# Get services from a docker-compose file
# Args: compose_file
# Returns: list of service names
docker_compose_get_services() {
    local compose_file="$1"
    
    if [ ! -f "$compose_file" ]; then
        return 1
    fi
    
    # Extract service names from docker-compose file
    grep -E '^\s+[a-zA-Z0-9_-]+:\s*$' "$compose_file" | sed 's/[[:space:]:]//g' | head -20
}

# Get running container names for a specific stack
# Args: stack_name, compose_file
# Returns: list of running container names for that stack
docker_compose_get_running_services() {
    local stack_name="$1"
    local compose_file="$2"
    
    # Get project name from directory or stack name
    local project_name
    project_name=$(basename "$(dirname "$compose_file")")
    
    # List containers belonging to this compose project
    docker ps --filter "label=com.docker.compose.project=$project_name" --format "{{.Names}}" 2>/dev/null
}

# Select a service from a docker-compose stack
# Args: stack_name, compose_file, title, prompt
# Returns: container name
docker_compose_select_service() {
    local stack_name="$1"
    local compose_file="$2"
    local title="$3"
    local prompt="$4"
    
    local containers
    containers=$(docker_compose_get_running_services "$stack_name" "$compose_file")
    
    if [ -z "$containers" ]; then
        ui_show_msgbox "$title" "No running services found for stack: $stack_name"
        return 1
    fi
    
    local menu_items=()
    while read -r name; do
        if [ -n "$name" ]; then
            menu_items+=("$name" "Service Container")
        fi
    done <<< "$containers"
    
    if [ ${#menu_items[@]} -eq 0 ]; then
        ui_show_msgbox "$title" "No running services found for stack: $stack_name"
        return 1
    fi
    
    ui_show_menu "$title" "$prompt" "${menu_items[@]}"
}

# Execute shell in a service container using docker compose exec with bash/sh fallback
# Args: compose_file, container_name
docker_compose_exec_shell() {
    local compose_file="$1"
    local container_name="$2"
    
    ui_set_title "Shell: ${container_name}"
    ui_clear
    echo "=========================================================="
    echo " Opening Interactive Shell in Container: $container_name"
    echo "=========================================================="
    echo " -> Type 'exit' and press [Enter] to return to the TUI."
    echo "----------------------------------------------------------"
    echo ""
    
    # Try bash first, fallback to sh
    if docker compose -f "$compose_file" exec "$container_name" test -x /bin/bash 2>/dev/null; then
        docker compose -f "$compose_file" exec -it "$container_name" /bin/bash
    elif docker compose -f "$compose_file" exec "$container_name" test -x /bin/sh 2>/dev/null; then
        docker compose -f "$compose_file" exec -it "$container_name" /bin/sh
    else
        ui_show_msgbox "Error" "Neither /bin/bash nor /bin/sh found in container '$container_name'."
        return 1
    fi
    
    echo ""
    read -p "Shell session ended. Press [Enter] to return to the menu..."
}
