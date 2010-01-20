
Lake - a build system for LaTeX documents

Authors:		Earl T. Barr
				Chris Bird
				David J. Hamilton


What lake is
============

Lake is a build system for LaTeX documents.

Lake does not ambitiously seek to parse and build an arbitrary latex project:
You must follow its layout and suffix conventions, as documented below.
Notably, lake uses pdflatex so you cannot use it in conjunction with LaTeX
source that includes postscript diagrams.

License
=======

Lake is licensed under the terms of the GNU Lesser General Public
License (LGPL). Please refer to the file named 'COPYING' that came with
this distribution for details.


Dependencies
============

Lake is a Rakefile and a supporting Ruby library.  As such, it requires ruby
and rake.  It has been built and tested against texlive.


Installation
============
To use lake for a latex project, clone the repository and copy the local
rakefile to the root of your project directory.

	git clone git@github.com:hjdivad/lake.git
	cp lake/Rakefile.local Rakefile

If you do this, it is probably best to add `/lake` to your `.gitignore`.

Alternatively you can add lake as a submodule.

	git submodule add git@github.com:hjdivad/lake.git
	cp lake/Rakefile.local Rakefile


Usage
=====

You can execute `Rake -T` to see a list of tasks.  The most common task is `view`,
which builds the pdf for the first master tex file and launches xpdf to view the
file.  Subsequently running `rake view` will reload, rather than relaunch, xpdf.

Suffixes are the key to using Lake.  If you follow Lake's conventions, it will
discover and build your content, such as bibliography files and diagrams, before
calling pdflatex.

Any project-specific configuration (e.g. changing the default values for
constants such as `EXCLUDED_FIGURES` or `R_CREATE_GRAPHS`) is done in the LaTeX
project's local `Rakefile`, copied from lake's `Rakefile.local` into the root of
the project repository.  Check this file for configuration options.

We designate a tex file that contains \begin{document} as a master tex file.
Currently, our support for more than one master tex file in the root directory
of the latex project is not well-tested.

Graphics
--------

Lake supports a number of ways to build figures before running `pdflatex`.
Because we assume `pdflatex`, no postscript figures are supported.

To include PDF figures, the following tools can be used, with the expected
extensions listed:

* graphviz -- .neato, .dot
* dia -- .dia

The drawing tool xfig can pass strings through the latex interpreter.  Lake
supports building figures with such strings automatically.  Lake produces
`diagram.pdftex_t` from `diagram.fig`, so in your tex source, you include
`diagram.pdftex_t`.

Gnuplot can generate either tex, png, jpg or gif files.  If you include a file
`diagram.gplot` that contains the line `set terminal latex`, then you include
the diagram in your tex files with `\input{diagram}`.  Similarly, if
`diagram.gplot` contains the line `set terminal png`, your tex file should use
`\includegraphics{diagram}`.

R is a powerful statistical package with many features.  Lake ignores most of
those features and treats R solely as a producer of graphical output.  Lake runs
the script identified by `R_CREATE_GRAPHS`, which is set in the project's local
Rakefile.

Whenever a file ending in `.rdata` is changed, Lake will run the script with one
argument, the name of the file.  Lake can handle any of R's graphical outputs
other than postscript.


Limitations and Assumptions
===========================

Defintion:  A master tex file is a (la)tex source file that contains
`\begin{document}` (normally, such a file will also contain `\end{document}`).

We assume there is a 1-1 mapping between master tex files and output pdfs.

We assume master tex files in the root directory of the repository.

We assume that a collection of tex files that produce a document contains a
single `\begin{document}` command and, if collection has a bibliography, that the
collection also contains a single `\bibliography` command.  Further, both the
`\begin{document}` and bibliography commands must start their line, although we do
tolerate prefixed whitespace.  In short, we cannot compile most latex documents
about writing latex documents.

Currently, support for more than one master tex file in the root directory of
the latex project is not well-tested.


Contributing
============

Patches, bug reports and all feedback gratefully accepted at lake@hjdivad.com.

