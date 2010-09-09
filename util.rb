require 'fileutils'
require 'rake'

def in_test?
	ENV.has_key? 'test'
end

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
	pattern_array = [pattern_array] unless pattern_array.is_a? Array
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

# This method parses an aux file and returns its list of bib files, citations,
# and included tex files.
def parse_aux_file aux_file
	bibs, cites, includes = [], [], []
	File.readlines(aux_file).each do |line|
		bibs += line[/^\\bibdata\{(.*)\}/, 1].split(",").map do |b|
			b.strip.ext "bib"
		end if line =~ /^\\bibdata/
		cites << line[/\{(.*)\}/, 1] if line =~ /^\\citation/
		includes << line[/\{(.*)\}/, 1] if line =~ /^\\@input/
	end if File.exists?(aux_file)
	return [bibs, cites, includes]
end

# This method traverses a tree of aux files, and parses each.  Its
# implementation makes two assumptions:  1) there is only one bibdata per master
# tex file; that is, only one \bibliography;  and master tex files that share a
# directory do not share an aux file that contains bibdata.
#
# This returns a list of bibs, and cites
# we use sets internally but return lists because rake doesn't like sets
def traverse_aux_file_tree(includes, bibs = [], cites = [])

	return [bibs, cites] if includes.empty?

    includes.each do |include|
        new_bibs, new_cites, new_includes = parse_aux_file include
        bibs |= new_bibs
        cites |= new_cites
        traverse_aux_file_tree(new_includes, bibs, cites)
    end

	return [bibs, cites]
end

# get a list of all of the bib keys in a list of bib files
def get_bib_keys bibs
    keys = []
    bibs.each do |bib|
        File.read(bib).scan(/@\s*\w+\s*\{\s*([^,\s]+)\s*,/) { |x| keys << x[0] }
    end
    return keys.uniq
end

# get a list of all bib entries in a list of .bbl files
def get_bbl_keys bbls
    keys = []
    bbls.select{ |x| File.exists? x}.each do |bbl|
        File.read(bbl).scan(/\\bibitem\{([^}]+)\}/) { |x| keys << x[0] }
    end
    return keys.uniq
end

# Determine master's exact dependencies from its fls and aux files.
def get_deps_bibs_cites master

	unless File.exists? master.ext("fls") and File.exists? master.ext("aux")
		raise "Missing #{master.ext("fls")} and #{master.ext("aux")}" 
	end

	# The variable deps includes packages, tex files, and figures; anything 
	# that latex reads to build the pdf.
	deps, bibs, cites = [master.ext("tex")], [], []

	# Parse master.fls.  Latex both inputs and outputs aux files, so if
	# master.pdf depended on master.aux, then each build would output a new
	# master.aux, which would, in turn, trigger a new build, ad infinitum.  To
	# prevent this, we separate latex' output files from its input files. 
	outputs = `grep OUTPUT #{master.ext("fls")}`.split("\n").map do |line|
		line.split(" ", 2)[1]
	end
	deps += `grep INPUT #{master.ext("fls")}`.split("\n").map do |line| 
		line.split(" ", 2)[1]
	end.reject{|f| outputs.include? f}

	# Parse master.aux to determine its bib dependencies.
	bibs, cites = traverse_aux_file_tree [master.ext("aux")]

	raise "There are cites, but no bib files." if bibs.empty? and !cites.empty?

	return [deps, bibs, cites].map{|x| x.uniq}
end

def run_bibtex? bibs, cites, master

	# If there is no bibliography or no cites, don't run bibtex.
	return false if bibs.nil? or bibs.empty? or cites.nil? or cites.empty?

	# We want running bibtex to essentially be stateless. We run bibtex iff:
	#   a) any .bib file used by master is newer than master.bbl (or 
	#      there is a .bib and master.bbl doesn't exist)
	#   b) there is a cite in master.aux that is not in master.bbl but 
	#      *is* in a bib file included by master.aux
	bib_keys = get_bib_keys bibs
	bbl_keys = get_bbl_keys [master.ext("bbl")]

	# Run if cite added to a tex file.
	run_bibtex = !((cites - bbl_keys) & bib_keys).empty?

	# Run bibtex if the set of bibs or cites has changed or if any bib file
	# has changed since the last bbl was built.
	run_bibtex |= (file master.ext("bbl") => bibs).needed?

	run_bibtex
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
