#!/usr/bin/env ruby

require "fileutils"
require "rsolr"

if $0 == __FILE__
  BASEDIR = File.join(File.dirname($0), "eval")
  RUN = "base"
  solr = RSolr.connect(url: "http://localhost:8983/solr/tulips")
  ARGF.each do |line|
    topic_id, query, = line.chomp.split(/\t/)
    topic_dir = File.join(BASEDIR, topic_id)
    FileUtils.mkdir(topic_dir) if not File.exist? topic_dir
    [ 1, 2, 5, 10, 20 ].each do |weight|
      filename = File.join(topic_dir, "#{RUN}#{ "%02d" % weight }.res")
      params = {
        q: query,
        defType: "edismax",
        qf: "title^#{weight}.0 default^1.0",
        rows: 1000,
        fl: "*,score",
        sort: "score desc, date desc",
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
end
