#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
# bigdata_spec.rb -  "RSpec file for bigdata test-case"
#
#   Copyright (c) 2012     Kiyoka Nishiyama  <kiyoka@sumibi.org>
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
require 'distributedtrie'
include DistributedTrie


describe Trie, "when initialized as '()" do
  before do
    @kvs  = DistributedTrie::KvsIf.new
    @trie = Trie.new( @kvs, "TEST::" )
    @arr = "0123456789abcdefghijklmnopqrstuvwxyz".split(//)
  end

  it "should" do
    @arr.each { |s1|
      @arr.each { |s2|
        @arr.each { |s3|
          @trie.addKey!( s1+s2+s3 )
        }
      }
    }

    @trie.addKey!( "0" )
    @trie.addKey!( "1" )
    @trie.addKey!( "AA" )
    @trie.addKey!( "BB" )

    @trie._getInternal( :work ).size.should == 1335
    @trie.commit!()

    @trie.exactMatchSearch( "0" ).should           == ["0"]
    @trie.exactMatchSearch( "1" ).should           == ["1"]
    @trie.exactMatchSearch( "2" ).should           == []
    @trie.exactMatchSearch( "AA" ).should          == ["AA"]
    @trie.exactMatchSearch( "BB" ).should          == ["BB"]
    @trie.exactMatchSearch( "CC" ).should          == []
    @trie.exactMatchSearch( "aa" ).should          == []
    @trie.exactMatchSearch( "bb" ).should          == []
    @trie.exactMatchSearch( "aaa" ).should         == ["aaa"]
    @trie.exactMatchSearch( "aaa" ).should         == ["aaa"]
    @trie.exactMatchSearch( "zzz" ).should         == ["zzz"]
    @trie.exactMatchSearch( "012" ).should         == ["012"]

    @trie.commonPrefixSearch( '00' ).should        == @arr.map{ |x| "00" + x }
    @trie.commonPrefixSearch( '' ).size.should     == (@arr.size * @arr.size * @arr.size) + 4
    @trie.search( 'ab'  ){|x| ( 'aba'  <= x) && (x <=   'abe') }.should      == ["aba", "abb", "abc", "abd", "abe"]
    @trie.search( 'zz'  ){|x| x.match( /zz[7-9]/ )  }.should                 == ["zz7", "zz8", "zz9"]

    @trie.search( ''    ){|x| 1 == x.size }.should                           == ["0", "1"]
    @trie.search( ''    ){|x| 2 >= x.size }.should                           == ["0", "1", "AA", "BB"]

  end
end
