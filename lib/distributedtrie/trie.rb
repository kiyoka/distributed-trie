#
#                        Distributed Trie / Trie
#
#
#   Copyright (c) 2012  Kiyoka Nishiyama  <kiyoka@sumibi.org>
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
#
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#
#   3. Neither the name of the authors nor the names of its contributors
#      may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
#   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
require 'fuzzystringmatch'
module DistributedTrie

  class Trie

    # kvsif ... Please implement like DistributedTrie::KvsIF class and specify instance of it.
    def initialize( kvsif, prefixString )
      @kvsif        = kvsif
      @req          = Hash.new
      @prefixString = prefixString
      @key_hash     = Hash.new
    end

    def addKey!( key )
      _createTree( key )
    end

    def deleteKey!( key )
    end

    def commit!()
      @key_hash.each_key { |key|
        cur = @kvsif.get( @prefixString + key, "" )
        @kvsif.put!( @prefixString + key, _mergeIndex( cur + " " + @key_hash[ key ] ))
      }
      @key_hash    = Hash.new
    end

    def cancel()
      @key_hash    = Hash.new
    end

    def listChilds( key )
      result = []
      (term, nonTerm) = _getNextLetters( key )
      #pp [ "searchChilds", key, term, nonTerm ]
      term.each { |x|
        result << key + x
      }
      (term + nonTerm).each { |x|
        result += listChilds( key + x )
      }
      result
    end

    def commonPrefixSearch( key )
      result =  exactMatchSearch( key )
      result += listChilds( key )
    end

    def exactMatchSearch( key )
      (term, nonTerm) = _getNextLetters( key[0...(key.size-1)] )
      #pp [ "exactMatchSearch", key, key[0...(key.size-1)], term, nonTerm ]
      if term.include?( key[-1] )
        [key]
      else
        []
      end
    end

    def _searchWith( key, &block )
      result = []
      (term, nonTerm) = _getNextLetters( key )
      (term + nonTerm).each { |x|
        arg = key + x
        #pp [ "_check", arg ]
        if block.call( arg )
          #pp [ '_match', key, x ]
          result += _searchWith( key + x, &block )
          if term.include?( x )
            result << arg
          end
        end
      }
      result
    end

    def search( entryNode, &block )
      _searchWith( entryNode, &block )
    end

    def rangeSearch( from, to )
      search( '' ) { |x|
        _from = from[0...x.size]
        _to   = to  [0...x.size]
        ( _from <= x ) && ( x <= _to  )
      }
    end

    def fuzzySearch( searchWord, threshold = 0.90 )
      jarow = FuzzyStringMatch::JaroWinkler.create( )
      search( '' ) { |x|
        _word = searchWord[0...x.size]
        if x.size < searchWord.size
          (searchWord.size-x.size).times {|i|
            _word += ' '
            x     += ' '
          }
        end
        result = jarow.getDistance( x, _word )
        #pp [ "fuzzyString", result, x, _word ]
        threshold <= result
      }
    end

    def _getNextLetters( node )
      str = @kvsif.get( @prefixString + node )
      if str
        term    = []
        nonTerm = []
        str.split( /[ ]+/ ).each { |x|
          case x.size
          when 1
            nonTerm << x
          when 2
            term    << x[0...1]
          end
        }
        [ term, nonTerm ]
      else
        [ [], [] ]
      end
    end

    def _mergeIndex( indexStr )
      # "a$ a" => "a$"    # merge into terminal
      # " a$"  => "a$"    # strip spaces
      # "a$ b" => "a$ b"  # alredy merged

      h = Hash.new
      term    = Array.new
      nonTerm = Array.new
      indexStr.split( /[ ]+/ ).each {|entry|
        case entry.size
        when 1
          nonTerm << entry
        when 2
          term    << entry[0...1]
        else
        end
      }
      arr  = term.uniq.map{ |x| x + '$' }
      arr += nonTerm.uniq.reject { |x| term.include?( x ) }
      arr.join( ' ' )
    end

    def _createTree( key )
      h = Hash.new
      str = ''
      key.split( // ).each { |c|
        val = if str.size == (key.size-1)
                c + '$'
              else
                c
              end
        h [ str ] = val
        str += c
      }

      h.keys.each{ |key|
        if not @key_hash.has_key?( key )
          @key_hash[ key ]  = ''
        end
        @key_hash[ key ] += ' ' + h[ key ]
        @key_hash[key] = _mergeIndex( @key_hash[key] )
      }
      @key_hash
    end

    def _getInternal( type = :work )
      @key_hash
    end
  end
end
