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

# Execute shell in a container with bash/sh fallback
# Args: container_name
docker_exec_shell() {
    local container_name="$1"
    
    ui_set_title "Shell: ${container_name}"
    ui_clear
    echo "========================================================"
    echo " Opening Shell in Container: $container_name"
    echo "========================================================"
    echo " -> Type 'exit' and press [Enter] to return to the TUI."
    echo "--------------------------------------------------------"
    echo ""
    
    # Try bash first, fallback to sh
    if docker exec -it "$container_name" test -x /bin/bash 2>/dev/null; then
        docker exec -it "$container_name" /bin/bash
    elif docker exec -it "$container_name" test -x /bin/sh 2>/dev/null; then
        docker exec -it "$container_name" /bin/sh
    else
        ui_show_msgbox "Error" "Neither /bin/bash nor /bin/sh found in container."
        return 1
    fi
    
    echo ""
    read -p "Shell session ended. Press [Enter] to return to the menu..."
}
