#!/usr/bin/env ruby

require "descriptive_statistics"

lines = []
ARGF.each do |line|
  next if line.strip.empty?
  lines << line.to_i
end

puts "Size: #{lines.size}"
puts "Mean: #{lines.mean}"
puts "STD: #{lines.standard_deviation}"
puts "Median: #{lines.median}"
puts "Min: #{lines.min}"
puts "Max: #{lines.max}"
