#!/usr/bin/zsh

# history-here zsh plugin
#   2019 @leonjza
#
# binds ^G to change the location where
# history gets written to from here on.
#
# This plugin checks the environment
# variable $HISTORY_HERE_AUTO_DIRS for a
# list of directories that should
# automatically have its history isolated.
# Matches use prefix-on-component semantics.
# If a match is found, history is stored in
# the matched component's directory.
#
# Example:
#   export HISTORY_HERE_AUTO_DIRS=(/Users/foo/work /root/test)

_history_here_global_histfile=$HISTFILE
_history_here_histfile_name=".zsh_history"
_history_here_is_startup=true
_history_here_is_isolated=false
_history_here_last_auto_root=""

autoload -Uz colors
colors

function _history_here_notify() {

    local _colored="$1"
    print -P -- "$_colored"
    if [[ -n "$ZLE" ]]; then
        zle reset-prompt
    fi
}

function _history_here_build_status() {

    local _kind="$1"
    local _path="$2"
    local _icon=""
    local _state=""
    local _state_color=""
    local _arrow="→"

    case "$_kind" in
        isolated)
            _icon="✓"
            _state="isolated"
            _state_color="${fg_bold[green]}"
            ;;
        global)
            _icon="↩"
            _state="global"
            _state_color="${fg_bold[yellow]}"
            ;;
    esac

    if [[ -n "$_state" ]]; then
        print -r -- "${fg[green]}${_icon}${reset_color} ${fg[cyan]}history${reset_color} ${_state_color}${_state}${reset_color} ${fg[blue]}${_arrow}${reset_color} ${fg[green]}$_path${reset_color}"
    else
        print -r -- "${fg[cyan]}history${reset_color} ${fg[blue]}${_arrow}${reset_color} ${fg[green]}$_path${reset_color}"
    fi
}

function history_here_toggle() {

    if [[ "$HISTFILE" == "$_history_here_global_histfile" ]]; then
       _history_here_switch_history "isolated" "$PWD/$_history_here_histfile_name"
    else
        _history_here_switch_history "global" "$_history_here_global_histfile"
    fi
}

function _history_here_switch_history() {

    local _kind="$1"
    local _target_histfile="$2"
    local _message="$(_history_here_build_status "$_kind" "$_target_histfile")"
    _history_here_notify "$_message"

    if [[ "$_kind" == "isolated" ]]; then
        if [[ "$_history_here_is_isolated" == true ]]; then
            fc -P 2>/dev/null
        fi
        if ! fc -p "$_target_histfile" 2>/dev/null; then
            _history_here_notify "history: failed to push history list"
            return 1
        fi
        if ! fc -R "$_target_histfile" 2>/dev/null; then
            _history_here_notify "history: failed to read history file"
            return 1
        fi
        _history_here_is_isolated=true
    else
        if [[ "$_history_here_is_isolated" == true ]]; then
            fc -P 2>/dev/null
        fi
        _history_here_is_isolated=false
    fi

    if [[ -n "$_target_histfile" ]]; then
        export HISTFILE="$_target_histfile"
    fi
}

function _history_here_find_auto_root() {

    local _pwd=$PWD
    local _root=""

    # Match "prefix on component": /parent/prefix matches /parent/prefix* (first path component only).
    for d in "${HISTORY_HERE_AUTO_DIRS[@]}"; do
        local _dir=${~d}
        _dir=${_dir%/}
        if [[ -z "$_dir" ]]; then
            continue
        fi

        local _parent="${_dir:h}"
        local _prefix="${_dir:t}"

        if [[ "$_pwd" != "$_parent"/* ]]; then
            continue
        fi

        local _rest="${_pwd#${_parent}/}"
        local _first="${_rest%%/*}"

        if [[ "$_first" == ${_prefix}* ]]; then
            if [[ "$_parent" == "/" ]]; then
                _root="/$_first"
            else
                _root="$_parent/$_first"
            fi
            break
        fi
    done

    print -r -- "$_root"
}

function _history_here_resolve_auto_root() {

    local _root=""
    if (( ${#HISTORY_HERE_AUTO_DIRS[@]} == 0 )); then
        _history_here_last_auto_root=""
        print -r -- ""
        return
    fi

    if [[ -n "$_history_here_last_auto_root" ]]; then
        if [[ "$PWD" == "$_history_here_last_auto_root" || "$PWD" == "$_history_here_last_auto_root"/* ]]; then
            _root="$_history_here_last_auto_root"
        fi
    fi

    if [[ -z "$_root" ]]; then
        _root="$(_history_here_find_auto_root)"
        _history_here_last_auto_root="$_root"
    fi

    print -r -- "$_root"
}

function _history_here_auto_switch_for_pwd() {

    local _on_startup=$_history_here_is_startup
    _history_here_is_startup=false
    local _kind="global"
    local _root="$(_history_here_resolve_auto_root)"
    local _target_histfile="$_history_here_global_histfile"
    if [[ -n "$_root" ]]; then
        _kind="isolated"
        _target_histfile="$_root/$_history_here_histfile_name"
    fi

    local _did_switch=false
    if [[ "$HISTFILE" != "$_target_histfile" ]]; then
        _history_here_switch_history "$_kind" "$_target_histfile"
        _did_switch=true
    fi

    if [[ "$_on_startup" == true && "$_kind" == "isolated" && "$_did_switch" == false ]]; then
        local _message="$(_history_here_build_status "$_kind" "$_target_histfile")"
        _history_here_notify "$_message"
    fi
}

# bind the toggle
zle -N history_here_toggle
bindkey '^G' history_here_toggle

# bind to cd, checking $HISTORY_HERE_AUTO_DIRS 
autoload -U add-zsh-hook
add-zsh-hook chpwd _history_here_auto_switch_for_pwd

# Apply isolation immediately on startup, if needed.
_history_here_auto_switch_for_pwd
