require 'jira'
require './sprint'

class JIRA::Resource::Issue
  def target_branch
    customfield_12905
  end
  
  def target_version
    customfield_12803
  end
  
  def has_parent?
    begin
      self.parent
      true
    rescue NoMethodError
      return false
    end
  end
  
  def sprints
    result = customfield_10800.map{|s| Sprint.new s}
    result
  end
  
  def current_sprint
    temp = sprints
    temp.delete_if{|s| !s.active?}
    return nil if temp.empty?
    temp.sort_by!{|s| s.startDate}.last
  end
end

