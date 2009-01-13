require 'fileutils'

def error ( message) 
	puts message
	exit 1
end

def dir_and_file_name( path)
	dir = File.dirname( path)
	file = path[dir.size+1..-1]

	[dir, file]
end

def dot(path)
	dir, file = dir_and_file_name(path)
	"#{dir}/#{'.' unless file =~ /^\./}#{file}"
end

def undot(path)
	dir, file = dir_and_file_name(path)
	"#{dir}/#{file.gsub /^\./, ''}"
end

def replace_extension(path, extension)
	dir, file = dir_and_file_name(path)
	"#{dir}/#{file.gsub(/\.[\w-]*$/,'')}.#{extension}"
end

# Implements the array usage of Dir::glob for older rubys (e.g. 1.8.5)
def glob(pattern_array)
	files = pattern_array.map{|s| Dir.glob(s)}.flatten
	files & files
end

# Reads a .gplot file and returns the expected file extension for the file type
# (e.g. tex, png).  Raises an Exception if the expected file type could not be
# determined.
def gnuplot_target_extension( gplot_path)
	File.open( gplot_path) do |file|
		while line = file.gets
			next unless line =~ /set terminal (.*)$/

			case $1.strip
			when 'latex'
				return 'tex'
			when /(png|jpg|gif)/
				return $1
			else
				raise "Unknown terminal type #{$1} in gplot file #{gplot_path}"
			end
		end
	end
	raise "Unable to determine extension for gplot file #{gplot_path}.  " +
		"No line that looked like 'set terminal FOO' could be found"
end



module StringUtils
	def compact!
		self.strip!
		self.gsub! /^\s+/, ' '
		self.gsub! /\n/, ''
		self
	end
end
String.class_eval{ include StringUtils}
