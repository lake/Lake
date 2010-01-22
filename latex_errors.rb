# Each latex error pairs a regex that describes a latex error with a window of
# lines following the error, either in terms of a delimiting regex or a count of
# lines.
# A list of common errors and their causes (which this list is partially based
# on) can be found at:
#   http://www.cs.utexas.edu/~witchel/errorclasses.html

latex_errors_abbrv = [
	# matches when an argument to a latex function has extra }'s.  
	# Spews lots of text (11 lines) see extra_brace.log in testing module.
	[/^.*:[0-9]+: Argument of.*has an extra \}/, /it will go away/],
	# Occurs when missing a \begin{table} statement
	# see hyphenation.log
	[/Too many \}'s/, 5],
	# Example: Package Option Conflict
	[/: Missing number, treated as zero/, /TeXbook/],
	# Improper parameter to \hyphenation
	# see hyphenation.log
	[/^.*:[0-9]+:.*Improper.*flushed/, 7],
	# Previous errors so bad that pdflatex won't produce anything
	[/^.*==>\sfatal.*/i, 2],
	# Include 7 lines by default.
	[/^.*:[0-9]+:/, 7]
]

$latex_errors = latex_errors_abbrv.map do |entry|
	{:regex => entry[0], 
		entry[1].class == Fixnum ? :lines : :delimiter => entry[1]}
end

def parse_log text
	errors = []
	# Match the error message and the two succeeding lines, which contain 
	# the context of the error and allow us to determine the column number.
	lines = text.split "\n"
	i = 0
	while i < lines.length
		record = $latex_errors.find { |r| lines[i] =~ r[:regex] }
		if not record
			i += 1
			next
		end
		if record.has_key? :lines
			errors << lines[i,record[:lines]].join("\n")
			i += record[:lines]
		elsif record.has_key? :delimiter
			error = ""
			while lines[i] !~ record[:delimiter]
				error += lines[i] + "\n"
				i += 1
			end
			errors << error + lines[i]
			i +=1
		else
			raise "Error record has neither :lines nor :delimiter!"
		end
	end
	return errors
end

# This line is faciliates testing and creates output only
# if this file is run as a script.
puts parse_log(File.read(ARGV[0])).join("\n*** ERROR ***\n") if $0 == __FILE__
