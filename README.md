# What is distributed-trie

![Logo]( http://pix.am/FeuT.png )

* distributed-trie is a trie library for key-value store.
* It is scalable ( with DHT system like DynamoDB )
* It supports Tokyo Cabinet / memcached / gdbm / pure hash / Redis / DynamoDB / SimpleDB

## The reason why i developed 
* I need a trie library for Sekka ( japanese input method ).
* I need a trie library which written in pure Ruby.
* I need a trie library which can scale out.

## Installing 

    gem install distributed-trie

## Features
* Add    keyword to trie.
* Delete keyword to trie.         ( not implemented... )
* commonPrefixSearch by keyword.
* fuzzySearch by jaro winker edit distance.
* search with user-defined-function.

## Architecture
* distributed-trie gem only manage trie data structure.
* You should manage your application data which corresponds to trie key.

![Figure]( http://pix.am/kYLz.png )


## Sample code

    require 'distributedtrie'
    require 'distributedtrie/kvs/tokyocabinet'
    kvsTc = DistributedTrie::KvsTc.new( '/tmp/distributed-trie.tch' )
    trie = DistributedTrie::Trie.new( kvsTc, "Sample::" )
    trie.addKey!( "apple"       )
    trie.addKey!( "application" )
    trie.addKey!( "orange"      )
    trie.commit!
    result = trie.commonPrefixSearch( "app" )
    print result
    # =>  [ "apple", "application" ]
    result = trie.fuzzySearch( "app", 0.80 )
    print result
    # =>  [[0.9066666666666667, "apple"], [0.8236914600550963, "application"]]

## Requires
 - Ruby  1.9.1 or higher
 - JRuby 1.6.6 or higher
 - fuzzy-string-match gem

## Author
 - Copyright (C) Kiyoka Nishiyama <kiyoka@sumibi.org>

## See also
 - <http://github.com/kiyoka/distributed-trie>
 - <http://en.wikipedia.org/wiki/Distributed_hash_table>
 - <http://www.allthingsdistributed.com/2007/10/amazons_dynamo.html>

## License
 - BSD License
