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

    @trie.fuzzySearch( "come"           ).should    == ["comedy"]
    @trie.fuzzySearch( "come",    0.85  ).should    == ["comedy", "code"]
    @trie.fuzzySearch( "come",    0.82  ).should    == ["comedy", "coming", "code"]
    @trie.fuzzySearch( "come",    0.80  ).should    == ["command", "comedy", "coming", "code"]

    @trie.fuzzySearch( "comm"                 ).should    == ["command"]
    @trie.fuzzySearch( "communication", 0.92  ).should    == ["communication", "community"]

    @trie.fuzzySearch( "copylight"            ).should    == ["copyright"]
    @trie.fuzzySearch( "copyrigh"     , 0.99  ).should    == ["copyright"]
    @trie.fuzzySearch( "copyleft"             ).should    == ["copy"]

    jarow = FuzzyStringMatch::JaroWinkler.create( )
    @words.select { |word| 0.85 <= jarow.getDistance( word, "come" )          }.should == ["comedy", "code"]
    @words.select { |word| 0.90 <= jarow.getDistance( word, "copylight" )     }.should == ["copyright"]
    @words.select { |word| 0.92 <= jarow.getDistance( word, "communication" ) }.should == ["communication", "community"]
    @words.select { |word| 0.90 <= jarow.getDistance( word, "copyleft" )      }.should == ["copy"]
  end
end
