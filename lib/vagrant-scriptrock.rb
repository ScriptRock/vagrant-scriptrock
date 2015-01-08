require "pathname"
require "vagrant-scriptrock/plugin"

module VagrantPlugins
	module ScriptRock
		lib_path = Pathname.new(File.expand_path("../vagrant-scriptrock", __FILE__))
		autoload :Config,      lib_path.join("config")
		autoload :Provisioner, lib_path.join("provisioner")

		# This returns the path to the source of this plugin.
		#
		# @return [Pathname]
		def self.source_root
			@source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
		end
	end
end
