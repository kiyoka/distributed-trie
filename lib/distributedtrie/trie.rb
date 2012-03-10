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
      @queue        = []
      @prefixString = prefixString
    end

    def addKeyword!( key, value )
      @queue[ key ] = value
    end

    def deleteKeyword!( key )
    end

    def commit!()
    end

    def cancel()
    end

    def commonPrefixSearch( key )
    end

    def search( key, proc )
    end


    def _createTree( key )
      arr = []
      str = ''
      key[0..(key.length)].each |c| {
        if 0 < str.size
          arr [ str ] = c
        end
        str += c
      }
      @key_arr = arr
    end

    def _getInternal( type = :work )
      @key_arr
    end
  end
end
