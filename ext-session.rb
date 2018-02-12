#!/usr/bin/env ruby

require "json"
require_relative "util.rb"

if $0 == __FILE__
  include AccessLog
  sessions = {}
  ARGF.each do |line|
    log = parse_line(line)
    if log[:valid]
      key = [log[:ip_addr], log[:agent]]
      sessions[key] ||= []
      sessions[key] << log
      #pp sessions[key] if sessions[key].size == 10
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
