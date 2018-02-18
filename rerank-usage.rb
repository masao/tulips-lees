#!/usr/bin/env ruby

require "fileutils"
require "leveldb"

if $0 == __FILE__
  BASEDIR = File.join(File.dirname($0), "eval")
  RUN = "usage"
  usage = {}
  db = LevelDB::DB.new("usage.db")
  ARGV.each do |res_file|
    filename = File.join(File.dirname(res_file), "#{RUN}.res")
    list = []
    open(res_file).each do |line|
      bibid, score, title, author, date, = line.chomp.split(/\t/)
      score = score.to_f
      list << [ bibid, score, title, author, date ]
      if not usage[bibid]
        logs = db.get(bibid)
        if logs
          usage[bibid] = logs.split(/\t/).size
        else
          usage[bibid] = 0.5
        end
      end
    end
    open(filename, "w") do |io|
      list.sort_by{|bibid, score, title, author, date| 
        [ usage[bibid], score, date.to_s ]
      }.reverse.each do |bibid, score, title, author, date|
        io.puts [ bibid, usage[bibid], score, title, author, date ].join("\t")
      end
    end
  end
end
