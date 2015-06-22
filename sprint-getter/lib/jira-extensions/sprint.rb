#!/usr/bin/env ruby
require 'yaml'
require 'pry'
require 'json'

class Sprint
  attr_reader :id, :rapidViewId, :state, :name
  attr_reader :startDate, :endDate, :completeDate
  attr_reader :sequence
  
  def initialize(sprint_str)
    @id = 0
    @rapidViewId = 0
    @state = 'CLOSED'
    @name = 'Unnamed'
    @startDate = Time.now
    @endDate = nil
    @completeDate = nil
    @sequence = 0
    
    @data = {}
    from_string sprint_str
  end
  
  def from_string(sprint_str)
    range = sprint_str.index('[')+1, sprint_str.index(']')
    juicy_bit = sprint_str[range[0]...range[1]]
    juicy_bit.gsub! ',',"\n"
    juicy_bit.gsub! '=', ': '
    juicy_bit.gsub! '<null>', 'null'
    @data = YAML.load juicy_bit
    @id = @data['id']
    @rapidViewId = @data['rapidViewId']
    @state = @data['state']
    @name = @data['name']
    @startDate = @data['startDate']
    @endDate = @data['endDate']
    @completeDate = @data['completeDate']
    @sequence = @data['sequence']
  end
  
  def print_data
    puts YAML.dump @data
  end
  
  def active?
    state == 'ACTIVE'
  end
  
end


if $0 == __FILE__
  sprint_str = "com.atlassian.greenhopper.service.sprint.Sprintdeadbeef[id=339,rapidViewId=48,state=ACTIVE,name=Jamaica - Sprint 12 - 12.0.11,startDate=2015-06-08T15:33:35.445-07:00,endDate=2015-06-19T15:33:00.000-07:00,completeDate=<null>,sequence=524]"

  s = Sprint.new sprint_str
  s.print_data
end

