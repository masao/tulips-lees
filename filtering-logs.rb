#!/usr/bin/env ruby

require "uri"
require "device_detector"

require_relative "util.rb"

if $0 == __FILE__
  include AccessLog
  count = Hash.new(0)
  ARGF.each do |line|
    log = parse_line(line)
    if log[:valid]
      client = DeviceDetector.new(log[:agent])
      if client.bot?
        count[:bot] += 1
        next
      end
      begin
        uri = URI.parse(log[:path])
        if uri.path =~ PATH_REGEXP or uri.path =~ SUFFIX_REGEXP or uri.path =~ TULIPS_PATH_REGEXP
          #p path
          count[:request] += 1
          next
        end
      rescue URI::InvalidURIError
        count[:request] += 1
        next
      end
      count[:valid] += 1
      puts line
    else
      count[:other] += 1
    end
  end
  STDERR.puts count.inspect
end
