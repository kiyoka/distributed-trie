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
    @db = MemCache.new(
                   "localhost:1978",
                   :connect_timeout => 1000.0,
                   :timeout => 1000.0 )
  end

  def put!( key, value, timeout = 0 )
    @db.set( key.force_encoding("ASCII-8BIT"), value.force_encoding("ASCII-8BIT"), timeout )
  end
end


begin
  require 'aws-sdk'
  class KvsSdb < KvsBase
    def initialize( )
      printf( "Amazon SimpleDB access_key_id:     %s\n", ENV['AMAZON_ACCESS_KEY_ID'])
      printf( "Amazon SimpleDB secret_access_key: %s\n", ENV['AMAZON_SECRET_ACCESS_KEY'])
      db = AWS::SimpleDB.new(
                         :access_key_id      => ENV['AMAZON_ACCESS_KEY_ID'],
                         :secret_access_key  => ENV['AMAZON_SECRET_ACCESS_KEY'],
                         :simple_db_endpoint => 'sdb.ap-northeast-1.amazonaws.com',
                         :use_ssl            => false )
      @domain = db.domains.create( 'triebench' )
    end
    def put!( key, value, timeout = 0 )
      item = @domain.items[ key ]
      item.attributes[ 'key' ] = value.force_encoding("ASCII-8BIT")
      puts "simpleDB: " + key
    end
    def get( key, fallback = false )
      item = @domain.items[ key ]
      if item
        vals = item.attributes[ 'index' ].values
        if vals[0]
          vals[0].force_encoding("UTF-8")
        else
          fallback
        end
      else
        fallback
      end
    end
  end
rescue LoadError
end


class TrieBench
  def initialize( filename )
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
      @kvsDbm       = KvsDbm.new
      @data.each { |k|  @kvsDbm.put!( k, k ) }
    }
    @arr << tms.to_a

    # Tokyo Cabinet
    tms = Benchmark.measure ("tc: setup") {
      @kvsTc        = KvsTc.new
      @data.each { |k|   @kvsTc.put!( k, k ) }
    }
    @arr << tms.to_a

    # Memcache
    tms = Benchmark.measure ("memcache: setup") {
      @kvsMemcache    = KvsMemcache.new
      @data.each { |k|   @kvsMemcache.put!( k, k ) }
    }
    @arr << tms.to_a

    # SimpleDB
    tms = Benchmark.measure ("simpleDB: setup") {
      @kvsSdb         = KvsSdb.new
      @data[0..100].each { |k|   @kvsSdb.put!( k, k ) }
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
      @kvsMemcache  = KvsMemcache.new
      @trieMemcache = DistributedTrie::Trie.new( @kvsMemcache,   "BENCH::" )
    }
    @arr << tms.to_a

    # SimpleDB
    tms = Benchmark.measure ("simpleDB: load") {
      @kvsSdb       = KvsSdb.new
      @trieSdb      = DistributedTrie::Trie.new( @kvsSdb,   "BENCH::" )
    }
    @arr << tms.to_a

  end


  def sequential( )
    # "[dbm]"
    tms = Benchmark.measure ("dbm: sequential_get") {
      @data.each { |k|
        @kvsDbm.get( k ) }
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: sequential_get") {
      @data.each { |k|
        @kvsTc.get( k ) }
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache: sequential_get") {
      @data.each { |k|
        @kvsMemcache.get( k ) }
    }
    @arr << tms.to_a

    # [SimpleDB]
    tms = Benchmark.measure ("simpleDB: sequential_get") {
      @data.each { |k|
        @kvsSdb.get( k ) }
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

    # SimpleDB
    @trieSdb  = DistributedTrie::Trie.new( @kvsSdb,   "BENCH::" )
    tms = Benchmark.measure ("simpleDB: setup_trie") {
      @data.each_with_index { |k,i|
        @trieSdb.addKey!( k )
        @trieSdb.commit! if 0 == (i % 10000)
      }
      @trieSdb.commit!
    }
    @arr << tms.to_a
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

  def fuzzy_search( )
    # "[dbm]"
    tms = Benchmark.measure ("dbm: fuzzy_search") {
      data = @trieDbm.fuzzySearch( @jarowKey ) 
      p data.size, data
    }
    @arr << tms.to_a

    # "[Tokyo Cabinet]"
    tms = Benchmark.measure ("tc: fuzzy_search") {
      data = @trieTc.fuzzySearch( @jarowKey )
      p data.size, data
    }
    @arr << tms.to_a

    # "[Memcached]"
    tms = Benchmark.measure ("memcache: fuzzy_search") {
      data = @trieMemcache.fuzzySearch( @jarowKey )
      p data.size, data
    }
    @arr << tms.to_a

    # "[SimpleDB]"
    tms = Benchmark.measure ("simpleDB: fuzzy_search") {
      data = @trieSdb.fuzzySearch( @jarowKey )
      p data.size, data
    }
    @arr << tms.to_a
    #puts "Info: aws-sdk is not installed(5)"

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
    trieBench = TrieBench.new( ARGV[1] )
    puts "setup..."
    trieBench.setup

    puts "setup trie..."
    trieBench.setup_trie

  when "main"
    trieBench = TrieBench.new( ARGV[1] )
    puts "load..."
    trieBench.load

#    puts "sequential..."
#    trieBench.sequential

    puts "sequential jaro..."
    trieBench.sequential_jaro

    puts "fuzzy search..."
    trieBench.fuzzy_search
  end

  trieBench.printResult
end

main

