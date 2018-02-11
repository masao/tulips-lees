#!/usr/bin/env ruby

require "csv"
require "lisbn"
require "rsolr"

class String
  def omit_invalid_chars
    self.gsub(/[\x00-\x08\x0b-\x1f]/, "")
  end
end

if $0 == __FILE__
  solr = RSolr.connect(url: "http://localhost:8983/solr/tulips")
  csv = CSV.new(ARGF, headers: true, row_sep: "\r\n")
  count = 0
  csv.each do |row|
    # LIMEBIB,VOL,ISBN,G/SMD,YEAR,CNTRY,TTLL,TXTL,REPRO,OTHN,TR,PUB,PHYS,VT,CW,NOTE,PTBL,AL,CLS,SH,LIMEHL,VOL,CLN,資料ID,受入区分,貸出区分,受入日
    row.each do |k, v|
      if v
        row[k] = v.omit_invalid_chars
      end
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
        end
        case key
        when "JLA", "TRC"
          key = :trc
        when nil
          key = nil
        else
          key = key.downcase.to_sym
        end
        identifiers[key] ||= []
        identifiers[key] << val
      end
    end
    classifications = {}
    if row["CLS"]
      row["CLS"].split(/\//).each do |classification|
        if classification.include? ":"
          key, val, = classification.split(/:/)
          key = key.downcase.to_sym
          classifications[key] ||= []
          classifications[key] << val
        end
      end
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
      identifier: identifiers,
      title: row["TR"],
      publisher: row["PUB"],
      phys: row["PHYS"],
      variant_title: row["VT"],
      sub_work: row["CW"],
      note: row["NOTE"],
      ptbl: row["PTBL"],
      author: row["AL"],
      classification: classifications,
#SH
#LIMEHL
#VOL
#CLN
#資料ID
#受入区分
#貸出区分
#受入日
    }
    p data
    solr.add(data)
    count += 1
    solr.commit if count % 10000 == 0
  end
  solr.commit
end
