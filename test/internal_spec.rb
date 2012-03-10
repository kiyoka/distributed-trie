#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
# internal_spec.rb -  "RSpec file for trie internal hehavior"
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

describe Trie, "Ruby version " do
  it "should" do
    RUBY_VERSION.match( /^1[.]8/ ).should_not be_true
  end
end

class KvsForTest
  def put!( key, value, timeout = 0 )
  end

  def get( key, fallback = false )
  end

  def delete( key )
  end
end


describe Trie, "when _mergeIndex as" do
  before do
    @kvs  = KvsForTest.new
    @trie = Trie.new( @kvs, "TEST::" )
  end
  it "should" do
    @trie._mergeIndex( "a$ a" ).should                         == "a$"
    @trie._mergeIndex( " a$"  ).should                         == "a$"
    @trie._mergeIndex( "a$ b" ).should                         == "a$ b"
    @trie._mergeIndex( "a$ a$ a$   a$" ).should                == "a$"
    @trie._mergeIndex( "a$ a a   a a a    a   a" ).should      == "a$"
    @trie._mergeIndex( "b b b b   b b  ").should               == " b"
    @trie._mergeIndex( "a b c d e f g" ).should                == " a b c d e f g"
    @trie._mergeIndex( "a$ b c$ d e$ f g$" ).should            == "a$ c$ e$ g$ b d f"
  end
end

describe Trie, "when _createTree as" do
  before do
    @kvs  = KvsForTest.new
    @trie = Trie.new( @kvs, "TEST::" )
  end

  it "should" do
    @trie.addKey!( "a" )
    @trie._getInternal( :work ).should == {'$' => 'a$' }
    @trie.addKey!( "ab" )
    @trie._getInternal( :work ).should == {'$' => 'a$', 'a' => 'b$' }
    @trie.addKey!( "in" )
    @trie._getInternal( :work ).should == {'$' => 'a$ i', 'a' => 'b$', 'i' => 'n$' }
  end
end
