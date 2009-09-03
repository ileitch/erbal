require 'erb'
require 'rubygems'
require 'erubis'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/erbal'

RUNS = 10000
REPEAT = 6
SRC = File.read('sample.erb')

class Benchmark
  def self.run(runs, repeat, warmup=false)
    puts "\n=> #{self.name.split('Benchmark').first}:" unless warmup
    times = []
    repeat.times do |i|
      total = 0
      runs.times do
        start = Time.now
        parse
        total += Time.now-start
      end
      times << total
      puts " #{i+1}) #{sprintf("%.2f", total)}" unless warmup
    end
    unless warmup
      puts "=> Average: #{sprintf("%.2f", times.inject(0){|c, n| c += n} / times.size)}"
    end
  end
end

class ErbalBenchmark < Benchmark
  def self.parse
    Erbal.new(SRC, "@output").parse
  end
end

class ErbBenchmark < Benchmark
  def self.parse
    ::ERB.new(SRC, nil, '-', '@output')
  end
end

class ErubisBenchmark < Benchmark
  def self.parse
    Erubis::FastEruby.new.convert(SRC)
  end
end

parsers = [ErbBenchmark, ErbalBenchmark, ErubisBenchmark]

$stdout.write("=> Warming up.... ")
$stdout.flush
parsers.each do |b|
  b.run(RUNS, 1, true)
end
puts "done"
puts "=> #{RUNS} runs repeated #{REPEAT} times"
parsers.map {|b| b.run(RUNS, REPEAT)}