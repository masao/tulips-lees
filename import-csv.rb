#!/usr/bin/env ruby

require "csv"
require "lisbn"

if $0 == __FILE__
  csv = CSV.new(ARGF, headers: true, row_sep: "\r\n")
  csv.each do |row|
    # LIMEBIB,VOL,ISBN,G/SMD,YEAR,CNTRY,TTLL,TXTL,REPRO,OTHN,TR,PUB,PHYS,VT,CW,NOTE,PTBL,AL,CLS,SH,LIMEHL,VOL,CLN,資料ID,受入区分,貸出区分,受入日
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
      bibid: row["LIMEBIB"],
      vol: row["VOL"],
      isbn: isbns,
      gsmd: row["G/SMD"],
      year: row["YEAR"],
      country: row["CNTRY"],
      title_lang: row["TTLL"],
      text_lang: row["TXTL"],
      reproduction: row["REPRO"],
      identifiers: identifiers,
      title: row["TR"],
      publisher: row["PUB"],
      phys: row["PHYS"],
      variant_title: row["VT"],
      sub_work: row["CW"],
      note: row["NOTE"],
      ptbl: row["PTBL"],
      author: row["AL"],
      classifications: classifications,
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
  end
end
