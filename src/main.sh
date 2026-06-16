#!/bin/bash

# TtyComposeio - Web-based Docker Compose Manager
# Main entry point

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source library modules
source "$PROJECT_ROOT/lib/constants.sh"
source "$PROJECT_ROOT/lib/ui.sh"
source "$PROJECT_ROOT/lib/stacks.sh"
source "$PROJECT_ROOT/lib/docker.sh"
source "$PROJECT_ROOT/lib/editor.sh"

# Initialize
ui_init
mkdir -p "$STACKS_DIR"

# Main menu loop
main_menu() {
    while true; do
        ui_set_title "TtyComposeio Manager"
        
        local choice
        choice=$(ui_show_menu \
            "Main Menu" \
            "Choose an action:" \
            1 "List Active Stacks (Status)" \
            2 "View Port Dashboard (Assigned Ports)" \
            3 "Start a Stack (Up & Follow Progress)" \
            4 "Stop a Stack (Down)" \
            5 "Edit Stack Configuration (Micro)" \
            6 "View Container Logs / Attach" \
            7 "Create Stack & Data Folders" \
            8 "Open Terminal in Stacks Directory" \
            9 "Execute Shell in Container" \
            10 "Exit")
        
        if [ $? -ne 0 ]; then
            break
        fi
        
        case $choice in
            1) handle_list_stacks ;;
            2) handle_port_dashboard ;;
            3) handle_start_stack ;;
            4) handle_stop_stack ;;
            5) handle_edit_stack ;;
            6) handle_view_logs ;;
            7) handle_create_stack ;;
            8) handle_terminal_shell ;;
            9) handle_container_shell ;;
            10) break ;;
        esac
    done
    
    ui_cleanup
}

# Handler functions
handle_list_stacks() {
    ui_set_title "TUI: Active Stacks Status"
    docker ps --format "table {{.Names}}\t{{.Status}}" > /tmp/docker_ps.txt
    ui_show_textbox "Active Stacks Status" /tmp/docker_ps.txt
}

handle_port_dashboard() {
    ui_set_title "TUI: Port Map Dashboard"
    docker_get_port_map > /tmp/docker_ports.txt
    ui_show_textbox "Port Map Dashboard" /tmp/docker_ports.txt
}

handle_start_stack() {
    local stack_name
    stack_name=$(stacks_select_from_list "Start Stack" "Select stack to start:")
    
    if [ -n "$stack_name" ]; then
        local compose_file
        compose_file=$(stacks_get_compose_file "$stack_name")
        
        ui_set_title "Deploying: ${stack_name}"
        ui_clear
        echo "========================================================"
        echo " Deploying Stack: $stack_name"
        echo "========================================================"
        echo " -> Streaming build output, network downloads, and pulling..."
        echo " -> Once fully running, press [Ctrl + C] to return to TUI."
        echo "    (Containers will remain active in the background)"
        echo "--------------------------------------------------------"
        echo ""
        
        docker compose -f "$compose_file" up
        
        echo ""
        read -p "Returned from stream. Press [Enter] to reload the menu..."
    fi
}

handle_stop_stack() {
    local stack_name
    stack_name=$(stacks_select_from_list "Stop Stack" "Select stack to stop:")
    
    if [ -n "$stack_name" ]; then
        local compose_file
        compose_file=$(stacks_get_compose_file "$stack_name")
        
        ui_set_title "Stopping: ${stack_name}"
        docker compose -f "$compose_file" down > /tmp/docker_out.txt 2>&1
        ui_show_textbox "Result" /tmp/docker_out.txt
    fi
}

handle_edit_stack() {
    local stack_name
    stack_name=$(stacks_select_from_list "Edit Stack Configuration" "Select stack to edit:")
    
    if [ -n "$stack_name" ]; then
        ui_set_title "Editing: ${stack_name}"
        ui_clear
        
        local compose_file
        compose_file=$(stacks_get_compose_file "$stack_name")
        
        # Ensure file exists
        touch "$compose_file"
        
        editor_open_micro "$compose_file"
    fi
}

handle_view_logs() {
    local container_name
    container_name=$(docker_select_container "View Logs / Attach" "Select a running container:")
    
    if [ -n "$container_name" ]; then
        ui_set_title "Logs: ${container_name}"
        ui_clear
        echo "Attaching to live logs for: $container_name"
        echo "Press [Ctrl + C] to detach and return to the main menu."
        echo "------------------------------------------------------------------"
        docker logs -f --tail 100 "$container_name"
        echo ""
        read -p "Logs detached. Press [Enter] to return to the menu..."
    fi
}

handle_create_stack() {
    ui_set_title "TUI: Creating Stack..."
    
    local stack_name
    stack_name=$(ui_input_dialog "New Stack" "Enter new stack name (e.g., silverbullet):")
    
    if [ -n "$stack_name" ]; then
        mkdir -p "$STACKS_DIR/$stack_name"
        touch "$STACKS_DIR/$stack_name/docker-compose.yml"
        
        local data_folders
        data_folders=$(ui_input_dialog "Data Folders" "Enter data folders to create, separated by space (e.g., config data logs):")
        
        if [ -n "$data_folders" ]; then
            for folder in $data_folders; do
                mkdir -p "$STACKS_DIR/$stack_name/$folder"
            done
        fi
        
        ui_set_title "Editing: ${stack_name}"
        ui_clear
        editor_open_micro "$STACKS_DIR/$stack_name/docker-compose.yml"
    fi
}

handle_terminal_shell() {
    ui_set_title "Terminal: /opt/stacks"
    ui_clear
    echo "========================================================"
    echo " Opening Terminal Session inside Stacks Directory       "
    echo " Location: $STACKS_DIR"
    echo "========================================================"
    echo " -> You are interacting directly with the filesystem mount."
    echo " -> Type 'exit' and press [Enter] to return to the TUI."
    echo "--------------------------------------------------------"
    echo ""
    
    (cd "$STACKS_DIR" && bash -i)
}

handle_container_shell() {
    local container_name
    container_name=$(docker_select_container "Container Shell" "Select a running container:")
    
    if [ -n "$container_name" ]; then
        docker_exec_shell "$container_name"
    fi
}

# Run main menu
main_menu
