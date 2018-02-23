#!/usr/bin/env ruby

require "roo"

class NDCG
  def initialize(qrels = {}, level = { L1: 1, L2: 10, L3: 20 })
    @qrels = qrels
    @level = level
    STDERR.puts "relevance weights: #{@level.inspect}"
  end
  def compute(ranking, &block)
    measure = 0
    ranking.each_with_index do |doc, i|
      index = i + 1
      relevance_level = ("L#{@qrels[doc]}").to_sym
      if @level[relevance_level]
        measure += yield(relevance_level, index)
      end
    end
    measure
  end
  def gains(ranking)
    compute(ranking) do |relevance_level, rank|
      @level[relevance_level]
    end
  end
  def dcg(ranking)
    compute(ranking) do |relevance_level, rank|
      @level[relevance_level] / Math.log2(1+rank)
    end
  end
  def ndcg(ranking, ideal_ranking)
    dcg(ranking) / dcg(ideal_ranking)
  end
  def precision_at(ranking, cutoff = 10, mapping = [:L2, :L3])
    #p :precision_at
    count = compute(ranking) do |relevance_level, rank|
      #p [ relevance_level, rank ]
      #p mapping.include?(relevance_level)
      if rank > cutoff
        0
      elsif mapping.include? relevance_level
        1
      else
        0
      end
    end
    #p count
    count / 10.0
  end
end

if $0 == __FILE__
  xlsx_file = ARGV.shift
  if xlsx_file =~ /:/
    xlsx_file, sheet, = xlsx_file.split(/:/)
  end
  xlsx = Roo::Excelx.new(xlsx_file)
  xlsx.default_sheet = sheet if sheet
  qrels = {}
  xlsx.each_row_streaming(offset: 1, pad_cells: true) do |row|
    docid = row[0].to_s
    relevance_level = row[4].value
    qrels[docid] = relevance_level
  end
  STDERR.puts "qrels: #{qrels.inspect}"
  ndcg = NDCG.new(qrels)
  ideal_ranking = qrels.keys.sort_by{|k| -qrels[k] }
  STDERR.puts ideal_ranking.inspect
  STDERR.puts ndcg.dcg(ideal_ranking)
  ARGV.each do |file|
    ranking = open(file){|io| io.readlines }.map{|l| l.chomp.split(/\t/).first }
    puts [ file, ndcg.gains( ranking ), ndcg.dcg( ranking ), ndcg.ndcg(ranking, ideal_ranking), ndcg.precision_at(ranking, 10) ].join("\t")
  end
end
