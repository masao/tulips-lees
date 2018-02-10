#!/usr/bin/env ruby

require "csv"

if $0 == __FILE__
  csv = CSV.new(ARGF, headers: true, row_sep: "\r\n")
  csv.each do |row|
    p row
  end
end
