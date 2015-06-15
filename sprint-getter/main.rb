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
  
  def initialize(
  username:'', password:'', config_file:'../jira-config.yml',
  host:'',
  interactive:false)
    @config_file = config_file
    
    # These three are loaded from the config_file
    @username = username
    @password = password
    @host = host

    if @username.empty? || @host.empty?
      if File.exist? @config_file
        load_config @config_file
      elsif interactive
        prompt_login
        prompt_host
      else
        raise "`#{@config_file}` could not be opened"
      end
    end

    raise "`#{@username}` is an invalid e-mail for JIRA" if @username !~ USER_RGX
    raise "No password provided" if @password.empty?
    raise "`#{@host}` is an invalid host URI" if @host.empty? || @host !~ URI_RGX

    options = {
      :username => @username,
      :password => @password,
      :site => @host,
      :context_path => '',
      :auth_type => :basic
    }
    @client = JIRA::Client.new options
  end

  def prompt_login
    prompted = false
    while @username !~ USER_RGX
      if not @username.empty?
        puts ">> `#{@username}` is not a valid e-mail!\n\n"
      elsif prompted
        puts ">> E-mail cannot be empty!\n\n"
      end
      
      print "E-mail: "
      @username = gets.chomp

      prompted = true
    end

    while @password.empty?
      puts ">> Password cannot be blank!\n\n" unless prompted
      prompted = false

      `stty -echo`
      print "Password: "
      @password = gets.chomp
      `stty echo`
      puts ""
    end
  end
  
  def prompt_host
    prompted = false
    while @host !~ URI_RGX
      if not @host.empty?
        puts ">> `#{@host}` is not a valid host URI!\n\n"
      elsif prompted
        puts ">> Host URI cannot be empty!\n\n"
      end
      
      print "Host: "
      @host = gets.chomp

      prompted = true
    end
  end

  def load_config(path=nil)
    cfg = JiraConfig.new(path || @config_file)
    @username, @password = cfg.username, cfg.password
    @host = cfg.host
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


con = JiraConnection.new config_file: File.expand_path('../../jira-config.yml', __FILE__)
#pp con
#con.pull_tickets
# con.get_ticket "CD-28954"
con.get_projects
