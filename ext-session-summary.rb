#!/usr/bin/env ruby

require "date"
require "json"
require_relative "ext-query.rb"
require_relative "util.rb"

def output(key, hash)
  #p [ key, hash ]
  if hash[:bib]
    period = hash[:times].last - hash[:times].first
    puts [
      key, hash[:request], hash[:query].to_a.uniq.size, hash[:bib].to_a.uniq.size,
      period, hash[:times].first.hour, hash[:times].first.wday,
    ].join("\t")
  end
end

if $0 == __FILE__
  include AccessLog
  include AccessLog::Query
  prev_id = nil
  hash = {}
  @ncid2bibid = NCID2BIBID.new(check_remote: false)
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
    hash[:times] ||= []
    hash[:times] << parse_time(log[:time])
    queries = extract_queries(log)
    queries.each do |query|
      if not query.strip.empty?
        query = query.gsub(/\s+/o, " ").strip
        hash[:query] ||= []
        hash[:query] << query
      end
    end
    bibids = extract_bibids(log)
    bibids.each do |bibid|
      hash[:bib] ||= []
      hash[:bib] << bibid
    end
    hash[:request] ||= 0
    hash[:request] += 1
    prev_id = key
  end
  output(prev_id, hash)
end
