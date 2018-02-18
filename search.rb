#!/usr/bin/env ruby

require "leveldb"
require "rsolr"

if $0 == __FILE__
  query = ARGV[0] || "対数関数"
  solr = RSolr.connect(url: "http://localhost:8983/solr/tulips")
  db = LevelDB::DB.new("usage.db")
  params = {
    q: query,
    defType: "edismax",
    qf: "title^10.0 default^1.0",
    rows: 100,
    fl: "*,score",
  }
  response = solr.get("select", params: params)
  docs = response["response"]["docs"]
  docs.each do |doc|
    logs = db.get(doc["id"])
    if logs 
      usage = logs.split(/\t/).size
    else
      usage = 0
    end
    puts [ doc["id"], usage, doc["score"], doc["title"], doc["author"], doc["date"] ].join("\t")
  end
end
