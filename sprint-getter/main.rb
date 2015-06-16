#!/usr/bin/env ruby

#require 'rubygems'
require 'jira'
require 'uri'
require 'pp'
require '../jira_config'

class JiraConnection
  ## Email username
  #USER_RGX = /^[^@]+@[^@]+$/
  ## Identifier username
  USER_RGX = /^[-_a-zA-Z0-9\.]+$/
  
  URI_RGX = /^https?:\/\/[-.\/a-zA-Z0-9]+$/
  
  def initialize(config_file='../jira-config.yml')
    @config_file = config_file
    
    # These three are loaded from the config_file
    # @username = 'username'
    # @password = 'password'
    # @host = 'https://www.example.com'
    load_config

    options = {
      :username => @username,
      :password => @password,
      :site => @host,
      :context_path => '',
      :auth_type => :basic
    }
    @client = JIRA::Client.new options
  end

  def load_config
    raise "`#{@config_file}` could not be opened" unless File.exist? @config_file

    this_dir = File.expand_path '..', __FILE__
    @config_file = File.expand_path @config_file, this_dir
    cfg = JiraConfig.new @config_file
    @username, @password = cfg.username, cfg.password
    @host = cfg.host

    raise "`#{@username}` is an invalid username for JIRA" if @username !~ USER_RGX
    raise "No password provided" if @password.empty?
    raise "`#{@host}` is an invalid host URI" if @host.empty? || @host !~ URI_RGX
  end

  def get_projects
    projects = @client.Project.all
    projects.each do |project|
      puts "#{project.key}: #{project.name}"
    end
  end

end

class JiraTicket
  def initialize(jiraId,summary,createdDate,status)
    @jiraId = jiraId
    @summary = summary
    @createdDate = createdDate
    @status = status
  end
  attr_accessor :jiraId, :summary, :createdDate, :status
end


con = JiraConnection.new
con.get_projects
