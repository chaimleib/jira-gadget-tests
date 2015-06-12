#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'jira'
require '../jira_config'

# Consider the use of :use_ssl and :ssl_verify_mode options if running locally
# for tests.

cfg = JiraConfig.new

options = {
            :username => cfg.username,
            :password => cfg.password,
            :site     => cfg.host,
            :context_path => '',
            :auth_type => :basic
          }

client = JIRA::Client.new(options)

# Show all projects
projects = client.Project.all

projects.each do |project|
  puts "Project -> key: #{project.key}, name: #{project.name}"
end

