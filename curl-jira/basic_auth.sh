#!/bin/bash

config_script="$(dirname "$0")/../jira_config.rb"
config="$(eval "$config_script")"
eval "$config"

uri="${host}/rest/api/latest/issue/CD-28954"
login="${username}:${password}"
auth="$(printf "$login" | base64)"

curl -D- -X GET \
    -H "Authorization: Basic $auth" \
    -H "Content-Type: application/json" \
    "$uri" | 
    more

