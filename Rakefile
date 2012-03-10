# -*- mode: ruby; -*-
#                                           Rakefile for Distributed-Trie
# Release Engineering
#   1. edit the VERSION.yml file
#   2. rake
#   3. rake gemspec  &&   rake build
#      to generate distributed-trie-x.x.x.gem
#   4. install distributed-trie-x.x.x.gem to clean environment and test
#   5. rake release
#   6. gem push pkg/distributed-trie-x.x.x.gem   ( need gem version 1.3.6 or higer. Please "gem update --system" to update )

require 'rake'
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "distributed-trie"
    gemspec.summary = "distributed-trie is a trie library on key-value store."
    gemspec.description = "distributed-trie is a trie library on key-value store."
    gemspec.email = "kiyoka@sumibi.org"
    gemspec.homepage = "http://github.com/kiyoka/distributed-trie"
    gemspec.authors = ["Kiyoka Nishiyama"]
    gemspec.files = FileList[
                    'Rakefile',
                    '.gemtest',
                    'VERSION.yml',
                    'lib/**/*.rb',
                    'test/*'
                      ].to_a
    gemspec.add_development_dependency "rake"
    gemspec.add_development_dependency "rspec"
  end
rescue LoadError
  puts 'Jeweler not available. If you want to build a gemfile, please install with "sudo gem install jeweler"'
end

task :default => [:test] do
end

task :test do
  stage1 =  []
  stage1 << "time ruby -I ./lib `which rspec` -b   ./test/nendo_spec.rb          -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
  stage1 << "time ruby -I ./lib `which rspec` -b   ./test/syntax_spec.rb         -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
  stage1 << "time ruby -I ./lib `which rspec` -b   ./test/testframework_spec.rb  -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
  stage1 << "time ruby  -I ./lib ./bin/nendo ./test/srfi-1-test.nnd"
  stage2 =  []
  stage2 << "/bin/rm -f test.record"
  stage2 << "echo "" > test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/textlib-test.nnd              >> test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/nendo-util-test.nnd           >> test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/json-test.nnd                 >> test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/srfi-2-test.nnd               >> test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/srfi-26-test.nnd              >> test.log"
  stage2 << "time ruby -I ./lib ./bin/nendo ./test/util-list-test.nnd            >> test.log"
  stage2 << "cat test.record"
  arr = []
  arr += stage1
  arr += stage2
  arr.each {|str|
    sh str
  }
end

task :test2 do
  stage1 =  []
  stage1 << "/bin/rm -f test.record"
  stage1 << "echo "" > test2.log"
  stage1 << "time ruby -I ./lib ./bin/nendo ./test/match-test.nnd                | tee -a test2.log"
  stage1 << "time ruby -I ./lib ./bin/nendo ./test/util-combinations-test.nnd    | tee -a test2.log"
  stage1 << "cat test.record"
  arr = []
  arr += stage1
  arr.each {|str|
    sh str
  }
end

task :bench do
  sh "ruby --version"
  sh "ruby -I ./lib ./bin/nendo      ./benchmark/benchmark.nnd"
  sh "                    nendo      ./benchmark/benchmark.nnd"
end
