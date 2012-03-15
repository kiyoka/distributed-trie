#!/usr/local/bin/ruby
#
# http://www.ruby-lang.org/ja/man/html/benchmark.html
#
require 'distributedtrie'
require 'benchmark'
require 'tokyocabinet'
require 'dbm'
require 'memcache'

class KvsBase < DistributedTrie::KvsIf
  def put!( key, value, timeout = 0 )
    @db[ key.force_encoding("ASCII-8BIT") ] = value.force_encoding("ASCII-8BIT")
  end

  def get( key, fallback = false )
    val = @db[ key ]
    if val
      val.force_encoding("UTF-8")
    else
      fallback
    end
  end
end


class KvsDbm < KvsBase
  def initialize( )
    @db = DBM.new( "/tmp/distributed-trie.db" )
  end
end


class KvsTc < KvsBase
  def initialize( )
    @db = TokyoCabinet::HDB.new( )
    @db.open( "/tmp/distributed-trie.tch", TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT )
  end
end


class KvsMemcache < KvsBase
  def initialize( )
    @db = MemCache.new( "localhost:11211" )
  end

  def put!( key, value, timeout = 0 )
    @db.set( key.force_encoding("ASCII-8BIT"), value.force_encoding("ASCII-8BIT"), timeout )
  end
end


class KvsBench
  LOOPTIMES        = 10
  MAGNIFYING_POWER = 10

  def initialize( filename )
    @data = open( filename ) {|f|
      f.map {|line|
        line.chomp!
      }
    }
  end

  def setup( )
    # Hash (on memory)
    @kvsHash      = DistributedTrie::KvsIf.new
    @data.each { |k| @kvsHash.put!( k, k * MAGNIFYING_POWER ) }

    # dbm
    @kvsDbm       = KvsDbm.new
    @data.each { |k|  @kvsDbm.put!( k, k * MAGNIFYING_POWER ) }

    # Tokyo Cabinet
    @kvsTc        = KvsTc.new
    @data.each { |k|   @kvsTc.put!( k, k * MAGNIFYING_POWER ) }

    # Memcache
    @kvsMemcache  = KvsMemcache.new
    @data.each { |k|   @kvsMemcache.put!( k, k * MAGNIFYING_POWER ) }
  end

  def go( )
    @arr = []

    # "[Hash]"
    tms = Benchmark.measure ("hash") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsHash.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[dbm]"
    tms = Benchmark.measure ("dbm") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsDbm.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsTc.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache(1/#{LOOPTIMES})") {
      @data.each { |k|
        @kvsMemcache.get( k ) }
    }
    @arr << tms.to_a
  end

  def printResult( )
    @arr.each { |elem|
      printf( "%20s:  %3.4f %3.4f %3.4f\n", elem[ 0 ], elem[ 1 ], elem[ 2 ], elem[ 5 ] )
    }
  end

  def dumpData( )
    puts "  length :" + @data.length.to_s
    puts "    " + @data.take( 10 ).join( ' ' ) + "..."
    puts "    " + @data[1000..1010].join( ' ' ) + "..."
    puts "      . "
    puts "      . "
    puts "      . "
  end
end


def main( )
  kvsBench = KvsBench.new( ARGV[0] )
  puts "setup..."
  kvsBench.setup

  puts "main..."
  kvsBench.go
  kvsBench.printResult
end

main

