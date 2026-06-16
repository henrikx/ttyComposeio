#!/bin/bash

# TtyComposeio - UI Module
# Handles all terminal UI interactions

# Initialize UI environment
ui_init() {
    export DIALOGRC="${DIALOGRC:-}"
}

# Cleanup UI
ui_cleanup() {
    ui_clear
    ui_set_title "Disconnected"
    echo "Session ended. You can close the browser window."
}

# Set terminal/browser tab title
ui_set_title() {
    local title="$1"
    echo -ne "\e]2;${title}\a"
}

# Clear screen
ui_clear() {
    clear
}

# Show a menu dialog
# Args: title, text, items...
ui_show_menu() {
    local title="$1"
    local text="$2"
    shift 2
    
    dialog --clear \
        --backtitle "TtyComposeio Manager" \
        --title "$title" \
        --menu "$text" "$UI_MENU_HEIGHT" "$UI_MENU_WIDTH" "$UI_MENU_MAX_ITEMS" \
        "$@" \
        3>&1 1>&2 2>&3
}

# Show a textbox dialog
# Args: title, file
ui_show_textbox() {
    local title="$1"
    local file="$2"
    
    dialog --title "$title" \
        --textbox "$file" "$UI_TEXTBOX_HEIGHT" "$UI_TEXTBOX_WIDTH"
}

# Show a message box
# Args: title, message
ui_show_msgbox() {
    local title="$1"
    local message="$2"
    
    dialog --title "$title" \
        --msgbox "$message" 8 40
}

# Show an input dialog
# Args: title, prompt
ui_input_dialog() {
    local title="$1"
    local prompt="$2"
    
    dialog --title "$title" \
        --inputbox "$prompt" "$UI_INPUT_HEIGHT" "$UI_INPUT_WIDTH" \
        3>&1 1>&2 2>&3
}
