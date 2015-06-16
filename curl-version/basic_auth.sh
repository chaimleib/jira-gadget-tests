#!/bin/bash

config_script="$(dirname "$0")/../jira_config.rb"
config="$(eval "$config_script")"
eval "$config"

uri="${host}/wiki/display/CP/CD+Maintenance+Releases"
login="${username}:${password}"
auth="$(printf "$login" | base64)"

curl -D- -X GET \
    -H "Authorization: Basic $auth" \
    "$uri" | 
    more

