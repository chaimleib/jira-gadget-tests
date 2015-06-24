#!/usr/bin/env ruby
require './version_scraper'
require 'pp'

def write_page
  require './secure_connection'
  rel_uri = '/wiki/display/CP/CD+Maintenance+Releases'
  con = SecureConnection.new
  html = con.submit_get rel_uri
  File.new('test.html', 'w').write(html)
end

#write_page

html = File.read('test.html')
freezes = VersionScraper.scrape_freeze_dates html
pp freezes

