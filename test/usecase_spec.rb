#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
# usecase_spec.rb -  "RSpec file for ordinary usecase"
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

describe Trie, "when you create auto complete application " do
  before do
    @kvs  = DistributedTrie::KvsIf.new
    @trie = Trie.new( @kvs, "TEST::" )
  end

  it "should" do
    @trie.addKey!( "i" )
    @trie.addKey!( "in" )
    @trie.addKey!( "inn" )
    @trie.addKey!( "communication" )
    @trie.addKey!( "command" )
    @trie.addKey!( "come" )
    @trie.addKey!( "coming" )
    @trie.addKey!( "code" )
    @trie.addKey!( "copy" )
    @trie.addKey!( "copyright" )
    @trie.commit!

    @trie.commonPrefixSearch( "i" ).should       == ["i", "in", "inn"]
    @trie.commonPrefixSearch( "in" ).should      == ["in", "inn"]
    @trie.commonPrefixSearch( "c" ).should       == ["come", "communication", "command", "coming", "code", "copy", "copyright"]
    @trie.commonPrefixSearch( "co" ).should      == ["come", "communication", "command", "coming", "code", "copy", "copyright"]
    @trie.commonPrefixSearch( "comm" ).should    == ["communication", "command"]
    @trie.commonPrefixSearch( "cod" ).should     == ["code"]
    @trie.commonPrefixSearch( "cop" ).should     == ["copy", "copyright"]

    @trie.exactMatchSearch( "copy" ).should      == ["copy"]
  end
end

def _roundDistance( arr )
  arr.map { |x|
    val = x[0] * 1000
    [ val.round / 1000.0, x[1] ]
  }
end

describe Trie, "when you create fuzzy-string-search application " do
  before do
    @kvs   = DistributedTrie::KvsIf.new
    @trie  = Trie.new( @kvs, "TEST::" )
    @words = [
      "communication",
      "community",
      "command",
      "comedy",
      "coming",
      "code",
      "copy",
      "copyright"
    ]
  end

  it "should" do
    @words.each { |word|  @trie.addKey!( word ) }
    @trie.commit!

    _roundDistance( @trie.fuzzySearch( "come"           )).should    == [[0.933, "comedy"]]
    _roundDistance( @trie.fuzzySearch( "come",    0.85  )).should    == [[0.933, "comedy"], [0.867, "code"]]
    _roundDistance( @trie.fuzzySearch( "come",    0.82  )).should    == [[0.933, "comedy"], [0.867, "code"], [0.825, "coming"]]
    _roundDistance( @trie.fuzzySearch( "come",    0.80  )).should    == [[0.933, "comedy"], [0.867, "code"], [0.825, "coming"], [0.808, "command"]]

    _roundDistance( @trie.fuzzySearch( "comm"                 )).should    == [[0.914, "command"]]
    _roundDistance( @trie.fuzzySearch( "communication", 0.92  )).should    == [[1.0, "communication"], [0.924, "community"]]

    _roundDistance( @trie.fuzzySearch( "copylight"            )).should    == [[0.956, "copyright"]]
    _roundDistance( @trie.fuzzySearch( "copyrigh"     , 0.99  )).should    == [[0.993, "copyright"]]
    _roundDistance( @trie.fuzzySearch( "copyleft"             )).should    == [[0.9, "copy"]]

    jarow = FuzzyStringMatch::JaroWinkler.create( )
    @words.select { |word| 0.85 <= jarow.getDistance( word, "come" )          }.should == ["comedy", "code"]
    @words.select { |word| 0.90 <= jarow.getDistance( word, "copylight" )     }.should == ["copyright"]
    @words.select { |word| 0.92 <= jarow.getDistance( word, "communication" ) }.should == ["communication", "community"]
    @words.select { |word| 0.90 <= jarow.getDistance( word, "copyleft" )      }.should == ["copy"]
  end
end
