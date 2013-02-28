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

at_exit do
  kill_lingering_daemons
end
