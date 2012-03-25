#!/usr/local/bin/ruby
#
# http://www.ruby-lang.org/ja/man/html/benchmark.html
#
#
# requires:
#    gdbm (ruby buildin)
#    Tokyo Cabinet
#    Tokyo Tyrant ( with memcache protocol )
#
# options:
#    aws-sdb gem (Amazon SimpleDB)
#
require 'distributedtrie'
require 'distributedtrie/kvs/dbm'
require 'distributedtrie/kvs/tokyocabinet'
require 'distributedtrie/kvs/memcache'
require 'distributedtrie/kvs/simpledb'
require 'benchmark'

class TrieBench

  DBM_PATH    = '/tmp/distributed-trie.db'
  TCH_PATH    = '/tmp/distributed-trie.tch'
  DOMAIN_NAME = 'triebench'

  def initialize( filename )
    @filename = filename
    @data = open( filename ) {|f|
      f.map {|line|
        line.chomp!
      }
    }
    @arr = []
    @jarow    = FuzzyStringMatch::JaroWinkler.create( )
    @jarowKey = "winkler"
  end

  def setup( )
    # dbm
    tms = Benchmark.measure ("dbm: setup") {
      @kvsDbm       = DistributedTrie::KvsDbm.new( DBM_PATH )
      @data.each { |k|  @kvsDbm.put!( k, k ) }
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    tms = Benchmark.measure ("tc: setup") {
      @kvsTc        = DistributedTrie::KvsTc.new( TCH_PATH )
      @data.each { |k|   @kvsTc.put!( k, k ) }
    }
    @arr << tms.to_a

    # Memcache
    tms = Benchmark.measure ("memcache: setup") {
      @kvsMemcache  = DistributedTrie::KvsMemcache.new
      @data.each { |k|   @kvsMemcache.put!( k, k ) }
    }
    @arr << tms.to_a
  end

  def load( )
    load1()
    load2()
  end

  def load1( )
    # dbm
    tms = Benchmark.measure ("dbm: load") {
      @kvsDbm       = DistributedTrie::KvsDbm.new( DBM_PATH )
      @trieDbm      = DistributedTrie::Trie.new( @kvsDbm,  "BENCH::" )
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    tms = Benchmark.measure ("tc: load") {
      @kvsTc        = DistributedTrie::KvsTc.new( TCH_PATH )
      @trieTc       = DistributedTrie::Trie.new( @kvsTc,   "BENCH::" )
    }
    @arr << tms.to_a
  end
  def load2()   # can go parallel
    # Memcache
    tms = Benchmark.measure ("memcache: load") {
      @kvsMemcache  = DistributedTrie::KvsMemcache.new
      @trieMemcache = DistributedTrie::Trie.new( @kvsMemcache,   "BENCH::" )
    }
    @arr << tms.to_a

    # SimpleDB
    @kvsSdb       = DistributedTrie::KvsSdb.new( DOMAIN_NAME )
    if @kvsSdb.enabled?
      tms = Benchmark.measure ("simpleDB: load") {
        @trieSdb      = DistributedTrie::Trie.new( @kvsSdb,   "BENCH::" )
      }
      @arr << tms.to_a
    end
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

  def setup_simpledb( )
    require 'pp'

    @kvsSdb       = DistributedTrie::KvsSdb.new( DOMAIN_NAME )
    if @kvsSdb.enabled?
      items = []
      @kvsTc.db.keys.each_with_index { |key,i|

        val = @kvsTc.db[key]
        h = {
          :name => key,
          :attributes => [{ :name => 'val', :value => val }]
        }
        items << h
        if ( i % 20 ) == 0
          pp i
          @kvsSdb.db.client.batch_put_attributes(:domain_name => DOMAIN_NAME, :items => items )
          items = []
        end
      }
    end
  end


  def sequential_jaro( )
    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: sequential_jaro") {
      data = []
      @data.each { |k|
        if 0.90 <= @jarow.getDistance( k, @jarowKey )
          data << k
        end
      }
      p data.size, data
    }
    @arr << tms.to_a
  end

  THRE = 0.93
  def fuzzy_search( )
    # "[dbm]"
    tms = Benchmark.measure ("dbm: fuzzy_search") {
      data = @trieDbm.fuzzySearch( @jarowKey, THRE )
      p data.size, data
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: fuzzy_search") {
      data = @trieTc.fuzzySearch( @jarowKey, THRE )
      p data.size, data
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache: fuzzy_search") {
      data = @trieMemcache.fuzzySearch( @jarowKey, THRE )
      p data.size, data
    }
    @arr << tms.to_a

    # "[SimpleDB]"
    if @kvsSdb.enabled?
      tms = Benchmark.measure ("simpleDB: fuzzy_search") {
        data = @trieSdb.fuzzySearch( @jarowKey, THRE )
        p data.size, data
      }
      @arr << tms.to_a
      #puts "Info: aws-sdk is not installed(5)"
    end
  end

  def random_fuzzy_search( parallel = false )
    len = @data.length
    step = len / 100
    random_data = []
    100.times{ |i|
      random_data << @data[i * 100]
    }
    p random_data

    if not parallel
      # "[dbm]"
      tms = Benchmark.measure ("dbm: random_fuzzy_search") {
        random_data.each { |x|  @trieDbm.fuzzySearch( x, THRE ) }
      }
      @arr << tms.to_a

      # "[Tokyo Cabinet]"
      tms = Benchmark.measure ("tc: random_fuzzy_search") {
        random_data.each { |x| @trieTc.fuzzySearch( x, THRE ) }
      }
      @arr << tms.to_a
    else
      # "[Memcached]"
      tms = Benchmark.measure ("memcache: random_fuzzy_search") {
        random_data.each { |x| @trieMemcache.fuzzySearch( x, THRE ) }
      }
      @arr << tms.to_a

      # "[SimpleDB]"
      if @kvsSdb.enabled?
        tms = Benchmark.measure ("simpleDB: random_fuzzy_search") {
          random_data.each { |x| @trieSdb.fuzzySearch( x, THRE ) }
        }
        @arr << tms.to_a
      end
    end
  end

  def printResult( )
    printf( "threshold :  %7.2f\n", THRE )
    printf( "filename  :  %s\n",    @filename )
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
    treBench = TrieBench.new( ARGV[1] )
    puts "setup..."
    trieBench.setup

    puts "setup trie..."
    trieBench.setup_trie

    puts "setup simpleDB..."
    trieBench.setup_simpledb

  when "main"
    trieBench = TrieBench.new( ARGV[1] )
    puts "load..."
    trieBench.load

    puts "sequential jaro..."
    trieBench.sequential_jaro

    puts "fuzzy search..."
    trieBench.fuzzy_search

  when "random"
    trieBench = TrieBench.new( ARGV[1] )
    puts "load..."
    trieBench.load2 # paralell

    puts "random fuzzy search..."
    trieBench.random_fuzzy_search( true ) # paralell
  end

  trieBench.printResult
end

main

