require 'fileutils'
require 'rake/clean'

__DIR__ = File.dirname( __FILE__)

require File.join(__DIR__, 'util')


BIB_FILES = FileList['*.bib', 'Bib/**/*.bib']
# a & a removes dupes, while preserving order
BIB_INPUTS = (a = BIB_FILES.map{|f| File.dirname(f)} + 
		(ENV['BIBINPUTS'] ||'').split(':'); a & a)
ENV['BIBINPUTS'] = BIB_INPUTS.join(':') unless BIB_INPUTS.empty?

TEX_FILES = FileList['*.tex']
FIG_FILES = FileList['**/*.fig']
DIA_FILES = FileList['**/*.dia']

PDFTEX_T_FILES = FIG_FILES.map{|f| f.gsub /\.\w*$/, '.pdftex_t'}
NEATO_FILES = FileList['**/*.neato']
SECONDARY_PDF_FILES =
	NEATO_FILES.map{|f| f.gsub /\.\w*$/, '.pdf'} \
	+ DIA_FILES.map{|f| f.gsub /\.\w*$/, '.pdf'}

GNUPLOT_DATA_FILES = FileList['**/*.gdata']
GNUPLOT_FILES = FileList['**/*.gplot'].map do |f| 
	replace_extension(dot(f), 'gnuplot-output')
end

# Local rakefiles must define R_CREATE_GRAPHS, the path to a script that
# generates pdfs from rdata files, in order for the rdata rules to take effect.
R_CREATE_GRAPHS = nil unless self.class.const_defined? :R_CREATE_GRAPHS
R_DATA_FILES = FileList['**/*.rdata']
R_FILES = R_DATA_FILES.map do |f| 
	replace_extension(dot(f), 'r-output')
end

# Ignore figures in excluded directories.
EXCLUDED_FIGURES = nil unless self.class.const_defined? :EXCLUDED_FIGURES

FIGURES = (PDFTEX_T_FILES + SECONDARY_PDF_FILES + GNUPLOT_FILES + R_FILES).
	reject { |f| f =~ EXCLUDED_FIGURES }

# Don't trash figures that are checked in directly (i.e. that we don't have the
# source for)
PREGENERATED_RESOURCES = 
	FileList[] unless self.class.const_defined? :PREGENERATED_RESOURCES
# We don't generate any pngs at the moment, we know they must be pregenerated
PREGENERATED_RESOURCES.include FileList['**/*.png']


CLEAN.include(glob(%w(
	*.4ct *.4tc *.dvi *.idv *.lg *.lop *.lol *.toc *.out *.lof *.lot *.blg *.bbl
	*.lop *.loa *.tmp *.xref *.log *.aux
)))
# Don't confuse .RData with the *.rdata files.  The former is detritus produced
# by the R binary.  
CLOBBER.include(
	glob(
		%w(*.pdf) + 
		%w(*.pdf *.eps *.Rout .RData *.png).map{|pat| "**/#{pat}"}
	).reject{|f| f =~ EXCLUDED_FIGURES} - 
		glob('latex/**/*') + 
		FIGURES - 
		PREGENERATED_RESOURCES
)
MAX_LATEX_ITERATION = 10

$paper ||= 'paper'


task :default => :view

########################################################################
# Tasks to build the paper in various formats

desc "
	Builds the pdf output.  If the pdf is manually removed (i.e. not through the
	clean task), it may be necessary to call cleaner before running this task.
".compact!
task :pdf  => "#{$paper}.pdf"
file "#{$paper}.pdf" => TEX_FILES + FIGURES do

	# Quit if latex reports an error
	exit 1 unless sh "pdflatex #{$paper}.tex"

	unless BIB_INPUTS.nil?

		# -min-crossrefs=100 essentially turns off cross referencing.
		# Not sure why one wouldn't just take the default of 2.
		sh "bibtex -terse -min-crossrefs=100 #{$paper}"
	end

	1.upto MAX_LATEX_ITERATION do 

		# Early escape when we know we can't resolve all citation references
		# because of missing citations.
		unless `egrep -s "I didn't find a database entry for " *.blg`.empty?
			break puts("Missing citations.  See warnings in pdflatex output.")
		end

		# We can stop when LaTeX is certain it has resolved all references.
		cross_ref_regex = "Rerun (LaTeX|to get cross-references right)"
		cit_regex = "LaTeX Warning: Citation .* on page .* undefined"
		regex = "((#{cross_ref_regex})|(#{cit_regex}))"
		break if `egrep -s '#{regex}' *.log`.empty?

		puts "Re-running latex to resolve references."
		exit 1 unless sh "pdflatex #{$paper}.tex > /dev/null"
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
	[ replace_extension(undot(f), 'gplot')] + GNUPLOT_DATA_FILES
} do |t|
	extension = gnuplot_target_extension( t.source)
	real_target_file = replace_extension(t.name, extension)
	sh "gnuplot < #{t.source} > #{real_target_file}"
	FileUtils.touch t.name
end

rule '.r-output' => proc{|f|
	[ replace_extension(undot(f), 'rdata'), R_CREATE_GRAPHS].compact
} do |t|
	dir = File.dirname(t.name)
	repo_root = File.expand_path( File.join( __DIR__, '..'))
	sh "cd #{dir}; #{repo_root}/#{R_CREATE_GRAPHS} #{repo_root}/#{t.source}"
	FileUtils.touch t.name
end


########################################################################
# Tasks to view the paper

task :view => :pdf do
	if `pgrep -f "^xpdf -remote #{$paper}"`.strip.empty?
		# not already viewing, open a new xpdf
		sh "xpdf -remote #{$paper} #{$paper}.pdf &"
	else
		# already viewing, reload instead
		sh "xpdf -remote #{$paper} -reload -raise"
	end
end
