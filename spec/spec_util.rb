require 'fileutils'

require 'spec'


module SpecUtil

	ThisDir = File.expand_path( File.dirname( __FILE__ ))
	TempDir = "#{ThisDir}/tmp"

	class << self
		# Creates a temporary directory and copies the contents of +test_dir+ into
		# that directory.
		def setup_test( test_dir )
			FileUtils.rm_rf TempDir
			FileUtils.mkdir_p "#{TempDir}/lake"

			# If all the copying turns out to be slow, it might be worth symlinking.

			# Copy default rakefile in case none is specified in the test
			FileUtils.cp "#{ThisDir}/../Rakefile.local", "#{TempDir}/Rakefile"
			FileUtils.cp "#{ThisDir}/../Rakefile", "#{TempDir}/lake"
			FileUtils.cp Dir["#{ThisDir}/../*.rb"], "#{TempDir}/lake"

			FileUtils.cp_r Dir["#{test_dir}/*"], TempDir
		end

		def message_for( key, value )
			case key
			when :exit_code
				"exit with code #{value}"
			when :output
				"produce output that includes #{value}"
			when :produced_files
				"produce files #{value.to_sentence}"
			else
				"satisfy #{key} = #{value}"
			end
		end

		# Runs the block with the current working directory set to the same
		# temporary directory that setup_test creates.
		def in_temp_dir
			# save current pwd
			pwd = Dir.pwd
			Dir.chdir TempDir
			yield
		ensure
			Dir.chdir pwd
		end
	end
end

