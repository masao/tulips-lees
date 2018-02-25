#!/usr/bin/env ruby

require "csv"
require "lisbn"
require "rsolr"
require "leveldb"

class String
  def omit_invalid_chars
    self.gsub(/[\x00-\x08\x0b-\x1f]/, "")
  end
end

if $0 == __FILE__
  solr = RSolr.connect(url: "http://localhost:8983/solr/tulips")
  db = LevelDB::DB.new("query.db")
  csv = CSV.new(ARGF, headers: true, row_sep: "\r\n")
  count = 0
  csv.each do |row|
    # LIMEBIB,VOL,ISBN,G/SMD,YEAR,CNTRY,TTLL,TXTL,REPRO,OTHN,TR,PUB,PHYS,VT,CW,NOTE,PTBL,AL,CLS,SH,LIMEHL,VOL,CLN,資料ID,受入区分,貸出区分,受入日
    row.each do |k, v|
      if v
        row[k] = v.omit_invalid_chars
      end
    end
    #p row
    if row["貸出区分"] == "オンライン" and row["CLN"] == "eBook"
      #row["G/SMD"] == "機械可読データファイル -- リモートファイル"
      puts "skip:" + row.inspect
      next
    end
    isbns = []
    if row["ISBN"]
      isbn = Lisbn.new(row["ISBN"])
      isbns << isbn.isbn10
      isbns << isbn.isbn13
    end
    identifiers = {}
    if row["OTHN"]
      row["OTHN"].split(/\//).each do |identifier|
        if identifier.include?(":")
          key, val, = identifier.split(/:/)
        elsif identifier =~ /\A\((.*?)\)(.*)\z/
          key = $1
          val = $2
        else
          next
        end
        key = key.downcase.to_sym
        identifiers[key] ||= []
        identifiers[key] << val
      end
    end
    if identifiers.empty?
      identifiers = nil
    else
      identifiers_s = identifiers.to_json
    end
    classifications = {}
    if row["CLS"]
      row["CLS"].split(/\//).each do |classification|
        if classification.include? ":"
          key, val, = classification.split(/:/)
          case key
          when /\ANDC/io, "CAL"
            key = :ndc
          when /\ADC/io
            key = :dc
          when /\ANDLC/io
            key = :ndlc
          when /\ALCC/io
            key = :lcc
          else
            STDERR.puts "skip: Classification #{key} (#{row["LIMEBIB"]})"
          end
          classifications[key] ||= []
          classifications[key] << val
        end
      end
    end
    queries = db.get(row["LIMEBIB"])
    if queries
      #STDERR.puts [row["LIMEBIB"], queries].inspect
      queries = queries.split(/\t/)
    else
      queries = []
    end
    data = {
      id: row["LIMEBIB"],
      vol: row["VOL"],
      isbn: isbns,
      gsmd: row["G/SMD"],
      year: row["YEAR"],
      country: row["CNTRY"],
      title_lang: row["TTLL"],
      text_lang: row["TXTL"],
      reproduction: row["REPRO"],
      identifier: identifiers_s,
      title: row["TR"],
      publisher: row["PUB"],
      phys: row["PHYS"],
      variant_title: row["VT"],
      sub_work: row["CW"],
      note: row["NOTE"],
      ptbl: row["PTBL"],
      author: row["AL"],
      ndc: classifications[:ndc].to_a.uniq,
      dc: classifications[:dc].to_a.uniq,
      ndlc: classifications[:ndlc].to_a.uniq,
      lcc: classifications[:lcc].to_a.uniq,
      item_id: row["資料ID"],
      call_number: row["CLN"],
      acquisition_genre: row["貸出区分"],
      circulation_type: row["貸出区分"],
      date: row["受入日"],
      subject: row["SH"].to_s.split(/\//),
      query: queries.map{|s| s.omit_invalid_chars },
    }
    #p data
    solr.add(data)
    count += 1
    if count % 10000 == 0
      print count, "..."
      solr.commit
    end
  end
  solr.commit
end
