#!/usr/bin/env ruby

require "time"
require "uri"
require "device_detector"

module AccessLog
  SUFFIX_REGEXP = /\.(css|jpe?g|png|gif|ico|js|mso|xml|rss|rdf)\z/o
  PATH_REGEXP = /\A\/(favicon.ico|robots.txt)\z/o
  # TULIPS_PATH_REGEXP = /\A(\/|\/lib\/)\z/o
  ACCESS_LOG_REGEXP = /\A([0-9\.]+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" ([0-9]+) ([\-0-9]+) "([^"]*)" "([^"]*)"\z/o
  REQUEST_REGEXP = /\A(\S+) (.*) HTTP\/(0\.9|1\.0|1\.1|2\.0)\z/o
  # additional ones...
  ADDITIONAL_BOT_LIST = [ "Hatena Antenna", "Feedeen", "Shrook", "libcheck", "WordPress", "FeedFetcher", "Jakarta Commons-HttpClient" ]
  def parse_line(line)
    result = {}
    if ACCESS_LOG_REGEXP =~ line.chomp
      valid = true
      dummy, ip_addr, user, group, time, request, status, size, referer, agent, = $~.to_a
      if REQUEST_REGEXP =~ request
        dummy, method, path, protocol, = $~.to_a
      end
    end
    {
      ip_addr: ip_addr,
      user: user,
      group: group,
      time: time,
      request: request,
      status: status,
      size: size,
      referer: referer,
      agent: agent,
      method: method,
      path: path,
      protocol:protocol,
      valid: valid,
    }
  end
  def parse_time(str)
    date, hour, min, sec, = str.split(/:/)
    date = Date._parse(date)
    Time.new(date[:year], date[:mon], date[:mday], hour, min, sec)
  end
end
