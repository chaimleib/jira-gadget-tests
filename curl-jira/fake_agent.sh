#!/bin/bash

config_script="$(dirname "$0")/../jira_config.rb"
config="$(eval "$config_script")"
eval "$config"

uri="${host}/rest/api/latest/issue/CD-12345"
login="${username}:${password}"
agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.85.15.3 (KHTML, like Gecko) Version/7.1.6 Safari/537.85.15.3'

curl \
    --user "$login" \
    --user-agent "$agent" \
    "$uri" | 
    more

