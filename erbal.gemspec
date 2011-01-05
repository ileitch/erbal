--- !ruby/object:Gem::Specification 
name: erbal
version: !ruby/object:Gem::Version 
  hash: 977940511
  prerelease: true
  segments: 
  - 1
  - 2
  - rc2
  version: 1.2.rc2
platform: ruby
authors: 
- Ian Leitch
autorequire: 
bindir: bin
cert_chain: []

date: 2011-01-05 00:00:00 +11:00
default_executable: 
dependencies: []

description: Very small, very fast Ragel/C based ERB parser
email: port001@gmail.com
executables: []

extensions: 
- ext/erbal/extconf.rb
extra_rdoc_files: []

files: 
- LICENSE
- CHANGELOG
- README.rdoc
- Rakefile
- lib/erbal
- lib/erbal/rails.rb
- spec/erbal_spec.rb
- spec/spec_helper.rb
- tasks/ext.rake
- tasks/gem.rake
- tasks/spec.rake
- benchmark/bench.rb
- benchmark/mem_leak_detect.rb
- benchmark/sample.erb
- ext/erbal/parser.h
- ext/erbal/erbal.c
- ext/erbal/parser.c
- ext/erbal/extconf.rb
- ext/erbal/parser.rl
has_rdoc: true
homepage: http://github.com/ileitch/erbal
licenses: []

post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      hash: 3
      segments: 
      - 0
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">"
    - !ruby/object:Gem::Version 
      hash: 25
      segments: 
      - 1
      - 3
      - 1
      version: 1.3.1
requirements: []

rubyforge_project: 
rubygems_version: 1.3.7
signing_key: 
specification_version: 3
summary: Very small, very fast Ragel/C based ERB parser
test_files: []

