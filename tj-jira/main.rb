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
      host:'')
    @config_file = config_file
    
    # These three are loaded from the config_file
    @username = username
    @password = password
    @host = host

    @estimate = Hash.new
    @jiraTickets = Hash.new

    if @username.empty? || @host.empty?
      if File.exist? @config_file
        load_config @config_file
      else
        raise "`#{@config_file}` could not be opened"
      end
    end

    raise "`#{@username}` is an invalid e-mail for JIRA" if @username !~ USER_RGX
    raise "No password provided" if @password.empty?
    raise "`#{@host}` is an invalid host URI" if @host.empty? || @host !~ URI_RGX
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

  def submit_search(jql='')
    return if jql.empty?
    path = "/search?jql=#{jql}"
    submit_get path
  end
  
  def submit_get(path='')
    return if path.empty?
    path = URI.escape path
    path = "/#{path}" if path[0] != '/'
    uri = URI.parse "#{@host}/rest/api/2#{path}"
    puts uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth @username, @password
    request["Content-Type"] = "application/json"
    response = http.request(request)
    #puts response.body
    raise "#{response.code}: #{response.message}" if response.code !~ /20[0-9]/
    data = JSON.parse(response.body)
  end
    

  def pull_tickets
    jql = "sprint=483+and+remainingestimate>0+order+by+assignee"
    #jql = "sprint=505+and+type='Technical task'"
    #jql = "sprint=505"
    data = submit_search jql

    raise 'Search failed' unless data

    fields = data.keys

    #puts JSON.pretty_generate(data)

    data["issues"].each do |issue|
      get_ticket issue["key"]
    end

    #puts @estimate
    #print data in the end
    @estimate.each do | key, int|
      print "#{key}:#{int/3600}"
    end
    puts ''
    #pp @estimate

    @jiraTickets.each do |key, jiraTicket|
      puts "#{key}:#{jiraTicket.jiraId},#{jiraTicket.createdDate}"
      puts JSON.pretty_generate jiraTicket.status
      puts ''
    end
  end

  def get_ticket(issue)
    #issue="CD-18281")
    #ticket = Ticket.new
    #ticket.jira_id = 3535353
    #ticket.components = issue
    #ticket.save
    #issue = "CD-18281"
    #issue_keys = %w[JZ-3030 CD-24650]
    #json_ext = ".json"

    #for issue in issue_keys
    path = "/issue/#{issue}"
    data = submit_get path
    fields = data.keys

    #puts JSON.pretty_generate(data)
    print data["key"] + ","
    print data["fields"]["reporter"]["displayName"] + ","
    print data["fields"]["assignee"]["displayName"] + ","
    print data["fields"]["status"]["name"] + ","

    data["fields"]["components"].each do |key|
      print key["name"] + ";"
    end

    if data["fields"]["summary"].include? "QE "

      ticket1 =  JiraTicket.new issue, data["fields"]["summary"],data["fields"]["created"],data["fields"]["status"]
      @jiraTickets[issue] = ticket1
      #puts "======#{issue},#{data["fields"]["summary"]},#{data["fields"]["created"]},#{data["fields"]["status"]["name"]}"
    end

    data["fields"]["subtasks"].each do |key|
      print key["key"] + ";"
    end
    print ","

    print data["fields"]["created"] + ","

    print data["fields"]["timetracking"]["originalEstimate"].to_s + "," unless data["fields"]["timetracking"]["originalEstimateSeconds"] == nil
    print data["fields"]["timetracking"]["remainingEstimate"].to_s + "," unless data["fields"]["timetracking"]["originalEstimateSeconds"] == nil
    #print data["fields"]["timetracking"]["timeSpent"] + ";"
    print data["fields"]["timetracking"]["originalEstimateSeconds"].to_s + "," unless data["fields"]["timetracking"]["originalEstimateSeconds"] == nil
    print data["fields"]["timetracking"]["remainingEstimateSeconds"].to_s + "," unless data["fields"]["timetracking"]["originalEstimateSeconds"] == nil
    print data["fields"]["timetracking"]["timeSpentSeconds"].to_s + "," unless data["fields"]["timetracking"]["originalEstimateSeconds"] == nil

    #uncomment the two lines below to see a prettified version of the json
    #puts "Here is prettified JSON data: "
    #puts JSON.pretty_generate(data)
    #
    summarize_estimate(data)
  end

  def summarize_estimate(ticket)
    if @estimate[ticket["fields"]["assignee"]["displayName"]]
      @estimate[ticket["fields"]["assignee"]["displayName"]] = @estimate[ticket["fields"]["assignee"]["displayName"]] + ticket["fields"]["timetracking"]["remainingEstimateSeconds"]
    else
      @estimate[ticket["fields"]["assignee"]["displayName"]] = ticket["fields"]["timetracking"]["remainingEstimateSeconds"]
    end
    puts @estimate[ticket["fields"]["assignee"]["displayName"]]
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
con.get_ticket "CD-28954"

