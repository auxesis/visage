#!/usr/bin/env ruby

require 'colorize'

After('@daemon') do
  kill_lingering_daemons
end

class IO
  attr_accessor :command

  class << self
    alias :original_popen :popen

    def popen(*args)
      obj = original_popen(*args)
      obj.command = args
      obj
    end
  end
end

DAEMONS = []

def kill_lingering_daemons
  DAEMONS && DAEMONS.each do |daemon|
    begin
      puts "Killing process #{daemon.pid}".yellow if @debug
      Process.kill("KILL", daemon.pid)
    rescue Errno::ESRCH
      puts "Process #{daemon.pid} has already exited.".green
    end

    if @debug
      puts "Output from #{daemon.pid} #{daemon.command}\n".blue
      puts daemon.read + "\n"
    end
  end
  puts "Done killing processes".yellow if @debug
end

def spawn_daemon(command, opts={})
  puts "Running: #{command}".yellow if @debug
  daemon = IO.popen(command)
  DAEMONS << daemon
  sleep 2

  begin
    Process.kill(0, daemon.pid)
  rescue
    puts "Daemon #{$?.pid}: (#{command}) is stopped!".red
    puts "Output from #{daemon.pid} #{daemon.command}\n".red
    puts daemon.read_nonblock + "\n"
    puts "Aborting!"
    exit 3
  end
  daemon
end

# Testing daemons with Ruby backticks blocks indefinitely, because the
# backtick method waits for the program to exit. We use the select() system
# call to read from a pipe connected to a daemon, and return if no data is
# read within the specified timeout.
#
# http://weblog.jamisbuck.org/assets/2006/9/25/gdb.rb
def read_until_timeout(pipe, timeout=1, verbose=false)
  @output ||= []
  line    = ""
  while data = IO.select([pipe], nil, nil, timeout) do
    next if data.empty?
    char = pipe.read(1)
    break if char.nil?

    line << char
    if line[-1] == ?\n
      puts line if verbose
      @output << line
      line = ""
    end
  end

  @output
end

at_exit do
  kill_lingering_daemons
end
