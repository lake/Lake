require 'fileutils'
require 'rake/clean'
require 'rake'
require 'set'

__DIR__ = File.dirname( __FILE__)

require File.join(__DIR__, 'util')

if ENV['TEXINPUTS'].nil? or  ENV['TEXINPUTS'].empty?
    ENV['TEXINPUTS'] = "#{__DIR__}/packages/todos/::"
else
    ENV['TEXINPUTS'] = "#{__DIR__}/packages/todos/:" + ENV['TEXINPUTS']
end

TEX_FILES = FileList['*.tex']
MASTER_TEX_FILE_ROOTS = TEX_FILES.map do |f|
	f.chomp('.tex') unless `grep '^[:space:]*\\\\begin{document}' #{f}`.empty?
end.compact
error '
	No master (la)tex documents found:  no tex file contains \begin{document}.
'.strip.gsub(/^\t/,"") if MASTER_TEX_FILE_ROOTS.empty?

FIG_FILES = FileList['**/*.fig']
DIA_FILES = FileList['**/*.dia']

PDFTEX_T_FILES = FIG_FILES.map{|f| f.ext '.pdftex_t'}
NEATO_FILES = FileList['**/*.neato']
SECONDARY_PDF_FILES =
	NEATO_FILES.map{|f| f.ext 'pdf'} \
	+ DIA_FILES.map{|f| f.ext 'pdf'}

GNUPLOT_DATA_FILES = FileList['**/*.gdata']
GNUPLOT_FILES = FileList['**/*.gplot'].map{|f| dot(f).ext 'gnuplot-output'}

# Local rakefiles must define R_CREATE_GRAPHS, the path to a script that
# generates pdfs from rdata files, in order for the rdata rules to take effect.
R_CREATE_GRAPHS = nil unless self.class.const_defined? :R_CREATE_GRAPHS
R_DATA_FILES = FileList['**/*.rdata']
R_FILES = R_DATA_FILES.map{|f| dot(f).ext 'r-output'}

# Ignore figures in excluded directories.
EXCLUDED_FIGURES = nil unless self.class.const_defined? :EXCLUDED_FIGURES

FIGURES = (PDFTEX_T_FILES + SECONDARY_PDF_FILES + GNUPLOT_FILES + R_FILES).
	reject { |f| f =~ EXCLUDED_FIGURES }

# Don't trash figures that are checked in directly (i.e. that we don't have the
# source for)
CLOBBER_EXTS = %w(pdf eps ps png Rout RData)
PREGENERATED_RESOURCES = FileList[
	`git ls-files`.split.select {|f| CLOBBER_EXTS.include? f[/\.(.*?)$/, 1]} 
]

CLEAN.include(glob(%w(
	*.4ct *.4tc *.dvi *.idv *.lg *.lop *.lol *.toc *.out *.lof *.lot *.blg *.bbl
	*.lop *.loa *.tmp *.xref *.log *.aux *.vrb *.snm *.nav *.fls
)))
# Don't confuse .RData with the *.rdata files.  The former is detritus produced
# by the R binary.  
CLOBBER.include(
	glob(
		CLOBBER_EXTS.map{|ext| "**/*.#{ext}"}
	).reject{|f| f =~ EXCLUDED_FIGURES} - 
		glob('latex/**/*') + 
		FIGURES - 
		PREGENERATED_RESOURCES
)
MAX_LATEX_ITERATION = 10


task :default => :view

########################################################################
# Tasks to build the paper in various formats

desc "
	Builds the pdf output.  If the pdf is manually removed (i.e. not through the
	clean task), it may be necessary to call clobber before running this task.
".compact!
task :pdf  => MASTER_TEX_FILE_ROOTS.map{|master| master + '.pdf'}

# Rake does not currently support filering the dependency list of a rule to a
# subset of the files that share an extension.  Not all tex files are created
# equal; some tex files are "master" tex files that contain \begin{document} and
# input other tex files.  Here, we create a (task, file) pair for each master
# tex file in the project.
MASTER_TEX_FILE_ROOTS.each do |master|
	task master => master + '.pdf' # Don't make me type '.pdf'.

	# Touch the master if the aux files and fls files don't exist.  This will 
	# trigger a rebuild, which is probably needed, and generate these files.
	touch master.ext("tex") \
		unless File.exists? master.ext("fls") and File.exists? master.ext("aux")
	# The deps variable includes figures, sty, cls, and package files: anything
	# latex reads when building the pdf.
	deps, bibs, cites = get_deps_bibs_cites master.ext("tex")
	file master.ext('.pdf') => deps + bibs + FIGURES + PREGENERATED_RESOURCES do

		# Run latex.  This quits if there is an error.
		sh "pdflatex -recorder #{master}"

		# Once pdflatex has run, we can get set of bib_files and bib_cites for 
		# this file from the aux file, if it exists. 
		new_bibs, new_cites = traverse_aux_file_tree [master.ext("aux")]

		# Run bibtex if the set of bibs or cites has changed or if any bib file
		# has changed since the last bbl was built.
		run_bibtex = Set.new(new_cites) != Set.new(cites) \
			or Set.new(new_bibs) != Set.new(bibs)
		run_bibtex |= (
			(file master.ext("bbl") => new_bibs).needed?
		) unless new_bibs.empty?

		# Run bibtex, if a bib file OR the set of cites has changed.
		if run_bibtex
			# -min-crossrefs=100 essentially turns off cross referencing.  Not
			# sure why one wouldn't just take the default of 2.
			sh "bibtex -terse -min-crossrefs=100 #{master}"
			# Always run pdflatex at least once after a bibtex since 
			# we ran it for a reason.
			sh "pdflatex -recorder #{master}"
		end

		prev_missing_cites = []
		1.upto MAX_LATEX_ITERATION do 

			# Early escape when we know we can't resolve all citation references
			# because of missing citations.
			missing_cites = (
				`egrep -s "I didn't find a database entry for " *.blg`.
					collect {|l| l.split(' ').last }
			)
			unless missing_cites.empty?
				if missing_cites == prev_missing_cites \
						&& !prev_missing_cites.empty?

					break puts("
						Missing citations.  See warnings in pdflatex output.
					".gsub(/^\t*/, '').strip)	# drop formatting detritus
				else
					prev_missing_cites = missing_cites
				end
			end

			# We can stop when LaTeX is certain it has resolved all references.
			cross_ref_regex = "Rerun (LaTeX|to get cross-references right)"
			cit_regex = "LaTeX Warning: Citation .* on page .* undefined"
			regex = "((#{cross_ref_regex})|(#{cit_regex}))"
			break if `egrep -s '#{regex}' *.log`.empty?

			puts "Re-running latex to resolve references."
			sh "pdflatex -recorder #{master} > /dev/null"
		end
	end
end


desc <<-EOS
	Builds all of the figures
EOS
task :figures => FIGURES


rule '.pdftex_t' => ['.fig'] do |t|
	pdf_name = t.name.gsub /\.\w*$/, '.pdf'
	sh "fig2dev -Lpdftex -p0 #{t.source} > #{pdf_name}"
	sh "fig2dev -Lpdftex_t -p#{pdf_name} #{t.source} > #{t.name}"
end

rule '.pdf' => ['.eps'] do |t|
	sh "epstopdf #{t.source}"
end

rule '.eps' => ['.neato'] do |t|
	sh "neato -Gepsilon=.000000001 #{t.source} -Tps > #{t.name}"
end

rule '.eps' => ['.dot'] do |t|
	sh "dot #{t.source} -Tps > #{t.name}"
end

rule '.eps' => ['.dia'] do |t|
	sh "dia -t eps #{t.source}"
end

# Figures/.foo.gnuplot-output => Figures/foo.gplot
rule '.gnuplot-output' => proc{ |f|
	[undot(f).ext('gplot')] + GNUPLOT_DATA_FILES
} do |t|
	extension = gnuplot_target_extension(t.source)
	real_target_file = t.name.ext extension
	sh "gnuplot < #{t.source} > #{real_target_file}"
	FileUtils.touch t.name
end

rule '.r-output' => proc{|f|
	[ undot(f).ext('rdata'), R_CREATE_GRAPHS].compact
} do |t|
	dir = File.dirname(t.name)
	repo_root = File.expand_path( File.join( __DIR__, '..'))
	sh "cd #{dir}; #{repo_root}/#{R_CREATE_GRAPHS} #{repo_root}/#{t.source}"
	FileUtils.touch t.name
end


########################################################################
# Task to view the paper
task :view => :pdf do
	viewer MASTER_TEX_FILE_ROOTS.first.ext("pdf")
end
