require 'httparty'
require 'json'
require 'yaml'

module VagrantPlugins
	module ScriptRock
		class Config < Vagrant.plugin(2, :config)
			attr_accessor :scriptrock_yml_path
			attr_accessor :first_hop
			attr_accessor :api_key
			attr_accessor :secret_key
			attr_accessor :connect_url
			attr_accessor :ssh_pubkey
			attr_accessor :name_prefix

			def initialize
				@debug = false
				puts "config initialize" if @debug
				@scriptrock_yml_path = "~/.scriptrock/vagrant.yml"
				@first_hop = UNSET_VALUE
				@api_key = UNSET_VALUE
				@secret_key = UNSET_VALUE
				@connect_url = UNSET_VALUE
				@ssh_pubkey = UNSET_VALUE
				@name_prefix = UNSET_VALUE
			end

			def load_vars_from_yml
				if unset(@api_key) || unset(@secret_key) || unset(@connect_url)
					path = @scriptrock_yml_path
					if unset(path)
						puts "ScriptRock yml config path un-set, not loading values from yml"
					elsif !File.exist?(File.expand_path(path))
						puts "ScriptRock yml file '#{path}' doesn't exist, not loading values from yml"
					else
						yml = YAML.load(File.read(File.expand_path(path)))
						puts yml if @debug
						if unset(@api_key)
							@api_key = yml["api_key"]
						end
						if unset(@secret_key)
							@secret_key = yml["secret_key"]
						end
						if unset(@connect_url)
							@connect_url = yml["connect_url"]
						end
					end
				end
			end

			def get_ssh_pubkey
				if @ssh_pubkey != UNSET_VALUE
					return @ssh_pubkey
				end

				load_vars_from_yml()
				begin
					puts "ScriptRock API connect_url #{@connect_url}" if @debug
					response = HTTParty.get(
						"#{@connect_url}/api/v1/users/ssh_key.json",
						:headers => {
							"Authorization" => "Token token=\"#{@api_key}\""
						})
					if response.code == 200
						h = JSON.parse(response.body)
						@ssh_pubkey = h["public_key"]
					else
						puts "ScriptRock get_ssh_pubkey error code = #{response.code}"
						puts "ScriptRock get_ssh_pubkey error body = #{response.body}"
					end
				rescue => e
					puts "ScriptRock get_ssh_pubkey error = #{e.class}: #{e.message}"
				end
				return @ssh_pubkey	
			end

			def finalize!
				puts "finalize!" if @debug
				get_ssh_pubkey()
				if unset(@first_hop)
					@first_hop = ""
				end
				if unset(@name_prefix)
					@name_prefix = "vagrant"
				end
			end

			def unset(v)
				return v == UNSET_VALUE || v == nil || v == ""
			end

			def dump
				puts "config dump"
				puts "yml_path #{@scriptrock_yml_path}"
				puts "api_key #{@api_key}"
				puts "connect_url #{@connect_url}"
				puts "ssh_pubkey #{@ssh_pubkey}"
			end

			def validate(machine)
				puts "config validate" if @debug
				dump if @debug

				errors = _detected_errors
				if unset(@api_key)
					errors << "ScriptRock Guardrail api_key is not set"
				end
				if unset(@secret_key)
					errors << "ScriptRock Guardrail secret_key is not set"
				end
				if unset(@connect_url)
					errors << "ScriptRock Guardrail connect_url is not set"
				end
				if unset(@ssh_pubkey)
					errors << "ScriptRock Guardrail ssh public key is not set"
				end

				{ "errors" => errors }
			end			
		end
	end
end
