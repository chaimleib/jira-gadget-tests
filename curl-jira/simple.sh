#!/bin/bash

config_script="$(dirname "$0")/../jira_config.rb"
config="$(eval "$config_script")"
eval "$config"

uri="${host}/rest/api/latest/issue/CD-12345"
login="${username}:${password}"

curl -D- -u "$login" -X GET -H "Content-Type: application/json" "$uri" | more

