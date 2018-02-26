#!/usr/bin/env ruby

require "fileutils"
require "leveldb"
require "descriptive_statistics"

if $0 == __FILE__
  ratio = 0.5
  if ARGV[0] and ARGV[0] =~ /\A-(\d+)\z/o
    ratio = $1.to_i / 10.0
    ARGV.shift
  end
  STDERR.puts "ratio: #{ratio}"
  BASEDIR = File.join(File.dirname($0), "eval")
  db = LevelDB::DB.new("usage.db")
  ARGV.each do |res_file|
    usage = {}
    basename = File.basename(res_file, ".res")
    filename = File.join(File.dirname(res_file), "#{basename}+usage#{ "%d" % (ratio*10) }.res")
    STDERR.puts "filename: #{filename}"
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
      scores = list.map{|e| e[1] }
      score_mean = scores.mean
      score_standard_deviation = scores.standard_deviation
      usage_mean = usage.values.mean
      usage_standard_deviation = usage.values.standard_deviation
      new_score = {}
      list.sort_by{|bibid, score, title, author, date| 
        score_val = ( score - score_mean ) / score_standard_deviation
        usage_val = ( usage[bibid] - usage_mean ) / usage_standard_deviation
        new_score[bibid] = ( 1 - ratio ) * score_val + ratio * usage_val
        #  STDERR.puts [ new_score[bibid], score_val, usage_val ].inspect
        [ new_score[bibid], usage[bibid], score, date.to_s ]
      }.reverse.each do |bibid, score, title, author, date|
        io.puts [ bibid, new_score[bibid], usage[bibid], score, title, author, date ].join("\t")
      end
    end
  end
end
