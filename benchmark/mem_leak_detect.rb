#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__)) + '/../lib/erbal'

SRC = File.read(File.expand_path(File.dirname(__FILE__)) + '/sample.erb')
GC.enable_stats

i = 0
while true do
  i += 1
  5000.times do
    e = Erbal.new(SRC)
    e.parse
  end
  GC.start
  rss = `ps -orss #{Process.pid}`.split("\n").last.strip
  puts
  puts "Run #{i}"
  puts "RSS #{rss}"
  puts "Live objects #{ObjectSpace.live_objects}"
  GC.dump
end