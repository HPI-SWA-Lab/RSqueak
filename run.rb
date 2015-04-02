#!/usr/bin/env ruby

Image = "./Squeak4.6-vmmaker.bench.image"
BENCHMARKS = %w[mandala dsaGen shaLongString renderFont arrayFillArray arrayFillString]

cog = "squeak"
stack = "squeak x86_64"
rsqueak = "./rsqueak"

STDERR << "Usage
#{ARGV[0]} [CogVM default:#{cog}] [StackVM default:#{stack}] [RSqueak default:#{rsqueak}]
Press any key to start..."
STDIN.readchar


class VM < Struct.new(:path)
  def go
    BENCHMARKS.each do |b|
      run(b).sub(/.*#\(([0-9 ]+)\).*/m, '\\1').split[-21..-1].each do |value|
        puts "#{b};#{self.class.name};#{value}"
      end
    end
  end
end

class RSqueak < VM
  def run(benchmark)
    `#{path} #{benchmark == 'renderFont' ? '-P' : ''} -n 0 -m #{benchmark} #{Image}`
  end
end

class Stack < VM
  def ensured_startup_file(benchmark)
    File.open('run.st', 'w') do |f|
      f << "FileStream stdout nextPutAll: 0 #{benchmark}; cr. "\
      "Smalltalk snapshot: false andQuit: true."
    end
    'run.st'
  end

  def run(benchmark)
    `#{path} #{benchmark == 'renderFont' ? '' : '-headless'} #{Image} #{ensured_startup_file(benchmark)}`
  end
end

class Cog < Stack
end

VMS = [Cog.new(ARGV[0] || cog), Stack.new(ARGV[1] || stack), RSqueak.new(ARGV[2] || rsqueak)]

if ARGV[3] && ARGV[4]
  puts VMS.detect {|vm| vm.class.name =~ /#{ARGV[3]}/i}.
    run(ARGV[4]).sub(/.*#\(([\d ]+)\).*/m, '\\1')
  exit
end

VMS.each(&:go)
