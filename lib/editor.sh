#!/bin/bash

# TtyComposeio - Editor Module
# Handles text editor interactions

# Open file with Micro editor
# Args: file_path
editor_open_micro() {
    local file_path="$1"
    
    if ! command -v micro &> /dev/null; then
        ui_show_msgbox "Error" "Micro editor not found. Please install 'micro'."
        return 1
    fi
    
    micro "$file_path"
}

# Open file with fallback editor (micro or nano)
# Args: file_path
editor_open_with_fallback() {
    local file_path="$1"
    
    if command -v micro &> /dev/null; then
        micro "$file_path"
    elif command -v nano &> /dev/null; then
        nano "$file_path"
    else
        ui_show_msgbox "Error" "No text editor found. Please install 'micro' or 'nano'."
        return 1
    fi
}
