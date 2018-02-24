#!/usr/bin/env ruby

require "json"
require_relative "ext-query.rb"

if $0 == __FILE__
  include AccessLog::Query
  ARGF.each do |line|
    key, json = line.chomp.split(/\t/)
    log = JSON.parse(json)
    log.keys.each do |k|
      log[k.to_sym] = log[k]
    end
    queries = extract_queries(log)
    queries.each do |query|
      if not query.strip.empty?
        query = query.gsub(/\s+/o, " ").strip
        puts [key, "query: #{query}"].join("\t")
      end
    end
    #p log["path"]
    if log["path"] =~ /bibid=(\d+)/o
      puts [key, $1].join("\t")
    end
  end
end
