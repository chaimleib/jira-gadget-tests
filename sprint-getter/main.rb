#!/usr/bin/env ruby

#require 'rubygems'
require 'jira'
require 'uri'
require 'pp'
require './object_cleaner'
require '../jira_config'
require 'pry'


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

  def get_user(username=@username)
    user = @client.User.find username
    pp user
  end

  def get_issues(username=@username)
    conditions = [
      "assignee=#{username.inspect}",
      #'project=CD',
      'updated > -14d',
      'status not in (Closed,Resolved)',
    ]
    query = conditions.join " AND "
    query += " order by updated desc"
    puts query
    issues = @client.Issue.jql query
  end
  
  def print_issue_array(issues)
    issues.each do |issue|
      # parent = issue.fields.parent.key
      status = issue.status.name
      description = issue.description
      if description
        description.gsub! "\n", ' '
        description.gsub! "\r", ''
      else
        description = '<No description>'
      end
      versions = issue.versions.map { |ver| ver.name }
      versions = versions.join ', '
      if versions.empty?
        versions = 'No versions assigned'
      else
        versions = "Versions: #{versions}"
      end
      puts "# #{issue.key} #{issue.updated} (#{status}): #{versions}"
      puts description
      puts ''
    end
  end
  
  def sort_issues_by_target_release(issues)
    result = {}
    _add_to_version = proc do |issue, version|
      result[version] = [] if !result.has_key? version
      result[version].push issue
    end
    issues.each do |issue|
      version = issue.versions
      # Should only have one version
      raise StandardError if version.length > 1
      version = version.length == 0 ? 'Unversioned' : version[0].name
      _add_to_version.call issue, version
    end
    result
  end
  
  def overview
    issues = get_issues
    sorted = sort_issues_by_target_release issues
    sorted.each{ |ver, issues|
      sorted[ver] = issues.map{ |issue| issue.key }
    }
    sorted
  end

  def get_issue(issue='CD-29175')
    issue = @client.Issue.find issue
    binding.pry
  end
end

con = JiraConnection.new
con.get_issue

