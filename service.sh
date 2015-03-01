#!/bin/bash

#
# Find all services that matches the provided string
#
locate () {
    service="${1:-.}"
    ls -1 \
/System/Library/LaunchAgents/*.plist \
/Library/LaunchAgents/*.plist \
~/Library/LaunchAgents/*.plist \
/System/Library/LaunchDaemons/*.plist \
/Library/LaunchDaemons/*.plist \
        | grep -i --color "$service"
}

#
# Find *one* service that matches the provided string
#
locate_one () {
    service="$1"
    file="$(locate "$service")"

    if [[ -z "$file" ]]; then
        echo "Service not found: $1" >&2
        exit 1
    elif [[ $(echo "$file" | wc -l) -gt 1 ]]; then
        echo "Multiple results for $1:" >&2
        echo "$file" >&2
        exit 1
    fi

    echo "$file"
}

#
# Find the matching plist for the service from the given paths
#
locate_cellar () {
    local service="$1"
    local paths="$(find "$(brew --celldar)"/*"${service}"* -depth 0 | while read path; do [ -f "$path"/*/homebrew*.plist ] && echo "$path"; done )"
    local count="$(echo "$paths" | wc -l | grep -oE '[0-9]+')"

    if [[ $count -lt 1 ]]; then
        echo "Formula not found: $service" >&2
        exit 1
    elif [[ $count -gt 1 ]]; then
        echo "Multiple formulas matching $service:" >&2
        for plist in $plists; do
            basename "$plist" >&2
        done
        exit 1
    fi

    service="$(basename "$plist")"

    plist="$(find "$paths"/*/homebrew*.plist | tail -n1)" # get the latest version
    if [[ -z "$plist" ]]; then
        echo "Service $service has no launcher" >&2
        exit 1
    fi

    echo "$plist"
}

#
# Link the plist found from the celler into ~/Library/LaunchAgents/
#
link_from_cellar () {
    service="$1"
    plist="$(locate_cellar "$service")"
    [ -n "$plist" ] || exit 1

    name=$(basename "$plist")

    if [[ -f ~/Library/LaunchAgents/"$name" ]]; then
        run unload "$name"
    fi

    ln -sfv "$plist" ~/Library/LaunchAgents
    run load "$name"
}

run () {
    cmd="$1"
    service="$2"
    if [[ $service == '.' ]]; then
        print_help $cmd
        exit 2
    fi

    script="$(locate_one "$service")"
    [ -n "$script" ] || exit 1

    sudo=""
    if [[ "$script" =~ ^/(System|Library) ]]; then
        echo "Service requires admin privileges. Sudo access required."
        sudo="sudo "
    fi

    if [[ ! ("$cmd" =~ load) ]]; then
        script=$(basename "$script" ".plist")
    fi

    execute="${sudo}launchctl $cmd $script"
    echo "$execute"
    $execute
}

print_help () {
    echo -en "Mac OS launchctl utility\n\n"
    echo "Usage: $0 <service_name> [load|unload|reload|start|stop|restart|search|link]" >&2
    if [[ $1 ]]; then
        case ${1} in
            search)
                echo -e "\n$0 search <string>"
                echo -e "\t conduct a partial search on the string name"
                ;;
        esac
    fi
}

case ${2} in
    load|unload|start|stop)
        run "$2" "$1"
        ;;
    restart)
        run stop "$1"
        run start "$1"
        ;;
    reload)
        run unload "$1"
        run load "$1"
        ;;
    search)
        locate "$1"
        ;;
    link)
        link_from_cellar "$1"
        ;;
    help)
        print_help "$1"
        exit 2
        ;;
    *)
        print_help
        exit 2
        ;;
esac