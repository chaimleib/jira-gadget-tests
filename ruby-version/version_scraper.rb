#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'

module VersionScraper
  require 'time'  # if not in module, can't use Time.parse

  NBSP = " "  # Unicode C2 A0

  module_function

  def scrape(html)
    page = Nokogiri::HTML html
    tables = get_tables page
    #puts "#{tables.length} tables extracted"
    data = tables.map{|table| scrape_table table}
    data = combine_tables data
  end

  def scrape_freezes(html)
    data = scrape html
    result = {}
    data.each do |release, row|
      result[release] = row['code freeze']
    end
    result
  end

  def scrape_freeze_dates(html)
    data = scrape_freezes html
    data.each do |release, info|
      next if info.nil?
      data[release] = info[:date]
    end
  end

  def get_tables page
    tables = page.css('table[class=confluenceTable]')
    tables.select{|table| table_has_column table, 'code freeze'}
  end

  def scrape_table(table)
    header = get_table_headers table
    rows = table.css('tr')
    rows.shift  # remove header row
    result_rows = rows.map{|row| scrape_row row, header}
    result_rows.delete_if &:nil?
    {
      :header => header,
      :data => result_rows,
    }
  end

  def combine_tables(tables)
    if tables.any?{|table| !table[:header][0].downcase.include? 'release'}
      raise StandardError
    end

    _fix_release_key = proc do |table|
      # Not all tables labeled the 'release' column the same, so
      # normalize them
      release_key = table[:header][0].downcase
      table[:header][0] = 'release'
      unless release_key == 'release'
        table[:data].each do |row|
          row['release'] = row[release_key]
          row.delete release_key
        end
      end
    end
    
    result = {}
    _add_row = proc do |row|
      release = row['release'][:name]
      if !result.has_key? release || result[release].nil?
        result[release] = row
        next
      end
      # If we're here, we have a duplicate entry; resolve it.
      # I only care about the code freeze date
      stored = result[release]['code freeze']
      new = row['code freeze']
      if stored == new || new.nil?
        # nothing to add!
        next
      elsif stored.nil?
        result[release] = row
        next
      else stored != new
        puts "result[#{release.inspect}] ="
        puts YAML.dump result[release]
        puts ''
        puts "row = "
        puts YAML.dump row
        raise "#{release.inspect} already present with a conflicting code freeze"
      end
    end
    
    tables.each do |table|
      _fix_release_key.call table
      # Now try to add the row
      table[:data].each{|row| _add_row.call row}
    end
    result
  end

  def html_strip(html)
    html.gsub(NBSP, ' ').strip
  end

  def scrape_row(row, header)
    cells = row.css('td')

    # first cell in row contains a version number,
    # possibly a link
    version = cells.shift
    version_name = html_strip version.text
    return nil if version_name.empty?
    version_uri = version.at('a')
    if version_uri
      version_uri = version_uri.attributes['href'].value
    end

    # other cells have dates and tags about this version
    data = cells.map{|cell| scrape_cell cell}

    if data.any?{|cell| cell && cell[:tags].include?("CANCELLED")}
      return nil
    end

    # put version info at front of data
    data.unshift({
      :name => version_name,
      :uri => version_uri
    })

    header = header.map &:downcase

    # make a hash with keys=header, values=data
    Hash[header.zip data]
  end

  def scrape_cell(cell)
    # This page was nice and enclosed dates in <time> elements
    date = cell.at('time')
    if date
      date = date.attributes['datetime'].value
      date += ' 23:59:59'
      date = Time.parse(date)
    else
      # If there is no time here, no use looking further
      return nil
    end

    # This page also enclosed its labels about the dates in separate elements. Nice!
    tags = cell.css('.status-macro').map{|tag| html_strip tag.text }
    {
      :date => date,
      :tags => tags,
    }
  end

  def get_table_headers(table)
    first_row = table.at('tr')
    headers = table.css('th') || table.css('td')
    headers = headers.map{|th| th.text.gsub(NBSP, ' ').strip}
    headers
  end

  def table_has_column(table, col)
    get_table_headers(table).map(&:downcase).include? col
  end
end

#class Nokogiri::XML::NodeSet
#  def delete_if
#    to_delete = []
#    self.each do |el|
#      to_delete << el if yield el
#    end
#    to_delete.each do |el|
#      delete el
#    end
#  end
#end

