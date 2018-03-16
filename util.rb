#!/usr/bin/env ruby

require "time"
require "uri"
require "device_detector"
require "leveldb"
require "net/http/persistent"

module AccessLog
  SUFFIX_REGEXP = /\.(css|jpe?g|png|gif|ico|js|mso|xml|rss|rdf)\z/io
  PATH_REGEXP = /\A\/(favicon.ico|robots.txt|proxy.pac)\z/o
  # TULIPS_PATH_REGEXP = /\A(\/|\/lib\/)\z/o
  ACCESS_LOG_REGEXP = /\A([0-9\.]+) (\S+) (\S+) \[([^\]]+)\] "([^"]+)" ([0-9]+) ([\-0-9]+) "([^"]*)" "([^"]*)"\z/ou
  REQUEST_REGEXP = /\A(\S+) (.*) HTTP\/(0\.9|1\.0|1\.1|2\.0)\z/o
  # additional ones...
  ADDITIONAL_BOT_LIST = [
    "Hatena Antenna",
    "Feedeen",
    "Shrook",
    "libcheck",
    "WordPress",
    "FeedFetcher",
    "Jakarta Commons-HttpClient",
    "internal dummy connection",
    "Wget",
    "DTS Agent",
    "SiteSucker",
    "Riddler",
    "ndl-japan-warp",
    "Wget",
    "Grasshopper",
    "Fetcher",
  ]
  ADDITIONAL_IP_LIST = %w( 70.42.131.170 52.192.242.88 160.16.62.108 )
  def parse_line(line)
    result = {}
    if ACCESS_LOG_REGEXP =~ line.chomp
      valid = true
      dummy, ip_addr, user, group, time, request, status, size, referer, agent, = $~.to_a
      if REQUEST_REGEXP =~ request
        dummy, method, path, protocol, = $~.to_a
      end
    end
    {
      ip_addr: ip_addr,
      user: user,
      group: group,
      time: time,
      request: request,
      status: status,
      size: size,
      referer: referer,
      agent: agent,
      method: method,
      path: path,
      protocol:protocol,
      valid: valid,
    }
  end
  def parse_time(str)
    date, hour, min, sec, = str.split(/:/)
    date = Date._parse(date)
    Time.new(date[:year], date[:mon], date[:mday], hour, min, sec)
  end
end

class NCID2BIBID
  REGEXP = /bibid=(\d+)/o
  HTTP_SLEEP_INTERVAL = 2000
  HTTP_SLEEP_PERIOD = 120
  HTTP_PERIOD = 0.5
  def initialize(dbname: "ncid2bibid.db", name: nil, check_remote: true)
    @dbname = dbname
    @db = LevelDB::DB.new(dbname)
    uaname = name
    uaname = [self.class, "-", "tulips-lees"].join(" ") unless uaname
    @http = Net::HTTP::Persistent.new(name: uaname)
    @http_count = 0
    @http_last_time = Time.now
    @non_existent = []
    @check_remote = check_remote
  end
  def to_bibid(ncid)
    bibid = nil
    if @db[ncid]
      bibid = @db[ncid]
    elsif not @check_remote
    elsif @non_existent.include? ncid
    else
      uri = URI.parse("http://www.tulips.tsukuba.ac.jp/mylimedio/search/search.do?target=local&mode=comp&ncid=#{ncid}")
      if @http_count > 0 and @http_count % HTTP_SLEEP_INTERVAL == 0
        @http.connection_for uri do |connection|
          @http.finish(connection)
        end
        sleep HTTP_SLEEP_PERIOD
      end
      duration = Time.now - @http_last_time
      if duration < HTTP_PERIOD
        #STDERR.puts ["sleeping", ncid, duration, Time.now, @http_last_time].inspect
        sleep( HTTP_PERIOD - duration )
      end
      @http_count += 1
      response = @http.request uri
      if REGEXP.match(response.body)
        bibid = $1.dup
        @db[ncid] = bibid
      else
        @non_existent << ncid
      end
      @http_last_time = Time.now
    end
    bibid
  end
end

def extract_bibids(data)
  bibids = []
  if data["path"] =~ /bibid=(\d+)/o
    bibids << $1.dup
  end
  if data["path"] =~ /ncid=(\w+)/o
    bibids << @ncid2bibid.to_bibid($1)
  end
  bibids.compact
end
