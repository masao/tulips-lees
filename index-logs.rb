#!/usr/bin/env ruby

require "leveldb"

db = LevelDB::DB.new("usage.db")

ARGV.each do |f|
  hash = {}
  open(f) do |io|
    io.each do |line|
      session_id, bibid, = line.chomp.split
      hash[bibid] ||= []
      hash[bibid] << session_id
    end
  end
  hash.each do |k, v|
    cur_value = v.uniq.join("\t")
    values = db.get(k)
    if values
      values << "\t" + cur_value
    else
      values = cur_value
    end
    db.put(k, values)
  end
end
