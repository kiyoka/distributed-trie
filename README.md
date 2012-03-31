# What is distributed-trie

* distributed-trie is a trie library on key-value store.
* It is scalable.
* It supports Tokyo Cabinet / memcached / gdbm / ruby's pure hash / Redis

## The reason why i developed 
* I need a trie library for Sekka ( japanese input method ).
* I need a trie library which written in pure Ruby.
* I need a trie library which can scale out.

## Installing 
  1. gem install distributed-trie

## Features
* Add    keyword to trie.
* Delete keyword to trie.         ( not implemented... )
* commonPrefixSearch by keyword.
* fuzzySearch by jaro winker edit distance.
* search with user-defined-function.

## Architecture
* distributed-trie gem only manage trie data structure.
* You should manage your application data which corresponds to trie key.

![Figure]( http://pix.am/urEv.png )


## Sample code

    require 'distributedtrie'
    require 'distributedtrie/kvs/tokyocabinet'
    kvsTc = DistributedTrie::KvsTc.new( '/tmp/distributed-trie.tch' )
    trie = DistributedTrie::Trie.create( kvsTc, "Sample::" )
    trie.addKey!( "apple"       )
    trie.addKey!( "application" )
    trie.addKey!( "orange"      )
    result = trie.commonPrefixSearch( "app" )
    print result;
    # =>  [ "apple", "application" ]
    result = trie.fuzzySearch( "apppp" )
    print result;
    # =>  [ "apple", "application" ]

## Requires
 - Ruby 1.9.1 or higher
 - fuzzy-string-match gem

## Author
 - Copyright (C) Kiyoka Nishiyama <kiyoka@sumibi.org>

## See also
 - <http://github.com/kiyoka/distributed-trie>

## License
 - BSD License

