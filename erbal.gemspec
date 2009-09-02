--- !ruby/object:Gem::Specification 
name: erbal
version: !ruby/object:Gem::Version 
  version: 0.0.1
platform: ruby
authors: 
- Ian Leitch
autorequire: 
bindir: bin
cert_chain: []

date: 2009-09-02 00:00:00 -04:00
default_executable: 
dependencies: []

description: Very small, very fast Ragel based ERB parser
email: ian.leitch@systino.net
executables: []

extensions: 
- ext/erbal/extconf.rb
extra_rdoc_files: []

files: 
- COPYING
- CHANGELOG
- README
- Rakefile
- lib/erbal
- lib/erbal/rails.rb
- tasks/ext.rake
- tasks/gem.rake
- tasks/spec.rake
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
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: 
rubygems_version: 1.3.4
signing_key: 
specification_version: 3
summary: Very small, very fast Ragel based ERB parser
test_files: []

