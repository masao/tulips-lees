#!/usr/bin/env ruby

require "uri"
require "device_detector"

if $0 == __FILE__
  ACCESS_LOG_REGEXP = /\A([0-9\.]+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" ([0-9]+) ([\-0-9]+) "([^"]*)" "([^"]*)"\z/o
  REQUEST_REGEXP = /\A(\S+) (.*) HTTP\/(0\.9|1\.0|1\.1|2\.0)\z/o
  SUFFIX_REGEXP = /\.(css|jpe?g|png|gif|ico|js|mso|xml|rss|rdf)/o
  PATH_REGEXP = /\A\/(favicon.ico|robots.txt)\z/o
  TULIPS_PATH_REGEXP = /\A(\/|\/lib\/)\z/o
  count = Hash.new(0)
  ARGF.each do |line|
    if ACCESS_LOG_REGEXP =~ line.chomp
      dummy, ip_addr, user, group, time, request, status, size, referer, agent, = $~.to_a
      client = DeviceDetector.new(agent)
      if client.bot?
        count[:bot] += 1
        next
      end
      if REQUEST_REGEXP =~ request
        dummy, method, path, = $~.to_a
        begin
          uri = URI.parse(path)
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
    else
      count[:other] += 1
    end
  end
  STDERR.puts count.inspect
end
