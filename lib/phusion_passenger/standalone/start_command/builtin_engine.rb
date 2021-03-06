#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2014 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

PhusionPassenger.require_passenger_lib 'constants'
PhusionPassenger.require_passenger_lib 'standalone/control_utils'
PhusionPassenger.require_passenger_lib 'utils/shellwords'

module PhusionPassenger
module Standalone
class StartCommand

module BuiltinEngine
private
	def start_engine_real
		Standalone::ControlUtils.require_daemon_controller
		@engine = DaemonController.new(build_daemon_controller_options)
		start_engine_no_create
	end

	def start_engine_no_create
		begin
			@engine.start
		rescue DaemonController::AlreadyStarted
			begin
				pid = @engine.pid
			rescue SystemCallError, IOError
				pid = nil
			end
			if pid
				abort "#{PROGRAM_NAME} Standalone is already running on PID #{pid}."
			else
				abort "#{PROGRAM_NAME} Standalone is already running."
			end
		rescue DaemonController::StartError => e
			abort "Could not start the server engine:\n#{e}"
		end
	end

	def build_daemon_controller_options
		if @options[:socket_file]
			ping_spec = [:unix, @options[:socket_file]]
		else
			ping_spec = [:tcp, @options[:address], @options[:port]]
		end

		command = "#{@agent_exe} watchdog";
		command << " --passenger-root #{Shellwords.escape PhusionPassenger.install_spec}"
		command << " --daemonize"
		command << " --no-delete-pid-file"
		command << " --cleanup-pidfile #{Shellwords.escape @working_dir}/temp_dir_toucher.pid"
		add_param(command, :user, "--user")
		add_param(command, :log_file, "--log-file")
		add_param(command, :pid_file, "--pid-file")
		add_param(command, :instance_registry_dir, "--instance-registry-dir")
		add_param(command, :data_buffer_dir, "--data-buffer-dir")
		add_param(command, :log_level, "--log-level")
		@options[:ctls].each do |ctl|
			command << " --ctl #{Shellwords.escape ctl}"
		end

		command << " --BS"
		command << " --listen #{listen_address}"
		command << " --no-graceful-exit"
		add_param(command, :environment, "--environment")
		add_param(command, :app_type, "--app-type")
		add_param(command, :startup_file, "--startup-file")
		add_param(command, :spawn_method, "--spawn-method")
		add_param(command, :restart_dir, "--restart-dir")
		if @options.has_key?(:friendly_error_pages)
			if @options[:friendly_error_pages]
				command << " --force-friendly-error-pages"
			else
				command << " --disable-friendly-error-pages"
			end
		end
		if @options[:turbocaching] == false
			command << " --disable-turbocaching"
		end
		add_flag_param(command, :load_shell_envvars, "--load-shell-envvars")
		add_param(command, :max_pool_size, "--max-pool-size")
		add_param(command, :min_instances, "--min-instances")
		add_enterprise_param(command, :concurrency_model, "--concurrency-model")
		add_enterprise_param(command, :thread_count, "--thread-count")
		add_enterprise_flag_param(command, :rolling_restarts, "--rolling-restarts")
		add_enterprise_flag_param(command, :resist_deployment_errors, "--resist-deployment-errors")
		add_flag_param(command, :sticky_sessions, "--sticky-sessions")
		add_param(command, :sticky_sessions_cookie_name, "--sticky-sessions-cookie-name")
		add_param(command, :union_station_gateway_address, "--union-station-gateway-address")
		add_param(command, :union_station_gateway_port, "--union-station-gateway-port")
		add_param(command, :union_station_key, "--union-station-key")

		command << " #{Shellwords.escape(@apps[0][:root])}"

		return {
			:identifier    => "#{AGENT_EXE} watchdog",
			:start_command => command,
			:ping_command  => ping_spec,
			:pid_file      => @options[:pid_file],
			:log_file      => @options[:log_file],
			:timeout       => 25
		}
	end

	def listen_address(options = @options, for_ping_port = false)
		if options[:socket_file]
			return "unix:" + File.absolute_path_no_resolve(options[:socket_file])
		else
			return "tcp://" + compose_ip_and_port(options[:address], options[:port])
		end
	end

	def add_param(command, option_name, param_name)
		if value = @options[option_name]
			command << " #{param_name} #{Shellwords.escape value.to_s}"
		end
	end

	def add_flag_param(command, option_name, param_name)
		if value = @options[option_name]
			command << " #{param_name}"
		end
	end

	def add_enterprise_param(command, option_name, param_name)
		if value = @options[option_name]
			abort "The '#{option_name}' feature is only available in #{PROGRAM_NAME} " +
				"Enterprise. You are currently running the open source #{PROGRAM_NAME}. " +
				"Please learn more about and/or buy #{PROGRAM_NAME} Enterprise at " +
				"https://www.phusionpassenger.com/enterprise"
		end
	end

	def add_enterprise_flag_param(command, option_name, param_name)
		if value = @options[option_name]
			abort "The '#{option_name}' feature is only available in #{PROGRAM_NAME} " +
				"Enterprise. You are currently running the open source #{PROGRAM_NAME}. " +
				"Please learn more about and/or buy #{PROGRAM_NAME} Enterprise at " +
				"https://www.phusionpassenger.com/enterprise"
		end
	end

	#####################
end

end # module StartCommand
end # module Standalone
end # module PhusionPassenger
