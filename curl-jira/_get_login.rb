#!/usr/bin/env ruby

require 'yaml'

def this_dir
  File.expand_path '..', __FILE__
end

def login_file(relpath:'../jira-config.yml')
  File.expand_path relpath, this_dir
end

def login_string
  f = File.open login_file
  data = YAML.load f.read
  f.close
  
  "#{data['username']}:#{data['password']}"
end

puts login_string

