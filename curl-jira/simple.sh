#!/bin/bash

uri="$(dirname "$0")/_get_host.rb"
uri="$(eval "$uri")"
uri="${uri}/rest/api/latest/issue/CD-12345"
#uri='https://www.example.com/rest/api/latest/issue/CD-12345'

login="$(dirname "$0")/_get_login.rb"
login="$(eval "$login")"
#login='user:password'

curl -D- -u "$login" -X GET -H "Content-Type: application/json" "$uri" | more

