#!/bin/bash
config_script="$(dirname "$0")/../jira_config.rb"
config="$(eval "$config_script")"
eval "$config"

login="${username}:${password}"

uri="${host}/wiki/display/CP/CD+Maintenance+Releases"

curl -D- -u "$login" -X GET "$uri" | more

