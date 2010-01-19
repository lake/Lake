#!/usr/bin/env ruby

# This class tracks which files in a directory have changed
# pass the path to the directory to the constructor.  Then,
# each time whatChanged? is called, it will list the files
# that have been modified (or added, but not deleted) since
# the previous call
class DirMonitor
	attr_reader :dir
	def initialize(dir)
		@dir = dir
		@mTimes = {}
		# prime @mTimes with the known modification times
		Dir.foreach(@dir) { |file| path = File.join(@dir, file)
			@mTimes[path] = File.mtime(path)
		}
	end

	# which files have changed since we last checked
	def whatChanged?
		changed = []
		Dir.foreach(@dir) do |file|
			path = File.join(@dir, file)
			#file can actually disappear midstream...
			if File.exists? path
				mtime = File.mtime(path)
				changed << path if !@mTimes.key?(path) || @mTimes[path] < File.mtime(path)
				#update with the latest mod time
				@mTimes[path] = mtime
			end
		end
		return changed
	end
end

# notifier can be any program that outputs something
# to std out when any of the directories on the command
# line have changed.  Note that programs may buffer to
# std out if it is not to a tty.  Thus, make sure you
# fflush stdout or you may think there is a bug in this code

$NOTIFIER = File.join(File.dirname(__FILE__), "notifier")


def main
	if !File.exists? $NOTIFIER
		$stderr.puts "The binary lake/continous/notifier has not been built"
		$stderr.puts "Please build it by executing rake in lake/continuous"
		exit 0
	end
	dirs = ["."]
	dirMonitor = DirMonitor.new(dirs[0])

	notifyOut = IO.popen("#{$NOTIFIER} #{dirs.join ' '}")
	puts "#{$NOTIFIER} is now running"
	while true
		fds = IO.select([notifyOut], [], [])
		if fds
			fds[0].each { |fd|
				s = fd.readline.strip
				#probably should do something here
			}
			changed = dirMonitor.whatChanged?
			puts "changed " + changed.inspect if !changed.empty?
			if changed.any? { |x| x =~ /\.(bib|tex)$/ }
				puts "Detected changes in: #{changed.join ' '}"
				puts "rebuilding now"
				system("rake")
			end
		end
	end
end

main if __FILE__ == $0


