#!/usr/bin/env ruby

require "uri"
require "device_detector"

require_relative "util.rb"

if $0 == __FILE__
  include AccessLog
  count = Hash.new(0)
  prev_line = nil
  ARGF.each do |line|
    if line == prev_line
      count[:other] += 1
      next
    end
    log = parse_line(line)
    if log[:valid]
      client = DeviceDetector.new(log[:agent])
      if client.bot? or log[:agent] =~ Regexp.union(ADDITIONAL_BOT_LIST)
        count[:bot] += 1
        next
      end
      begin
        uri = URI.parse(log[:path])
        uri.path = uri.path.sub(/;jsessionid=\w+\z/o)
        if uri.path =~ PATH_REGEXP or uri.path =~ SUFFIX_REGEXP # or uri.path =~ TULIPS_PATH_REGEXP
          #p path
          count[:request] += 1
          next
        elsif uri.path == "/limedio/dlam/B29/B2986065/1.pdf" and log[:status] == "404"
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
    prev_line = line
  end
  STDERR.puts count.inspect
end
