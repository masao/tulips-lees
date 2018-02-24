#!/usr/bin/env ruby

last_id = ""
count = 0
ARGF.each do |line|
  session_id, str = line.split(/\t/)
  if session_id != last_id
    count += 1
  end
  puts [ count, str ].join("\t")
  last_id = session_id
end
