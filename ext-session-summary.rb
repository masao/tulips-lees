#!/usr/bin/env ruby

require "json"
require_relative "ext-query.rb"

def output(key, hash)
  #p [ key, hash ]
  if hash[:bib]
    puts [ key, hash[:request], hash[:query].to_a.uniq.size, hash[:bib].to_a.uniq.size ].join("\t")
  end
end

if $0 == __FILE__
  include AccessLog::Query
  prev_id = nil
  hash = {}
  ARGF.each do |line|
    key, json = line.chomp.split(/\t/)
    if prev_id and prev_id != key
      output(prev_id, hash)
      hash = {}
    end
    log = JSON.parse(json)
    log.keys.each do |k|
      log[k.to_sym] = log[k]
    end
    queries = extract_queries(log)
    queries.each do |query|
      if not query.strip.empty?
        query = query.gsub(/\s+/o, " ").strip
        hash[:query] ||= []
        hash[:query] << query
      end
    end
    #p log["path"]
    if log["path"] =~ /bibid=(\d+)/o
      hash[:bib] ||= []
      hash[:bib] << $1.dup
    end
    hash[:request] ||= 0
    hash[:request] += 1
    prev_id = key
  end
  output(prev_id, hash)
end
