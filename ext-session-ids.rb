#!/usr/bin/env ruby

require "json"

if $0 == __FILE__
  ARGF.each do |line|
    key, json = line.chomp.split(/\t/)
    log = JSON.parse(json)
    #p log["path"]
    if log["path"] =~ /bibid=(\d+)/o
      puts [key, $1].join("\t")
    end
  end
end
