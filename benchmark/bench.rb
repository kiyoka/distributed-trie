#!/usr/local/bin/ruby
#
# http://www.ruby-lang.org/ja/man/html/benchmark.html
#
require 'distributedtrie'
require 'benchmark'
require 'tokyocabinet'
require 'gdbm'
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
    @db = GDBM.new( "/tmp/distributed-trie.db" )
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
    @db = MemCache.new( "localhost:1978" )
  end

  def put!( key, value, timeout = 0 )
    @db.set( key.force_encoding("ASCII-8BIT"), value.force_encoding("ASCII-8BIT"), timeout )
  end
end

class KvsMemcacheEmpty < KvsBase
  def initialize( )
  end

  def put!( key, value, timeout = 0 )
  end
  def get( key, fallback = false )
    key
  end
end


class TrieBench
  LOOPTIMES        = 1
  MAGNIFYING_POWER = 1

  def initialize( filename, memcacheFlag )
    @data = open( filename ) {|f|
      f.map {|line|
        line.chomp!
      }
    }
    @arr = []
    @memcacheFlag = memcacheFlag
    @jarow    = FuzzyStringMatch::JaroWinkler.create( )
    @jarowKey = "winkler"
  end

  attr_reader :memcacheFlag

  def setup( )
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
      if @memcacheFlag 
        @kvsMemcache  = KvsMemcache.new
      else
        @kvsMemcache  = KvsMemcacheEmpty.new
      end
      @data.each { |k|   @kvsMemcache.put!( k, k * MAGNIFYING_POWER ) }
    }
    @arr << tms.to_a
  end

  def load( )
    # dbm
    tms = Benchmark.measure ("dbm: load") {
      @kvsDbm       = KvsDbm.new
      @trieDbm      = DistributedTrie::Trie.new( @kvsDbm,  "BENCH::" )
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    tms = Benchmark.measure ("tc: load") {
      @kvsTc        = KvsTc.new
      @trieTc       = DistributedTrie::Trie.new( @kvsTc,   "BENCH::" )
    }
    @arr << tms.to_a

    # Memcache
    tms = Benchmark.measure ("memcache: load") {
      if @memcacheFlag 
        @kvsMemcache  = KvsMemcache.new
      else
        @kvsMemcache  = KvsMemcacheEmpty.new
      end
      @trieMemcache  = DistributedTrie::Trie.new( @kvsMemcache,   "BENCH::" )
    }
    @arr << tms.to_a
  end


  def sequential( )
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

  def setup_trie( )
    # dbm
    @trieDbm  = DistributedTrie::Trie.new( @kvsDbm,  "BENCH::" )
    tms = Benchmark.measure ("dbm: setup_trie") {
      @data.each_with_index { |k,i|
        @trieDbm.addKey!( k )
        @trieDbm.commit! if 0 == (i % 10000)
      }
      @trieDbm.commit!
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    @trieTc   = DistributedTrie::Trie.new( @kvsTc,   "BENCH::" )
    tms = Benchmark.measure ("tc: setup_trie") {
      @data.each_with_index { |k,i|
        @trieTc.addKey!( k )
        @trieTc.commit! if 0 == (i % 10000)
      }
      @trieTc.commit!
    }
    @arr << tms.to_a

    # Memcache
    @trieMemcache  = DistributedTrie::Trie.new( @kvsMemcache,   "BENCH::" )
    tms = Benchmark.measure ("memcache: setup_trie") {
      @data.each_with_index { |k,i|
        @trieMemcache.addKey!( k )
        @trieMemcache.commit! if 0 == (i % 10000)
      }
      @trieMemcache.commit!
    }
    @arr << tms.to_a
  end

  def sequential_jaro( )
    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: sequential_jaro") {
      data = []
      LOOPTIMES.times { |i|
        @data.each { |k|
          if 0.90 < @jarow.getDistance( k, @jarowKey )
            data << k
          end
        }
      }
      p data[0..10]
    }
    @arr << tms.to_a
  end

  def fuzzy_search( )
    # "[dbm]"
    tms = Benchmark.measure ("dbm: fuzzy_search") {
      LOOPTIMES.times { |i|
        @trieDbm.fuzzySearch( @jarowKey ) 
      }
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: fuzzy_search") {
      LOOPTIMES.times { |i|
        @trieTc.fuzzySearch( @jarowKey )
      }
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache(1/#{LOOPTIMES}): fuzzy_search") {
      @trieMemcache.fuzzySearch( @jarowKey )
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
  case ARGV[0]
  when "setup"
    trieBench = TrieBench.new( ARGV[1], "true" == ARGV[2] )
    printf( "memcacheFlag = [%s]\n", trieBench.memcacheFlag )
    puts "setup..."
    trieBench.setup

    puts "setup trie..."
    trieBench.setup_trie
    
  when "main"
    trieBench = TrieBench.new( ARGV[1], "true" == ARGV[2] )
    printf( "memcacheFlag = [%s]\n", trieBench.memcacheFlag )
    puts "load..."
    trieBench.load

    puts "sequential..."
    trieBench.sequential
    
    puts "sequential jaro..."
    trieBench.sequential_jaro
    
    puts "fuzzy search..."
    trieBench.fuzzy_search
  end

  trieBench.printResult
end

main

