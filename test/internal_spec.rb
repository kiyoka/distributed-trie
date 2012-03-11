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
  def initialize()
    @data = Hash.new
  end

  def put!( key, value, timeout = 0 )
    @data[key] = value
  end

  def get( key, fallback = false )
    val = @data[key]
    if val
      val
    else
      fallback
    end
  end

  def delete( key )
  end

  def _getInternal( )
    arr = []
    @data.keys.each { |key|
      arr << [key,@data[key]]
    }
    arr
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
    @trie._mergeIndex( "b b b b   b b  ").should               == "b"
    @trie._mergeIndex( "a b c d e f g" ).should                == "a b c d e f g"
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
    @trie._getInternal( :work ).should == { '' => 'a$' }
    @trie.addKey!( "ab" )
    @trie._getInternal( :work ).should == { '' => 'a$', 'a' => 'b$' }
    @trie.addKey!( "in" )
    @trie._getInternal( :work ).should == { '' => 'a$ i', 'a' => 'b$', 'i' => 'n$' }
  end
end

describe Trie, "when _commit as" do
  before do
    @kvs  = KvsForTest.new
    @trie = Trie.new( @kvs, "TEST::" )
  end

  it "should" do
    @trie.addKey!( "app" )
    @trie._getInternal( :work ).should == { ""=>"a", "a"=>"p", "ap"=>"p$" }
    @trie.addKey!( "apple" )
    @trie._getInternal( :work ).should == { ""=>"a", "a"=>"p", "ap"=>"p$", "app"=>"l", "appl"=>"e$" }
    @trie.addKey!( "application" )
    @trie._getInternal( :work ).should == { ""=>"a", "a"=>"p", "ap"=>"p$", "app"=>"l", "appl"=>"e$ i", "appli"=>"c", "applic"=>"a", "applica"=>"t", "applicat"=>"i", "applicati"=>"o", "applicatio"=>"n$" }
    @trie.commit!()
    @trie._getInternal( :work ).should == {}
    @kvs._getInternal( ).should        == [
      ["TEST::", "a"],
      ["TEST::a", "p"],
      ["TEST::ap", "p$"],
      ["TEST::app", "l"],
      ["TEST::appl", "e$ i"],
      ["TEST::appli", "c"],
      ["TEST::applic", "a"],
      ["TEST::applica", "t"],
      ["TEST::applicat", "i"],
      ["TEST::applicati", "o"],
      ["TEST::applicatio", "n$"]]
    @trie.listChilds( "" ).should                == ["app", "apple", "application"]
    @trie.listChilds( "ap" ).should              == ["app", "apple", "application"]
    @trie.listChilds( "app" ).should             == [       "apple", "application"]
    @trie.listChilds( "appl" ).should            == [       "apple", "application"]
    @trie.listChilds( "appli" ).should           == [                "application"]

    @trie.commonPrefixSearch( "" ).should        == ["app", "apple", "application"]
    @trie.commonPrefixSearch( "ap" ).should      == ["app", "apple", "application"]
    @trie.commonPrefixSearch( "app" ).should     == ["app", "apple", "application"]
    @trie.commonPrefixSearch( "appl" ).should    == [       "apple", "application"]
    @trie.commonPrefixSearch( "appli" ).should   == [                "application"]
  end
end
