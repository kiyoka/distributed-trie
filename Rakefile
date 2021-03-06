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
  require 'jeweler2'
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
                    'README.md',
                    'COPYING',
                    'lib/**/*.rb',
                    'lib/*.png',
                    'test/*'
                      ].to_a
    gemspec.add_development_dependency "rake"
    gemspec.add_development_dependency "rspec"
    gemspec.add_dependency( "fuzzy-string-match", ">= 0.9.3" )
  end
rescue LoadError
  puts 'Jeweler2 not available. If you want to build a gemfile, please install with "sudo gem install jeweler2"'
end

task :default => [:test] do
end

task :test do
  sh "time ruby -I ./lib `which rspec` -b   ./test/internal_spec.rb     -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
  sh "time ruby -I ./lib `which rspec` -b   ./test/usecase_spec.rb      -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
  sh "time ruby -I ./lib `which rspec` -b   ./test/bigdata_spec.rb      -r ./test/rspec_formatter_for_emacs.rb -f CustomFormatter"
end

DATA="aspell.dump.txt"
#DATA="wlist_match1.txt"

task :bench_setup do
  sh "ruby -I ./lib ./benchmark/bench.rb  setup  ./data/#{DATA}"
end

task :bench do
  # URL http://www.keithv.com/software/wlist/wlist_match1.zip
  sh "ruby -I ./lib ./benchmark/bench.rb  main   ./data/#{DATA}"
end

task :bench_random do
  sh "ruby -I ./lib ./benchmark/bench.rb random  ./data/#{DATA}"
end

task :dumptc do
  sh "bash -c 'tchmgr list -pv /tmp/distributed-trie.tch > /tmp/distributed-trie.txt'"
end

task :data do
  sh "aspell -l en dump master > ./data/aspell.dump.txt"
end

