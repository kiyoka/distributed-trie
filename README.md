# What is distributed-trie

* distributed-trie is a trie library on key-value store.
* It is scalable.
* It supports tokyo cabinet / dbm / gdbm

## The reason why i developed 
* I need a trie library for Sekka ( japanese input method ).
* I need a trie library which written in pure Ruby.
* I need a trie library which can scale.

## Installing 
  1. gem install distributed-trie

## Features
* Add    entry by key and value.
* Delete entry by key.
* commonPrefixSearch by key.
* search with user-defined-function.

## Sample code 

<code>
    require 'distributed-rie'
    trie = DistributedTrie::Trie.create( kvs, "Sample::" )
    trie.addKey!( "apple",       10 )
    trie.addKey!( "application", 20 )
    trie.addKey!( "orange",      30 )
    result = trie.commonPrefixSearch( "app" )
    print result;
    # =>  [ "apple", "application" ]
</code>

## Requires
 - Ruby 1.9.1 or higher

## Author
 - Copyright (C) Kiyoka Nishiyama <kiyoka@sumibi.org>

## See also
 - <http://github.com/naoya/perl-text-jarowinkler>

## License
 - BSD License

