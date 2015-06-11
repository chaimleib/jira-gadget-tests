#!/bin/bash

uri="$(dirname "$0")/_get_host.rb"
uri="$(eval "$uri")"
uri="${uri}/rest/api/latest/issue/CD-12345"
#uri='https://www.example.com/rest/api/latest/issue/CD-12345'

login="$(dirname "$0")/_get_login.rb"
login="$(eval "$login")"
#login='username:password'

agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.85.15.3 (KHTML, like Gecko) Version/7.1.6 Safari/537.85.15.3'

curl \
    --user "$login" \
    --user-agent "$agent" \
    "$uri" | 
    more

