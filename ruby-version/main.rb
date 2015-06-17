#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'pp'
require 'pry'
require './secure_connection'

class VersionScraper
  def initialize
    @rel_uri = '/wiki/display/CP/CD+Maintenance+Releases'
  end

  def scrape
    result = {}
    
    con = SecureConnection.new
    html = con.submit_get @rel_uri
    page = Nokogiri::HTML html
    tables = get_tables page
    puts "#{tables.length} tables extracted"
    tables.each {|table|
      scrape_table table, result
    }
    result
  end
  
  def get_table_headers(table)
    first_row = table.at('tr')
    headers = table.css('th') || table.css('td')
    headers.map!{|th| th.text.strip }
    headers
  end
    
  def table_has_column(table, col)
    get_table_headers(table).map{|col| col.downcase}.include? col
  end
  
  def get_tables page
    results = {}
    tables = page.css('table[class=confluenceTable]')
    binding.pry
    # delete_if doesn't work on Nokogiri nodes
    tables.delete_if{|table| !table_has_column(table, 'code freeze') }
    table_headers = tables.map{|table| get_table_headers table }
    results['headers'] = table_headers
    results['data'] = []
    tables.each{|table|
      result_rows = []
      results['data'].push result_rows
      rows = table.css('tr')
      rows.shift
      rows.map{|row|
        cells = row.css('td').map{|cell| cell.text.strip }
        result_rows.push cells
      }
    }
    results
  end
end

scraper = VersionScraper.new
data = scraper.scrape
pp data

