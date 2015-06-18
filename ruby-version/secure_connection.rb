#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require '../jira_config'

class SecureConnection
  ## Email username
  #USER_RGX = /^[^@]+@[^@]+$/
  ## Identifier username
  USER_RGX = /^[-_a-zA-Z0-9\.]+$/

  URI_RGX = /^https?:\/\/[-.\/a-zA-Z0-9]+$/

  def initialize(config_file='../jira-config.yml')
    @config_file = File.expand_path config_file, "#{__FILE__}/.."

    # These three are loaded from the config_file
    #@username = username
    #@password = password
    #@host = host

    raise "`#{@config_file}` could not be opened" if !File.exist? @config_file
    load_config @config_file
    validate
  end

  def load_config(path=@config_file)
    cfg = JiraConfig.new(path)
    @username, @password = cfg.username, cfg.password
    @host = cfg.host
  end

  def validate
    raise "`#{@username}` is an invalid e-mail for JIRA" if @username !~ USER_RGX
    raise "No password provided" if @password.empty?
    raise "`#{@host}` is an invalid host URI" if @host.empty? || @host !~ URI_RGX
  end

  def submit_get(path='')
    return if path.empty?
    path = URI.escape path
    path = "/#{path}" if path[0] != '/'
    uri = URI.parse "#{@host}/#{path}"
    puts uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth @username, @password
    request["Content-Type"] = "application/json"
    response = http.request(request)
    raise "#{response.code}: #{response.message}" if response.code !~ /20[0-9]/
    response.body
  end
end


if __FILE__ == $0
  con = SecureConnection.new
  puts con.submit_get '/wiki/display/CP/CD+Maintenance+Releases'
end

