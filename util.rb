require 'fileutils'
require 'rake'

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

# This parses an aux file and returns its list of bib files and citations.
def parse_aux_file aux_file
	bibs, cites = [], [] 
	File.readlines(aux_file).each do |line|
		cites << line[/\{(.*)\}/, 1] if line =~ /^\\citation/
		bibs += line[/^\\bibdata\{(.*)\}/, 1].split(",").map do |b|
			b.strip.ext "bib"
		end if line =~ /^\\bibdata/
	end
	return [bibs, cites]
end

# Determine master's exact dependencies from its fls and aux files.
def get_deps_bibs_cites master

	# The variable deps will include packages, tex files, figures, anything
	# that is read by latex to build the pdf.
	deps, bibs, cites = [master.ext("tex")], [], []

	# Parse master.fls if it exists.
	if File.exists? master.ext("fls")
		# Latex both inputs and outputs aux files, so if master.pdf depended on
		# master.aux, then each build would output a new master.aux, which
		# would, in turn, trigger a new build, ad infinitum.  To prevent this,
		# we separate latex' output files from its input files. 
		outputs = `grep OUTPUT #{master.ext("fls")}`.split("\n").map do |line|
			line.split(" ")[1]
		end
		deps += `grep INPUT #{master.ext("fls")}`.split("\n").map do |line| 
			line.split(" ")[1]
		end.reject{|f| outputs.include? f}
	end

	# If master.aux, exists parse it to determine its bib dependencies.
	if File.exists? master.ext("aux")
		bibs, cites = parse_aux_file master.ext("aux")
	end

	return [deps, bibs, cites].map{|x| x.uniq}
end

# The following code block defines a default pdf viewer.  The viewer method
# may be overridden in a local Rakefile, created by copying Rakefile.local.

# If xpdf is on the path, use it.
if not `which xpdf`.strip.empty?
	def viewer pdf
		if `pgrep -f "^xpdf -remote #{pdf}"`.strip.empty?
		# not already viewing, open a new xpdf
			sh "xpdf -remote #{pdf} #{pdf} &"
		else
		# already viewing, reload instead
			sh "xpdf -remote #{pdf} -reload -raise"
		end
	end

# If skim is on the system, use it. /Applications is standard like /usr/bin.
elsif File.exists? "/Applications/Skim.app"
	def viewer pdf
		sh "#{File.dirname(File.expand_path(__FILE__))}/skimview #{pdf}" 
	end

# If this is OS X, then open with the "open" command.
elsif `uname` == "Darwin" # "Darwin" == OS X
	def viewer pdf
		sh "open #{pdf}"
	end

# If none of these were set then let the user know they should define one.
else 
	def viewer(pdf) 
		puts  "Unable to view #{pdf}:  No pdf viewer found."
		print "Define the viewer method in your local Rakefile, "
		puts  "which you copy from Rakefile.local."
	end

end
