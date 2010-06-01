#!/usr/bin/env ruby

exit if ARGV.size == 0

require 'stringio'
def getio; StringIO.new `top -l 3 -stats pid,command,cpu,time,ports -n 10`; end
io = getio

class Object
  def identity
    self
  end
end

class Array
  def from_match(match, transformation = :identity)
    hash = {}
    transformation = [transformation].flatten * self.size unless transformation.is_a? Array
    self.size.times do |i|
      hash[self[i]] = match[i + 1].send(transformation[i])
    end
    hash
  end
end

samples = []
sample = nil

while !io.eof? and line = io.readline
	if line =~ /^Processes\:\s+(\d+) total, (\d+) running.*$/
	  #puts line
	  samples << sample if sample
	  sample = {}
	  sample[:processes] = [:total, :running].from_match($~, :to_i)
	elsif line =~ /^Load Avg\: ([0-9.]+), ([0-9.]+), ([0-9.]+)\s*$/
	  #puts line
	  sample[:load] = [:now, :min5, :min10].from_match($~, :to_f)
	elsif line =~ /^CPU usage\: ([0-9.]+)\% user, ([0-9.]+)\% sys, ([0-9.]+)\% idle\s*$/
	  sample[:cpu] = [:user, :sys, :idel].from_match($~, :to_f)
	end
end

samples << sample if sample

# Using accumulative, so no averaging.  Just use the last

result = samples.last

if ARGV[0] == 'config'
  puts "multigraph Load Average"
  puts "graph_title Load Average"
  puts "graph_category system"
  puts "graph_vlabel load"
  puts "load.label load"
  puts "load.warning 10"
  puts "load.critical 120"
  puts "load.value #{result[:load][:min5]}"
  puts "load.info Average load for the last 5 minutes"
  
  puts "multigraph Process Count"
  puts "graph_title Process Count"
  puts "graph_category system"
  puts "graph_vlabel p_count"
  puts "p_count.label process count"
  puts "p_count.value #{result[:processes][:total]}"
  puts "p_count Total number or processes"

end

