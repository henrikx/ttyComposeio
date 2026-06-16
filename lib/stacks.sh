#!/bin/bash

# TtyComposeio - Stacks Module
# Handles Docker Compose stack operations

# Load all available stacks
# Returns: populates array of stack names
stacks_load() {
    local -n stacks_array=$1
    stacks_array=()
    
    if [ ! -d "$STACKS_DIR" ]; then
        return
    fi
    
    for dir in "$STACKS_DIR"/*/; do
        if [ -d "$dir" ]; then
            if [ -f "${dir}docker-compose.yml" ] || [ -f "${dir}compose.yml" ]; then
                stacks_array+=("$(basename "$dir")" "Compose Stack")
            fi
        fi
    done
}

# Get compose file for a stack
# Args: stack_name
# Returns: path to compose file
stacks_get_compose_file() {
    local stack_name="$1"
    local docker_compose="$STACKS_DIR/$stack_name/docker-compose.yml"
    local compose="$STACKS_DIR/$stack_name/compose.yml"
    
    if [ -f "$compose" ]; then
        echo "$compose"
    else
        echo "$docker_compose"
    fi
}

# Select a stack from available stacks
# Args: title, prompt
# Returns: selected stack name
stacks_select_from_list() {
    local title="$1"
    local prompt="$2"
    
    local stacks_list=()
    stacks_load stacks_list
    
    if [ ${#stacks_list[@]} -eq 0 ]; then
        ui_show_msgbox "$title" "No stacks found in $STACKS_DIR"
        return 1
    fi
    
    ui_show_menu "$title" "$prompt" "${stacks_list[@]}"
}
