require 'fileutils'


BIB_FILES = FileList['*.bib', 'Bib/**/*.bib']
TEX_FILES = FileList['*.tex']
FIG_FILES = FileList['Figures/**/*.fig']
DIA_FILES = FileList['Figures/**/*.dia']

PDFTEX_T_FILES = FIG_FILES.map{|f| f.gsub /\.\w*$/, '.pdftex_t'}
NEATO_FILES = FileList['Figures/**/*.neato']
SECONDARY_PDF_FILES = NEATO_FILES.map{|f| f.gsub /\.\w*$/, '.pdf'}
PNG_FILES = DIA_FILES.map{|f| f.gsub /\.\w*$/, '.png'}

FIGURES = PDFTEX_T_FILES + SECONDARY_PDF_FILES + PNG_FILES

# Don't trash figures that are checked in directly (i.e. that we don't have the
# source for)
PREGENERATED_RESOURCES = FileList['Figures/**/*.png'] - PNG_FILES


MAX_LATEX_ITERATION = 10



$paper ||= 'paper'

BBL_FILE  = FileList[$paper + ".bbl"]


task :default => :view

########################################################################
# Tasks to build the paper in various formats

desc <<-EOS
	Builds the pdf output
EOS
task :pdf  => "#{$paper}.pdf"
file "#{$paper}.pdf" => TEX_FILES + BBL_FILE + FIGURES do
	1.upto MAX_LATEX_ITERATION do 
		# Quit if latex reports an error
		exit 1 unless sh "pdflatex #{$paper}.tex"

		# We can stop when LaTeX is certain it has resolved all citation
		# references.
		break if 
			`egrep -s 'Rerun (LaTeX|to get cross-references right)' *.log`.empty?
	end
end

desc <<-EOS
	Creates #{$paper}.bbl if a bib file exists
EOS
file "#{$paper}.bbl" => BIB_FILES do |t|
	unless BIB_FILES.nil?
		bib_inputs =
			BIB_FILES.map{|f| File.dirname(f)} + ENV['BIBINPUTS'].split(':')

		# remove dupes, preserving order
		bib_inputs = bib_inputs & bib_inputs

		ENV['BIBINPUTS'] = bib_inputs.join(':')

		sh "pdflatex #{$paper}.tex" unless File.exists?($paper + ".aux")

		# -min-crossrefs=100 essentially turns off cross referencing.
		# Not sure why one wouldn't just take the default of 2.
		sh "bibtex -min-crossrefs=100 #{File.basename(t.name, '.bbl')}"
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

rule '.eps' => ['.neato'] do |t|
	sh "neato -Gepsilon=.000000001 #{t.source} -Tps > #{t.name}"
end

rule '.eps' => ['.dot'] do |t|
	sh "dot #{t.source} -Tps > #{t.name}"
end


rule '.pdf' => ['.eps'] do |t|
	sh "epstopdf #{t.source}"
end

rule '.png' => ['.dia'] do |t|
	sh "dia -t png #{t.source}"
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


########################################################################
# Tasks modify the working directory

CLEAN_PATTERN = %w(*.4ct *.4tc *.dvi *.idv *.lg *.lop *.lol
				*.toc *.out *.lof *.lot *.blg *.bbl *.lop *.loa
				*.tmp *.xref *.log *.aux).map {|pat| "{.,html}/#{pat}"}
CLEANER_PATTERN = %w(*.pdf *.css *.html).map {|pat| "{.,html}/#{pat}"}
CLEANEST_PATTERN = %w(*.eps *.pdftex_t *.pdf 
					*.png).map {|pat| "Figures/**/#{pat}"}

desc <<-EOS
	Clean LaTeX ancillary files
EOS
task :clean do
	glob( CLEAN_PATTERN).each{|file| FileUtils.rm file}
end

desc <<-EOS
	Clean output files (implies clean)
EOS
task :cleaner => :clean do
	glob( CLEANER_PATTERN).each{|file| FileUtils.rm file}
end

desc <<-EOS
	Clean all generated files, including Figures (implies cleaner)
EOS
task :cleanest => :cleaner do |t|
	glob( CLEANEST_PATTERN).
		reject{ |file| PREGENERATED_RESOURCES.include? file}.
		each{ |file| FileUtils.rm file}
end

# Implements the array usage of Dir::glob for older rubys (e.g. 1.8.5)
def glob(pattern_array)
	files = pattern_array.map{|s| Dir.glob(s)}.flatten
	files & files
end

