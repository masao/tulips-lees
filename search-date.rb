#!/usr/bin/env ruby

require "fileutils"
require "rsolr"

if $0 == __FILE__
  BASEDIR = File.join(File.dirname($0), "eval")
  RUN = "date"
  solr = RSolr.connect(url: "http://localhost:8983/solr/tulips")
  ARGF.each do |line|
    topic_id, query, = line.chomp.split(/\t/)
    topic_dir = File.join(BASEDIR, topic_id)
    FileUtils.mkdir(topic_dir) if not File.exist? topic_dir
    filename = File.join(topic_dir, "#{RUN}.res")
    params = {
      q: query,
      defType: "edismax",
      qf: "title^10.0 default^1.0",
      rows: 1000,
      fl: "*,score",
      sort: "date desc, score desc",
    }
    response = solr.get("select", params: params)
    docs = response["response"]["docs"]
    open(filename, "w") do |io|
      docs.each do |doc|
        io.puts [ doc["id"], doc["score"], doc["title"], doc["author"], doc["date"] ].join("\t")
      end
    end
  end
end
