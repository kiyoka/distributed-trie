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
    @arr = []
  end

  def setup( )
    # Hash (on memory)
    tms = Benchmark.measure ("hash: setup") {
      @kvsHash      = DistributedTrie::KvsIf.new
      @data.each { |k| @kvsHash.put!( k, k * MAGNIFYING_POWER ) }
    }
    @arr << tms.to_a

    # dbm
    tms = Benchmark.measure ("dbm: setup") {
      @kvsDbm       = KvsDbm.new
      @data.each { |k|  @kvsDbm.put!( k, k * MAGNIFYING_POWER ) }
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    tms = Benchmark.measure ("tc: setup") {
      @kvsTc        = KvsTc.new
      @data.each { |k|   @kvsTc.put!( k, k * MAGNIFYING_POWER ) }
    }
    @arr << tms.to_a

    # Memcache
    tms = Benchmark.measure ("memcache: setup") {
      @kvsMemcache  = KvsMemcache.new
      @data.each { |k|   @kvsMemcache.put!( k, k * MAGNIFYING_POWER ) }
    }
    @arr << tms.to_a
  end

  def sequential( )
    # "[Hash]"
    tms = Benchmark.measure ("hash: sequential_get") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsHash.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[dbm]"
    tms = Benchmark.measure ("dbm: sequential_get") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsDbm.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: sequential_get") {
      LOOPTIMES.times { |i|
        @data.each { |k|
          @kvsTc.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache(1/#{LOOPTIMES}): sequential_get") {
      @data.each { |k|
        @kvsMemcache.get( k ) }
    }
    @arr << tms.to_a
  end

  def printResult( )
    @arr.each { |elem|
      printf( "%35s:  %7.2f %7.2f %7.2f\n", elem[ 0 ], elem[ 1 ], elem[ 2 ], elem[ 5 ] )
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

  puts "sequential..."
  kvsBench.sequential
  kvsBench.printResult
end

main

