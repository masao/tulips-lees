#!/usr/bin/env ruby

require "json"
require "descriptive_statistics"

require_relative "util.rb"
include AccessLog

last_id = nil
times = []
ARGF.each do |line|
  num, str, = line.chomp.split(/\t/)
  #p [num, str]
  obj = JSON.load(str)
  if times.empty? or last_id == num
    times << parse_time(obj["time"])
    last_id = num
  else
    times = times.sort
    period = times.last - times.first
    puts [ last_id, period ].join("\t")
    last_id = num
    times = []
  end
end
times = times.sort
period = times.last - times.first
puts [ last_id, period ].join("\t")
