#!/bin/bash

STACKS_DIR="/opt/stacks"
# Ensure the stacks directory exists
mkdir -p "$STACKS_DIR"

# Global array to hold found stacks
STACKS_LIST=()

# Helper function to dynamically change the browser/terminal tab title
set_terminal_title() {
    local title="$1"
    echo -ne "\e]2;${title}\a"
}

# Helper function to find stacks and populate the array safely
load_stacks() {
    STACKS_LIST=()
    for dir in "$STACKS_DIR"/*/; do
        if [ -f "${dir}docker-compose.yml" ] || [ -f "${dir}compose.yml" ]; then
            stack_name=$(basename "$dir")
            # Explicit description labels prevent rendering alignment collapses
            STACKS_LIST+=("$stack_name" "Compose Stack")
        fi
    done
}

while true; do
    # Set the main menu default tab title
    set_terminal_title "WebttyCompose Manager"

    CHOICE=$(dialog --clear \
        --backtitle "WebttyCompose Manager" \
        --title "Main Menu" \
        --menu "Choose an action:" 19 60 9 \
        1 "List Active Stacks (Status)" \
        2 "View Port Dashboard (Assigned Ports)" \
        3 "Start a Stack (Up & Follow Progress)" \
        4 "Stop a Stack (Down)" \
        5 "Edit Stack Configuration (Nano)" \
        6 "View Container Logs / Attach" \
        7 "Create Stack & Data Folders" \
        8 "Open Terminal in Stacks Directory" \
        9 "Exit" \
        3>&1 1>&2 2>&3)

    # Exit if user hits Cancel or ESC
    if [ $? -ne 0 ]; then break; fi

    case $CHOICE in
        1)
            set_terminal_title "TUI: Active Stacks Status"
            docker ps --format "table {{.Names}}\t{{.Status}}" > /tmp/docker_ps.txt
            dialog --title "Active Stacks Status" --textbox /tmp/docker_ps.txt 20 70
            ;;
        2)
            set_terminal_title "TUI: Port Map Dashboard"
            (
            echo "CONTAINER NAME           | ASSIGNED PORTS"
            echo "----------------------------------------------------"
            docker ps --format "{{.Names}}|||{{.Ports}}" | while IFS="|||" read -r name ports; do
                if [ -z "$ports" ]; then
                    clean_ports="None"
                else
                    clean_ports=$(echo "$ports" | sed -E 's/0.0.0.0://g; s/:::([0-9]+->[0-9]+\/(tcp|udp))(, )?//g; s/\/tcp//g; s/\/udp//g')
                fi
                printf "%-24s | %s\n" "$name" "$clean_ports"
            done
            ) > /tmp/docker_ports.txt

            dialog --title "Port Map Dashboard" --textbox /tmp/docker_ports.txt 20 70
            ;;
        3)
            # Start Stack and immediately watch pull/build streams
            load_stacks
            if [ ${#STACKS_LIST[@]} -eq 0 ]; then
                dialog --msgbox "No stacks found in $STACKS_DIR" 8 40
                continue
            fi
            
            STACK_TO_START=$(dialog --title "Start Stack" --menu "Select stack to start:" 15 50 10 "${STACKS_LIST[@]}" 3>&1 1>&2 2>&3)
            if [ -n "$STACK_TO_START" ]; then
                if [ -f "$STACKS_DIR/$STACK_TO_START/compose.yml" ]; then
                    COMPOSE_FILE="$STACKS_DIR/$STACK_TO_START/compose.yml"
                else
                    COMPOSE_FILE="$STACKS_DIR/$STACK_TO_START/docker-compose.yml"
                fi
                
                # Update browser tab to reflect the active stack deployment
                set_terminal_title "Deploying: ${STACK_TO_START}"
                clear
                echo "========================================================"
                echo " Deploying Stack: $STACK_TO_START"
                echo "========================================================"
                echo " -> Streaming build output, network downloads, and pulling..."
                echo " -> Once fully running, press [Ctrl + C] to return to TUI."
                echo "    (Containers will remain active in the background)"
                echo "--------------------------------------------------------"
                echo ""
                
                docker compose -f "$COMPOSE_FILE" up
                
                echo ""
                read -p "Returned from stream. Press [Enter] to reload the menu..."
            fi
            ;;
        4)
            # Stop Stack
            load_stacks
            if [ ${#STACKS_LIST[@]} -eq 0 ]; then
                dialog --msgbox "No stacks found in $STACKS_DIR" 8 40
                continue
            fi
            
            STACK_TO_STOP=$(dialog --title "Stop Stack" --menu "Select stack to stop:" 15 50 10 "${STACKS_LIST[@]}" 3>&1 1>&2 2>&3)
            if [ -n "$STACK_TO_STOP" ]; then
                if [ -f "$STACKS_DIR/$STACK_TO_STOP/compose.yml" ]; then
                    COMPOSE_FILE="$STACKS_DIR/$STACK_TO_STOP/compose.yml"
                else
                    COMPOSE_FILE="$STACKS_DIR/$STACK_TO_STOP/docker-compose.yml"
                fi
                set_terminal_title "Stopping: ${STACK_TO_STOP}"
                docker compose -f "$COMPOSE_FILE" down > /tmp/docker_out.txt 2>&1
                dialog --title "Result" --textbox /tmp/docker_out.txt 15 60
            fi
            ;;
        5)
            # Edit Compose File with Nano
            load_stacks
            if [ ${#STACKS_LIST[@]} -eq 0 ]; then
                dialog --msgbox "No stacks found in $STACKS_DIR" 8 40
                continue
            fi
            
            STACK_TO_EDIT=$(dialog --title "Edit Stack Configuration" --menu "Select stack to edit:" 15 50 10 "${STACKS_LIST[@]}" 3>&1 1>&2 2>&3)
            if [ -n "$STACK_TO_EDIT" ]; then
                set_terminal_title "Editing: ${STACK_TO_EDIT}"
                clear
                if [ ! -f "$STACKS_DIR/$STACK_TO_EDIT/docker-compose.yml" ] && [ -f "$STACKS_DIR/$STACK_TO_EDIT/compose.yml" ]; then
                    nano "$STACKS_DIR/$STACK_TO_EDIT/compose.yml"
                else
                    touch "$STACKS_DIR/$STACK_TO_EDIT/docker-compose.yml"
                    nano "$STACKS_DIR/$STACK_TO_EDIT/docker-compose.yml"
                fi
            fi
            ;;
        6)
            # View Live Container Logs manually
            CONTAINERS=$(docker ps --format "{{.Names}}")
            if [ -z "$CONTAINERS" ]; then
                dialog --msgbox "No running containers found to attach to." 8 45
                continue
            fi
            
            MENU_ITEMS=()
            while read -r name; do
                [ -n "$name" ] && MENU_ITEMS+=("$name" "Running Container")
            done <<< "$CONTAINERS"
            
            CONTAINER_TO_LOG=$(dialog --title "View Logs / Attach" --menu "Select a running container:" 15 55 10 "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
            if [ -n "$CONTAINER_TO_LOG" ]; then
                set_terminal_title "Logs: ${CONTAINER_TO_LOG}"
                clear
                echo "Attaching to live logs for: $CONTAINER_TO_LOG"
                echo "Press [Ctrl + C] to detach and return to the main menu."
                echo "------------------------------------------------------------------"
                docker logs -f --tail 100 "$CONTAINER_TO_LOG"
                echo ""
                read -p "Logs detached. Press [Enter] to return to the menu..."
            fi
            ;;
        7)
            # Create Folders
            set_terminal_title "TUI: Creating Stack..."
            STACK_NAME=$(dialog --title "New Stack" --inputbox "Enter new stack name (e.g., silverbullet):" 8 40 3>&1 1>&2 2>&3)
            if [ -n "$STACK_NAME" ]; then
                mkdir -p "$STACKS_DIR/$STACK_NAME"
                touch "$STACKS_DIR/$STACK_NAME/docker-compose.yml"
                
                DATA_FOLDERS=$(dialog --title "Data Folders" --inputbox "Enter data folders to create, separated by space (e.g., config data logs):" 8 60 3>&1 1>&2 2>&3)
                if [ -n "$DATA_FOLDERS" ]; then
                    for folder in $DATA_FOLDERS; do
                        mkdir -p "$STACKS_DIR/$STACK_NAME/$folder"
                    done
                fi
                
                set_terminal_title "Editing: ${STACK_NAME}"
                clear
                nano "$STACKS_DIR/$STACK_NAME/docker-compose.yml"
            fi
            ;;
        8)
            # Interactive shell environment
            set_terminal_title "Terminal: /opt/stacks"
            clear
            echo "========================================================"
            echo " Opening Terminal Session inside Stacks Directory       "
            echo " Location: $STACKS_DIR"
            echo "========================================================"
            echo " -> You are interacting directly with the filesystem mount."
            echo " -> Type 'exit' and press [Enter] to return to the TUI."
            echo "--------------------------------------------------------"
            echo ""
            
            (cd "$STACKS_DIR" && bash -i)
            ;;
        9)
            break
            ;;
    esac
done

clear
set_terminal_title "Disconnected"
echo "Session ended. You can close the browser window."
