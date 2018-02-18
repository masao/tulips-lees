#!/usr/bin/env ruby

if $0 == __FILE__
  LIMIT = 50
  hash = {}
  ARGV.each do |file|
    lines = open(file){|io| io.readlines }[0, LIMIT]
    lines.each do |line|
      bibid, score, *data = line.chomp.split( /\t/ )
      new_data = []
      data.each do |e|
        if e =~ /\A[\-\d\.]+\z/o
        else
          new_data << e
        end
      end
      hash[ bibid ] ||= []
      hash[ bibid ] = new_data
    end
  end
  hash.keys.sort_by{|e| e.to_i }.each do |bibid|
    puts [ bibid, hash[bibid] ].join( "\t" )
  end
end

