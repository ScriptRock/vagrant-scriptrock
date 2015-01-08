require 'cgi'
require 'httparty'

module VagrantPlugins
	module ScriptRock
		class Provisioner < Vagrant.plugin("2", :provisioner)

			class GuardrailPrivateKeyInstallError < Vagrant::Errors::VagrantError
			end

			def initialize(machine, config)
				@debug = false
				@machine = machine
				@root_config = machine.config
				puts "provision initialize config" if @debug
			end

			def configure(root_config)
				puts "provision configure" if @debug
				@root_config = root_config
			end

			def guardrail_name
				return "#{@root_config.scriptrock.name_prefix} #{@machine.name}"
			end

			def guardrail_auth_headers
				return { "Authorization" => "Token token=\"#{@root_config.scriptrock.api_key}#{@root_config.scriptrock.secret_key}\"" }
			end

			def guardrail_lookup_and_show
				url = "#{@root_config.scriptrock.connect_url}/api/v1/nodes/lookup.json?name=#{CGI.escape(guardrail_name)}"
				response = HTTParty.get(url, :headers => guardrail_auth_headers)
				if response.code == 200
					responseJson = JSON.parse(response.body)
					url = "#{@root_config.scriptrock.connect_url}/api/v1/nodes/#{responseJson["node_id"]}.json"
					response = HTTParty.get(url, :headers => guardrail_auth_headers)
					responseJson = JSON.parse(response.body)
					if response.code == 200
						puts "ScriptRock: node already exists, id #{responseJson["id"]} name '#{guardrail_name}'"
						return responseJson
					end
				end
				return nil
			end

			def guardrail_create
				url = "#{@root_config.scriptrock.connect_url}/api/v1/nodes.json"
				response = HTTParty.post(url, :headers => guardrail_auth_headers, :body => {
						:node => {
							"name" => guardrail_name,
							"node_type" => "SV",
						},
					})
				responseJson = JSON.parse(response.body)
				if response.code == 201
					puts "ScriptRock: created new node, id #{responseJson["id"]} name '#{guardrail_name}'"
					return responseJson
				else
					throw "ScriptRock Guardrail create node error code #{response.code} body: #{response.body}"
				end
			end

			def guardrail_update(node)
				url = "#{@root_config.scriptrock.connect_url}/api/v1/nodes/#{node["id"]}.json"
				ssh_info = @machine.ssh_info
				node = {
					:medium_type => 3,
					:description => "#{@machine.name} (vagrant)",
					:medium_hostname => "#{@root_config.scriptrock.first_hop} ssh://#{ssh_info[:username]}@#{ssh_info[:host]}:#{ssh_info[:port]}".strip,
				}
				response = HTTParty.put(url, :headers => guardrail_auth_headers, :body => { :node => node })
				if response.code == 204
					return true
				else
					throw "ScriptRock Guardrail update node error code #{response.code} body: #{response.body}"
				end				
			end

			def guardrail_delete
				begin
					node = guardrail_lookup_and_show
					if node == nil
						puts "ScriptRock: node with name '#{guardrail_name}' not found"
					else
						url = "#{@root_config.scriptrock.connect_url}/api/v1/nodes/#{node["id"]}.json"
						response = HTTParty.delete(url, :headers => guardrail_auth_headers)
						if response.code == 204
							puts "ScriptRock: deleted node, id #{node["id"]} name #{guardrail_name}"
							return true
						else
							throw "ScriptRock Guardrail delete node error code #{response.code} body: #{response.body}"
						end			
					end
				rescue => e
					puts "Error contacting guardrail api: #{e.class}: #{e.message}"
				end
			end

			def guardrail_create_update
				begin
					node = guardrail_lookup_and_show
					if node == nil
						node = guardrail_create
					end
					guardrail_update(node)
				rescue => e
					puts "Error contacting guardrail api: #{e.class}: #{e.message}"
				end
			end

			def provision
				puts "provision provision" if @debug

				# insert the guardrail public key onto the target node if it is not already present
				puts "Checking for and possibly installing Guardrail public key in ~/.ssh/authorized_keys..."
				pk = @root_config.scriptrock.ssh_pubkey
				key_install_script = "mkdir -p ~/.ssh && " +
					"(grep -q -s '#{pk}' ~/.ssh/authorized_keys || echo '#{pk}' >> ~/.ssh/authorized_keys) && "+
					"grep -q -s '#{pk}' ~/.ssh/authorized_keys"
				@machine.communicate.tap do |comm|
					comm.execute(key_install_script, error_class: GuardrailPrivateKeyInstallError)
				end

				# add this node to guardrail if not already present, then update to use the current credentials + forwarded port
				guardrail_create_update
			end

			def cleanup
				puts "provision cleanup" if @debug
				guardrail_delete
			end
		end
	end
end
