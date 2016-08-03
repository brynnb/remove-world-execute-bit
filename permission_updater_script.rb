# This is a script to use the PermissionUpdater class and accept options to pass along.
#
require 'optparse'
require './permission_updater'

options = {}

parser = OptionParser.new do|opts|
  opts.banner = "Usage: permission_updater_script.rb [options]"
  opts.on('-r', '--recursive', 'Update in subdirectories recursively') do |recursive|
    options[:recursive] = recursive;
  end

  opts.on('-a', '--all', 'Also update hidden dot files (e.g. `.gitignore`)') do |all|
    options[:all] = true;
  end

  opts.on('-v', '--verbose', 'List updated files during processing') do |verbose|
    options[:verbose] = true;
  end

  opts.on('-p', '--path [path]', 'Directory to process (defaults to current)') do |path|
    options[:path] = path;
  end

  opts.on('-m', '--max_depth [integer]', 'Maximum depth of subdirectories to process (with level 1 being given path)') do |max_depth|
    options[:max_depth] = Integer(max_depth);
  end

  opts.on('-h', '--help', 'Displays this help message') do
    puts opts
    exit
  end
end

parser.parse!

updater = PermissionUpdater.new(options)

updater.update_permissions