#!/usr/local/bin/ruby
#
# http://www.ruby-lang.org/ja/man/html/benchmark.html
#
require 'distributedtrie'
require 'benchmark'
require 'tokyocabinet'
require 'dbm'


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


class KvsBench
  LOOPTIMES = 10

  def initialize( filename )
    @data = open( filename ) {|f|
      f.map {|line|
        line.chomp!
      }
    }
  end

  def setup( )
    # Hash (on memory)
    @kvsHash = DistributedTrie::KvsIf.new
    @data.each { |k| @kvsHash.put!( k, k ) }

    # dbm
    @kvsDbm  = KvsDbm.new
    @data.each { |k|  @kvsDbm.put!( k, k ) }

    # Tokyo Cabinet
    @kvsTc   = KvsTc.new
    @data.each { |k|   @kvsTc.put!( k, k ) }
  end

  def go( )
    @arr = []

    # "[Hash]"
    tms = Benchmark.measure ("hash") {
      @data.each { |k|
        LOOPTIMES.times { |i| @kvsHash.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[dbm]"
    tms = Benchmark.measure ("dbm") {
      @data.each { |k|
        LOOPTIMES.times { |i| @kvsDbm.get( k ) }
      }
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc") {
      @data.each { |k|
        LOOPTIMES.times { |i| @kvsTc.get( k ) }
      }
    }
    @arr << tms.to_a
  end

  def printResult( )
    @arr.each { |elem|
      printf( "%5s %3.4f %3.4f %3.4f\n", elem[ 0 ], elem[ 1 ], elem[ 2 ], elem[ 5 ] )
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
  kvsBench.setup

  kvsBench.go
  kvsBench.printResult
end

main
