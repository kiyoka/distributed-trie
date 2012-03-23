# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "distributed-trie"
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kiyoka Nishiyama"]
  s.date = "2012-03-20"
  s.description = "distributed-trie is a trie library on key-value store."
  s.email = "kiyoka@sumibi.org"
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "Rakefile",
    "VERSION.yml",
    "lib/distributedtrie.rb",
    "lib/distributedtrie/kvsif.rb",
    "lib/distributedtrie/trie.rb",
    "test/bigdata_spec.rb",
    "test/internal_spec.rb",
    "test/rspec_formatter_for_emacs.rb",
    "test/usecase_spec.rb"
  ]
  s.homepage = "http://github.com/kiyoka/distributed-trie"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "distributed-trie is a trie library on key-value store."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<fuzzy-string-match>, [">= 0.9.3"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<fuzzy-string-match>, [">= 0.9.3"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<fuzzy-string-match>, [">= 0.9.3"])
  end
end
