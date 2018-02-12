#!/usr/bin/env ruby

require "json"
require_relative "util.rb"

SESSION_EXPIRE = 60 * 60

if $0 == __FILE__
  include AccessLog
  sessions = {}
  ARGF.each do |line|
    log = parse_line(line)
    if log[:valid]
      key = [log[:ip_addr], log[:agent]]
      time = parse_time(log[:time])
      if sessions[key]
        last_time = parse_time(sessions[key].last[:time])
        if time - last_time > SESSION_EXPIRE
          #p [ time, last_time ]
          if sessions[key].find{|e| e[:path] =~ /bibid=\d+/o or e[:path] =~ /(ncid|isbn|issn)=\w+/o }
            sessions[key].each do |e|
              puts [ key.hash, e.to_json ].join("\t")
            end
          end
          sessions.delete key
        end
      end
      sessions[key] ||= []
      sessions[key] << log
    end
  end
  sessions.keys.each do |key|
    if sessions[key].find{|e| e[:path] =~ /bibid=\d+/o or e[:path] =~ /(ncid|isbn|issn)=\w+/o }
      sessions[key].each do |e|
        puts [ key.hash, e.to_json ].join("\t")
      end
    end
  end
end
