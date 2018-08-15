#!/usr/bin/env ruby

require "uri"
require_relative "util.rb"

module AccessLog::Query
PATTERNS = [
  { path: "/scripts/online-j/search", query: "query" },
  { path: "/mylimedio/search/search.do", query: "keyword" },
  { path: "/mylimedio/search/search.do", query: "title" },
]
REFERER_PATTERNS = [
  { host: /google\.(co\.\w\w|com)\z/o, query: "q", encoding: "ie", source: :google },
  { host: /yahoo\.(co\.\w\w|com)\z/o, query: "p", encoding: "ei", source: :yahoo },
  { host: /bing\.com\z/o, query: "q", source: :bing },
  { host: "tsukuba.summon.serialssolutions.com", query: "q", source: :summon },
  { host: "tsukuba.summon.serialssolutions.com", query: "s.q", source: :summon },
  { host: "jn2xs2wb8u.search.serialssolutions.com", query: "rft.atitle", source: :"360link" },
  { host: "jn2xs2wb8u.search.serialssolutions.com", query: "C", source: :"360link" },
]
  def extract_queries(data)
    queries = []
    #p [ data[:path], data[:referer] ]
    begin
    path = URI.parse(data[:path])
    PATTERNS.each do |pattern|
      if path.path === pattern[:path]
        #p [ data[:path], data[:referer] ]
        if path.query
          params = URI.decode_www_form(path.query)
          params.each do |k, v|
            if pattern[:query] === k and not v.strip.empty?
              #p [ data[:path], data[:referer] ]
              queries << { query: v, source: pattern[:source] || :opac }
            end
          end
        end
      end
    end
    rescue
    end
    begin
    referer = URI.parse(data[:referer])
    REFERER_PATTERNS.each do |pattern|
      if pattern[:host] === referer.host
        if referer.query
          params = URI.decode_www_form(referer.query)
          if pattern[:encoding]
            ie, encoding = params.find{|k, v| k == pattern[:encoding] }
            if encoding
              params = URI.decode_www_form(referer.query, encoding) 
              params = params.map do |k, v|
                v = v.encode("utf-8")
                [ k, v ]
              end
            end
          end
          params.each do |k, v|
            if pattern[:query] === k and not v.strip.empty?
              #p [ data[:path], data[:referer] ]
              queries << { query: v, source: pattern[:source] }
            end
          end
        end
      end
    end
    rescue
    end
    queries
  end
end

if $0 == __FILE__
  include AccessLog
  include AccessLog::Query
  Encoding.default_external = "utf-8"
  ARGF.each do |line|
    data = parse_line(line)
    puts extract_queries(data)
  end
end
