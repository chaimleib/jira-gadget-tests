#!/usr/bin/env ruby

require 'yaml'

class JiraConfig
  def initialize(config_path:'./jira-config.yml')
    this_dir = File.expand_path '..', __FILE__
    @path = File.expand_path config_path, this_dir
    @username = ''
    @password = ''
    @host = ''
    load_config
  end
  
  def load_config
    f = File.open @path
    data = YAML.load f.read
    f.close
    @username = data['username']
    @password = data['password']
    @host = data['host']
    self
  end
  
  attr_accessor :path
  attr_reader :username, :password
  attr_reader :host
  
  def login_string
    "#{@username}:#{@password}"
  end
end
