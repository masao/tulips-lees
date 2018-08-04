#!/usr/bin/env ruby

require "json"
require 'digest/md5'
require_relative "util.rb"

SESSION_EXPIRE = 15 * 60

BOT_MINIMUM_SIZE = 200
BOT_INTERVAL = 5.0 # 4 accesses per minute

def bot_session?(logs)
  if logs.size > BOT_MINIMUM_SIZE
    first_time = parse_time(logs.first[:time])
    last_time = parse_time(logs.last[:time])
    duration = last_time - first_time
    if duration / logs.size < BOT_INTERVAL
      STDERR.puts [ "skip:", logs.size, duration, duration / logs.size ].join("\t")
      true
    else
      false
    end
  else
    false
  end
end
def access_to_bibliography?(logs)
  logs.find{|e|
    e[:path] =~ /bibid=\d+/o or e[:path] =~ /(ncid|isbn|issn)=\w+/o
  }
end

def output(key, logs)
  logs = logs.sort_by.with_index{|e, idx|
    [ parse_time(e[:time]), idx ]
  }
  last_time = parse_time(logs.last[:time])
  logs.each do |e|
    puts [ Digest::MD5.hexdigest([key, last_time].join), e.to_json ].join("\t")
  end
end

if $0 == __FILE__
  include AccessLog
  sessions = {}
  count = Hash.new(0)
  ARGF.each_with_index do |line, i|
    log = parse_line(line)
    if log[:valid]
      key = [log[:ip_addr], log[:agent]]
      time = parse_time(log[:time])
      if sessions[key]
        last_time = parse_time(sessions[key].last[:time])
        if time - last_time > SESSION_EXPIRE
          if access_to_bibliography?(sessions[key]) and not bot_session?(sessions[key])
            output(key, sessions[key])
            count[:session] += 1
            count[:log] += sessions[key].size
          end
          sessions.delete key
        end
      end
      sessions[key] ||= []
      sessions[key] << log
      if i % 100000 == 0
        sessions.each do |k, v|
          last_time = parse_time(v.last[:time])
          if time - last_time > SESSION_EXPIRE
            if access_to_bibliography?(v) and not bot_session?(v)
              output(k, v)
              count[:session] += 1
              count[:log] += v.size
            end
            sessions.delete k
          end
        end
      end
    end
  end
  sessions.each do |k, v|
    if access_to_bibliography?(v) and not bot_session?(v)
      output(k, v)
      count[:session] += 1
      count[:log] += v.size
    end
  end
  STDERR.puts count.inspect
end
