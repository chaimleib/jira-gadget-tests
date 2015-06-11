#!/usr/bin/env ruby

require 'yaml'

def this_dir
  File.expand_path '..', __FILE__
end

def host_file(relpath:'../jira-config.yml')
  File.expand_path relpath, this_dir
end

def host_uri
  f = File.open host_file
  data = YAML.load f.read
  f.close
  
  data['host']
end

puts host_uri

