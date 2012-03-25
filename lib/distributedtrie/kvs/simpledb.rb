#
#                        Distributed Trie / KvsSdb
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
require 'distributedtrie/kvs/base'
module DistributedTrie

  # AWS SimpleDB implementation
  begin
    require 'aws-sdk'
    class KvsSdb < KvsBase
      def initialize( domainName )
        printf( "Amazon SimpleDB access_key_id:     %s\n", ENV['AMAZON_ACCESS_KEY_ID'])
        printf( "Amazon SimpleDB secret_access_key: %s\n", ENV['AMAZON_SECRET_ACCESS_KEY'])
        @domainName = domainName
        @db = AWS::SimpleDB.new(
                               :access_key_id      => ENV['AMAZON_ACCESS_KEY_ID'],
                               :secret_access_key  => ENV['AMAZON_SECRET_ACCESS_KEY'],
                               :simple_db_endpoint => 'sdb.ap-northeast-1.amazonaws.com',
                               :use_ssl            => false )
        @domain = @db.domains.create( domainName )
      end
      def put!( key, value, timeout = 0 )
        item = @domain.items[ key ]
        item.attributes[ 'val' ] = value.force_encoding("ASCII-8BIT")
        puts "simpleDB put: " + key
      end
      def get( key, fallback = false )
        res = @db.client.get_attributes(
                             :domain_name => @domainName,
                             :item_name => key,
                             :attribute_names => ['val'],
                             :consistent_read => false
                             )
        val = nil
        res.attributes.each { |x|
          val = x.value
        }
        if val
          puts "simpleDB get: " + key + "," + val
          val.force_encoding("UTF-8")
        else
          fallback
        end
      end
      def enabled?()   true   end

      attr_reader :db
    end
  rescue LoadError
    class KvsSdb < KvsBase
      def enabled?()   false  end
    end
  end
end
