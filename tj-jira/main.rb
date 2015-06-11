#!/usr/bin/env ruby

#require 'rubygems'
require 'jira'
require 'uri'
require 'yaml'
require 'pp'

class JiraConnection
  EMAIL_RGX = /^[^@]+@[^@]+$/
  URI_RGX = /^https?:\/\/[-.\/a-zA-Z0-9]+$/
  
  def initialize(
      username:'', password:'', config_file:'jira-config.yml', 
      host:'',
      interactive:false)
    @username = username
    @password = password
    @config_file = config_file

    @host = host

    @estimate = Hash.new
    @jiraTickets = Hash.new

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

    raise "`#{@username}` is an invalid e-mail for JIRA" if @username !~ EMAIL_RGX
    raise "No password provided" if @password.empty?
    raise "`#{@host}` is an invalid host URI" if @host.empty? || @host !~ URI_RGX

    puts @username
  end

  def prompt_login
    prompted = false
    while @username !~ EMAIL_RGX
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


  def load_config(path='jira-config.yml')
    f = File.open(path)
    config = YAML.load(f.read)
    f.close
    @username, @password = config['username'], config['password']
    @host = config['host']
  end

  def submit_search(jql='')
    return if jql.empty?

    jql = URI.escape jql
    # puts jql

    uri = URI.parse "#{@host}/rest/api/2/search?jql=#{jql}"
    puts uri

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth @username, @password
    request["Content-Type"] = "application/json"

    response = http.request(request)
    puts response.body

    raise "#{response.code}: #{response.message}" if response.code !~ /20[0-9]/
    data = JSON.parse(response.body)
  end

  def pull_tickets
  #  jql = "sprint=483+and+remainingestimate>0+order+by+assignee"
    #jql = "sprint=505+and+type='Technical task'"
    jql = "sprint=505"
    data = submit_search(jql)

    raise 'Search failed' unless data

    fields = data.keys

    #puts JSON.pretty_generate(data)

    data["issues"].each do |issue|
      get_ticket(issue["key"])
    end

    #puts @estimate
    #print data in the end
    @estimate.each do | key, int|
      print "#{key}:"
      puts int/3600
    end
    #pp @estimate

    @jiraTickets.each do |key, jiraTicket|
      print "#{key}:"
      #jiraTicket1 = JiraTicket.new(jiraTicket)

      p jiraTicket.createdDate
      #print jiraTicket.status
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
      uri = URI.parse("#{@host}/rest/api/latest/issue/" + issue)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth @username, @pwd
      request["Content-Type"] = "application/json"

      response = http.request(request)

      if response.code =~ /20[0-9]{1}/
        data = JSON.parse(response.body)
        fields = data.keys

        #puts JSON.pretty_generate(data)
        print data["key"] + ","
        print data["fields"]["reporter"]["displayName"] + ","
        print data["fields"]["assignee"]["displayName"] + ","
        print  data["fields"]["status"]["name"] + ","

        data["fields"]["components"].each do |key|
          print key["name"] + ";"
        end

        if data["fields"]["summary"].include? "QE "

          ticket1 =  JiraTicket.new issue, data["fields"]["summary"],data["fields"]["created"],data["fields"]["status"]
          @jiraTickets[issue] = ticket1
          puts "======" + issue + data["fields"]["summary"] + data["fields"]["created"] + data["fields"]["status"]
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
    else
     raise StandardError, "Unsuccessful response code " + response.code + " for issue " + issue
    end
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
end


con = JiraConnection.new config_file: File.expand_path('../../jira-config.yml', __FILE__)
pp con
# con.pull_tickets
con.get_ticket "CD-12345"
