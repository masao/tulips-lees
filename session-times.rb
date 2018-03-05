#!/usr/bin/env ruby

require "json"
require "descriptive_statistics"

require_relative "util.rb"
include AccessLog

first_time = last_time = last_id = nil
ARGF.each do |line|
  num, str, = line.chomp.split(/\t/)
  #p [num, str]
  obj = JSON.load(str)
  if last_id == num
    last_time = parse_time(obj["time"])
    next
  else
    puts [ last_id, last_time - first_time ].join("\t") if first_time
    first_time = parse_time(obj["time"])
    last_time = parse_time(obj["time"])
    last_id = num
  end
end
puts [ last_id, last_time - first_time ].join("\t")
