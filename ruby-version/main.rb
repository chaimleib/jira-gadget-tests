#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'pp'
require './secure_connection'

class VersionScraper
  def initialize
    @rel_uri = '/wiki/display/CP/CD+Maintenance+Releases'
  end

  def scrape
    result = {}

    result
  end
end

scraper = VersionScraper.new
data = scraper.scrape
pp data

