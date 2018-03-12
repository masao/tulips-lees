#!/usr/bin/env ruby

require "csv"
require_relative "util.rb"

if $0 == __FILE__
  csv = CSV.new(ARGF, headers: true, row_sep: "\r\n")
  db = NCID2BIBID.new
  count = 0
  csv.each do |row|
    if row["OTHN"] and row["OTHN"].include?("NCID:")
      row["OTHN"].split(/\//).each do |identifier|
        if identifier =~ /\ANCID:(.+)\z/o
          ncid = $1.dup
          db[ncid] = row["LIMEBIB"]
          count += 1
        end
      end
    end
  end
  p count
end
