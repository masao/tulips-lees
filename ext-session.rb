#!/usr/bin/env ruby

require "json"
require_relative "util.rb"

SESSION_EXPIRE = 60 * 60

def access_to_bibliography?(logs)
  logs.find{|e|
    e[:path] =~ /bibid=\d+/o or e[:path] =~ /(ncid|isbn|issn)=\w+/o
  }
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
          #p [ time, last_time ]
          if access_to_bibliography?(sessions[key])
            count[:session] += 1
            sessions[key].each do |e|
              puts [ [key, time].hash, e.to_json ].join("\t")
              count[:log] += 1
            end
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
            if access_to_bibliography?(v)
              count[:session] += 1
              v.each do |e|
                puts [ [k, time].hash, e.to_json ].join("\t")
                count[:log] += 1
              end
            end
            sessions.delete k
          end
        end
      end
    end
  end
  sessions.keys.each do |key|
    if access_to_bibliography?(sessions[key])
      count[:session] += 1
      sessions[key].each do |e|
        puts [ [key, time].hash, e.to_json ].join("\t")
        count[:log] += 1
      end
    end
  end
  STDERR.puts count.inspect
end
