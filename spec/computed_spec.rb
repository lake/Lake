require 'fileutils'
require 'yaml'

require 'rubygems'
require 'active_support'
require 'spec'

require 'spec_util'


# Each test consists of a directory with a .test.yaml specification that
# describes a set of tasks to be run and:
#
# 	1.	Environment variables that should be set.
# 	2.	Either:
# 		a. Expected files to be produced.
# 		b. Expected output (e.g. error message).
# 		c. Expected exit code (defaults to 0, i.e. success).
#
# An example such file:
#
#	---
#	 rake foo.pdf:
#	  :exit_code:		1
#	  :output:			a substring to match
#	  :produced_files:
#	  - foo.pdf
#
# The rest of the subtree is considered the starting point: the place where lake
# will run.
describe "auto test directory" do

	# ∀ dir with file .test ϵ ./**
	# 	create a test that
	# 		copies the subtree into ./tmp
	# 		with pwd of ./tmp, runs each task and compares output
	Dir["auto/**/.test.yaml"].each do |test_file|
		test_dir = File.expand_path( File.dirname( test_file ))

		describe File.basename( test_dir ) do
			YAML::load_file( test_file ).each_pair do |test, params|
				params.reverse_merge!({
					# All tasks are assumed to exit successfully, unless an
					# explicit exit code is given.
					:exit_code => 0,
				})
				describe "running '#{test}'" do
					output = nil
					params.each_pair do |key, value|
						it( "should " + SpecUtil::message_for( key, value )) do
							SpecUtil::setup_test( test_dir ) if output.nil?
							SpecUtil::in_temp_dir do
								# Run the test only once, for the first expectation
								output = `#{test} 2>&1` if output.nil?

								case key
								when :exit_code
									$?.exitstatus.should == value
								when :output
									output.index( value ).should_not be_nil
								when :produced_files
									value.each do |file|
										File.should be_exists( file )
									end
								else
									raise "Unexpected key '#{key}'"
								end
							end
						end
					end
				end
			end
		end
	end
end
