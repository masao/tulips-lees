#!/usr/bin/env ruby

require "uri"
require_relative "util.rb"

if $0 == __FILE__
  include AccessLog
  ARGF.each do |line|
    next if not rand(100000) == 0
    data = parse_line(line)
    p [ data[:path], data[:referer] ]
  end
end
