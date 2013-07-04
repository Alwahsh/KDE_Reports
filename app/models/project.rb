require 'open-uri' # Needed for fetching data from external URLs

# --------------------------------------------------------------------------------------------------------------------------
# General Functions:
# These are functions that are used generally in other functions.

# Given a text, it splits the text into an array. Used for getting an array out of text areas that hold one item per line
def get_array_from_text unparsed
  return unparsed.split("\n").map{|s| s.chomp}
end

# Given a Ruby array, it transforms it into a string. This is used to represent the array in JSON format.
def convert_array_to_string_array to_convert 
  return "["+"\"#{to_convert.join('","')}\""+"]"
end

# Given a time object, it returns the string representation in the format accepted by Bugzilla.
def get_time_as_string time
  return time.strftime("%Y-%m-%dT%H:%M:%SZ")
end

# ----------------------------------------------------------------------------------------------------------------------------

# Bugzilla Functions:
# These are functions that are used to interact with Bugzilla.



# Given the parameters, it fetches the list of bugs matching the given parameters.
def search_bugzilla include_fields=nil,limit=0,offset=0,status = nil, creation_time = nil, last_change_time = nil
  # include_fields: An array of fields that should be fetched.
  # limit, offset: Used to display lists of bugs.
  # status: An array of bugs status to search for.
  full_string = 'https://bugs.kde.org/jsonrpc.cgi?method=Bug.search&params=[{"product":' + convert_array_to_string_array(get_array_from_text(bugzilla_products))
  full_string += ',"include_fields":' + convert_array_to_string_array(include_fields) if include_fields
  full_string += ',"status":' + convert_array_to_string_array(status) if status
  full_string += ',"limit":' + limit.to_s + ',"offset":'+offset.to_s if limit != 0
  full_string += ',"creation_time":"'+ get_time_as_string(creation_time) +'"' if creation_time
  full_string += ',"last_change_time":"'+ get_time_as_string(last_change_time) +'"' if last_change_time
  full_string += '}]'
  unparsed = open(URI::encode(full_string))
  parsed = ActiveSupport::JSON.decode(unparsed)
  return parsed["result"]["bugs"] if parsed["result"]
  Rails.cache.write "error", parsed["error"] # For debugging only.
end

# ----------------------------------------------------------------------------------------------------------------------------


class Project < ActiveRecord::Base
  resourcify
  attr_accessible :bugzilla_products, :description, :git_repos, :irc_channels, :large_description, :mailing_lists, :parent_id, :title, :bugs_report_fields
  serialize :bugs_report_fields, Array
  
  # This adds the ability to have sub projects.
  acts_as_tree
  
  # Adding a many to many relationship between projects and users.
  has_and_belongs_to_many :users
  
  # After creating the project, fetch needed data to produce graphical reports and save them in the cache.
  after_create :prepare_bugs_report
  after_update :prepare_bugs_report, :if => :bugzilla_products_changed?
  after_update :prepare_bugs_report, :if => :bugs_report_fields_changed?

# ----------------------------------------------------------------------------------------------------------------------------

  # Bugs:
  
  # Available bug options from Bugzilla.
  def self.bugs_options
    ["assigned_to","classification","component","creator","op_sys","platform","priority","product","severity","status","version"]
  end
  
  
  # Deletes all entries in cache for the bug.
  def clear_cache
    Project.bugs_options.each do |property|
      Rails.cache.delete("bugs_by_"+ property +"_for"+id.to_s)
    end
    Rails.cache.delete("reported_bugs_by_creation_time_for"+id.to_s)
    Rails.cache.delete("resolved_bugs_by_creation_time_for"+id.to_s)
    Rails.cache.delete("resolvedbugs_by_assigned_to_for"+id.to_s)
    Rails.cache.delete("openbugs_by_priority_for"+id.to_s)
  end
  
  # Fetches from Bugzilla all data needed to generate graphical reports.
  def prepare_bugs_report
    clear_cache
    successful = search_bugzilla(get_bug_report_fields | ["is_open","creation_time","status","priority","assigned_to"])
    if successful
      get_bug_report_fields.each do |property|
        count_bugs_by property, successful unless ["is_open","creation_time"].include?(property)
      end
      count_bugs_by "assigned_to", successful, "resolved", ["status","RESOLVED"]
      count_bugs_by "priority", successful, "open",["is_open",false]
      reported_bugs_per_month
      resolved_bugs_per_month
      Rails.cache.write("number_of_bugs_for"+id.to_s,successful.length)
    end
  end
  
  # Returns a hash where keys represent a property and values are the data to be represented.
  def get_bugs_report
    res = Hash.new()
    get_bug_report_fields.each do |property|
      res["bugs_by_"+property] = pie_chart_for_bugs_by property
    end
    res["resolvedbugs_by_assigned_to"] = pie_chart_for_bugs_by "assigned_to","resolved"
    res["openbugs_by_priority"] = pie_chart_for_bugs_by "priority", "open"
    res["reported_bugs_by_creation_time"] = line_graph_for_bugs "reported"
    res["resolved_bugs_by_creation_time"] = line_graph_for_bugs "resolved"
    return res
  end
  
  # Returns the bug report fields that were chosen when creating the project.
  def get_bug_report_fields
    return bugs_report_fields
  end
    
  # Produces a hash whose keys are months and values are number of bugs reported in that month.
  def reported_bugs_per_month 
    successful = search_bugzilla ["creation_time"],0,0,nil,12.months.ago.at_beginning_of_month
    return nil unless successful
    bugs = Hash.new(0)
    successful.each do |bug|
      bugs[bug["creation_time"].to_date.mon] += 1 unless Time.now.at_beginning_of_month < bug["creation_time"]
    end
    Rails.cache.write("reported_bugs_by_creation_time_for"+id.to_s,bugs)
  end
  
  # Produces a hash whose keys are months and values are number of bugs resolved in that month.
  def resolved_bugs_per_month
    successful = search_bugzilla ["last_change_time","status"],0,0,nil,nil,12.months.ago.at_beginning_of_month
    return nil unless successful
    bugs = Hash.new(0)
    successful.each do |bug|
      bugs[bug["last_change_time"].to_date.mon] += 1 if (Time.now.at_beginning_of_month > bug["last_change_time"] && bug["status"] == "RESOLVED")
    end
    Rails.cache.write("resolved_bugs_by_creation_time_for"+id.to_s,bugs)
  end
  
  # Produces an array whose each element is itself an array of 2 elements, the first of which is the name of a property and the second is the number of bugs that has it.
  def count_bugs_by property, successful, extra= "", condition = nil
    bugs = Hash.new(0)
    successful.each do |bug|
      unless condition
        bugs[bug[property]] += 1
      else
        if bug[condition[0]] == condition[1]
          bugs[bug[property]] += 1
        end
      end 
    end  
      bugs = bugs.sort_by{|k,v| v}
      Rails.cache.write(extra+"bugs_by_"+ property +"_for"+id.to_s,bugs)
  end
  
  
  # Returns a string that can be passed to the data parameter of HighCharts to draw line_graph
  def line_graph_for_bugs type = ""
    res = "["
    bugs = Rails.cache.read(type+"_bugs_by_creation_time_for"+id.to_s)
    bugs.each do |k,v|
      res << v.to_s << ","
    end
    res << "]"
    return res
  end
  
  
  # Returns a string that may be used in the data field of HighCharts library to draw a pie chart of a bugs property and its percentages and numbers
  def pie_chart_for_bugs_by property, extra=""
    res = ""
    bugs = Rails.cache.read(extra+"bugs_by_"+ property +"_for"+id.to_s)
    bugs.each do |k,v|
      res << "['" << k << "'," << v.to_s << "],"
    end
    return res
  end
  
  def number_of_bugs
    return Rails.cache.read("number_of_bugs_for"+id.to_s)
  end
  
  # Returns an array whose each element represents a bug. Used to provide a list of bugs for a given project.
  def list_of_bugs offset, limit = 10
    offset = 1 unless offset
    number_bugs = self.number_of_bugs
    temp = number_bugs-(offset.to_i)*limit
    if temp > 0
      successful = search_bugzilla ["id","assigned_to","component","last_change_time","status","summary"],limit,temp
    else
      successful = (search_bugzilla ["id","assigned_to","component","last_change_time","status","summary"],limit,0)[0...(limit+temp)]
    end 
    return successful.reverse if successful
    return []
  end
  
end
