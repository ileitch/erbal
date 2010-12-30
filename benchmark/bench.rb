#!/usr/bin/env ruby

require 'erb'
require 'rubygems'
require 'erubis'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/erbal'

RUNS = 3000
REPEAT = 6
SRC = File.read(File.expand_path(File.dirname(__FILE__)) + '/sample.erb')

class Benchmark
  def self.run(what, runs, repeat, warmup=false)
    puts "\n=> #{canonical_name}" unless warmup
    times = []
    repeat.times do |i|
      total = 0
      runs.times do |n|
        start = Time.now
        send(what)
        total += Time.now-start
      end
      times << total
      unless warmup
        $stdout.write(sprintf("%.3f ", total))
        $stdout.flush
      end
    end
    unless warmup
      puts "\n=> Average: #{sprintf("%.3f", times.inject(0){|c, n| c += n} / times.size)}"
    end
  end

  def self.prep_for_eval
    @src = parse
  end

  def self.eval_src
    eval(@src)
  end

  def self.canonical_name
    name.split('Benchmark').first
  end
end

class ErbalBenchmark < Benchmark
  def self.parse
    Erbal.new(SRC).parse
  end
end

class ErbBenchmark < Benchmark
  def self.parse
    ::ERB.new(SRC, nil, '-', '@output')
  end

  def self.prep_for_eval
    @src = parse.src
  end
end

class ErubisFastBenchmark < Benchmark
  def self.parse
    Erubis::FastEruby.new.convert(SRC)
  end

  def self.canonical_name
    "Erubis (using FastEruby engine)"
  end
end

class ErubisBenchmark < Benchmark
  def self.parse
    Erubis::Eruby.new.convert(SRC)
  end

  def self.canonical_name
    "Erubis (using default Eruby engine)"
  end
end

parsers = [ErbBenchmark, ErubisFastBenchmark, ErubisBenchmark, ErbalBenchmark]

$stdout.write("=> Warming up.... ")
$stdout.flush
parsers.each do |b|
  b.run(:parse, 10, 2, true)
end
puts "done"
puts
puts "=> Parsing Benchmark"
parsers.map {|b| b.run(:parse, RUNS, REPEAT)}

puts
puts "=> eval() Benchmark"
parsers.map {|b| b.prep_for_eval}
parsers.map {|b| b.run(:eval_src, RUNS, REPEAT)}
