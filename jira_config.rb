#!/usr/bin/env ruby

require 'yaml'

class JiraConfig
  def initialize(config_path:'./jira-config.yml')
    this_dir = File.expand_path '..', __FILE__
    @path = File.expand_path config_path, this_dir
    @username = ''
    @password = ''
    @host = ''
    @data = {}
    load_config
  end
  
  def load_config
    f = File.open @path
    @data = YAML.load f.read
    f.close
    @username = @data['username']
    @password = @data['password']
    @host = @data['host']
    self
  end
  
  attr_accessor :path
  attr_reader :username, :password
  attr_reader :host
  
  def login_string
    "#{@username}:#{@password}"
  end
  
  def shell_vars
    lines = @data.collect { |k, v| "#{k}=#{v.inspect}" }
    lines.join "\n"
  end
    
end

if __FILE__ == $0
  def usage
    puts "#{__FILE__} [commands ...]
    
    Commands:
      username
      password
      host
      shell_vars    - print bash script to set variables for the above
      login_string  - 'username:password'
      -h, --help    - print this help message
      "
  end
  
  cfg = JiraConfig.new
  
  if ARGV.empty?
    puts cfg.shell_vars
  elsif (ARGV & ['-h', '--help']).any?
    usage
  else
    ARGV.each do |arg|
      puts cfg.send arg
    end
  end
  
end

