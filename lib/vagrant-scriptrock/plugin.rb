require "vagrant"

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
	raise "The Vagrant ScriptRock plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
	module ScriptRock
		class Plugin < Vagrant.plugin("2")
			name "ScriptRock"
			description <<-DESC
This plugin will install a Guardrail public key ~/.ssh/authorized_keys
on the instantiated vm, register the new node in the target Guardrail site,
and delete the node from the Guardrail when the vm is destroyed.
DESC

			config(:scriptrock) do
				require_relative "config"
				Config
			end

			provisioner(:scriptrock) do
				require_relative "provisioner"
				Provisioner
			end
		end
	end
end
