#!/usr/bin/env ruby

require "leveldb"

def import_db(hash, dbname)
  db = LevelDB::DB.new(dbname)
  hash.each do |k, v|
    cur_value = v.uniq
    values = db.get(k)
    if values
      values = values.force_encoding("utf-8").split(/\t/)
      values += cur_value
      values = values.uniq.join("\t")
    else
      values = cur_value.join("\t")
    end
    db.put(k, values)
  end
  db.close
end

ARGV.each do |f|
  STDERR.puts f
  session_hash = {}
  bib_hash = {}
  query_hash = {}
  open(f) do |io|
    io.each do |line|
      session_id, arg, = line.chomp.split(/\t/)
      if arg =~ /\Aquery:\s*(.+)\z/o
        query_hash[session_id] ||= []
        query_hash[session_id] << $1
      else
        bibid = arg
        bib_hash[bibid] ||= []
        bib_hash[bibid] << session_id
        session_hash[session_id] ||= []
        session_hash[session_id] << bibid
      end
    end
  end
  query_hash_r = {}
  session_hash.each do |session_id, bibids|
    bibids.uniq.each do |bibid|
      if query_hash[session_id]
        query_hash_r[bibid] ||= []
        query_hash_r[bibid] += query_hash[session_id]
      end
    end
  end
  import_db(bib_hash, "usage.db")
  import_db(query_hash, "query.db")
end
