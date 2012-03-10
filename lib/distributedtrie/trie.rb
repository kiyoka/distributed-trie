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
      @key_hash    = Hash.new
    end

    def cancel()
    end

    def commonPrefixSearch( key )
    end

    def search( key, proc )
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
          term    << entry[0..0]
        else
        end
      }
      result = term.uniq.map{ |x| x + '$' }.join( ' ' )
      #p 'term = ', result
      nonTerm = nonTerm.uniq.reject { |x| term.include?( x ) }
      #p 'nonTerm  = ', nonTerm.join( ' ' )
      if ( 0 < nonTerm.size )
        result += ' ' + nonTerm.join( ' ' )
      end
      result
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
        case str.size
        when 0
          h [ '$' ] = val
        else
          h [ str ] = val
        end
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
