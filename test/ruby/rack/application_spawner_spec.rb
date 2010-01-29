require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'phusion_passenger/rack/application_spawner'

require 'ruby/shared/abstract_server_spec'
require 'ruby/shared/spawners/spawn_server_spec'
require 'ruby/shared/spawners/spawner_spec'
require 'ruby/shared/spawners/preloading_spawner_spec'
require 'ruby/shared/spawners/non_preloading_spawner_spec'

describe Rack::ApplicationSpawner do
	include SpawnerSpecHelper
	
	after :each do
		@spawner.stop if @spawner && @spawner.started?
	end
	
	describe "conservative spawning" do
		def spawn_some_application(extra_options = {})
			stub = register_stub(RackStub.new('rack'))
			yield stub if block_given?
			
			defaults = {
				"app_root"    => stub.app_root,
				"lowest_user" => CONFIG['lowest_user']
			}
			options = defaults.merge(extra_options)
			app = Rack::ApplicationSpawner.spawn_application(options)
			return register_app(app)
		end
		
		it_should_behave_like "a spawner"
		it_should_behave_like "a spawner that does not preload app code"
	end
	
	describe "smart spawning" do
		def server
			return spawner
		end
		
		def spawner
			@spawner ||= begin
				stub = register_stub(RackStub.new("rack"))
				spawner = Rack::ApplicationSpawner.new("app_root" => stub.app_root)
				spawner.start
				spawner
			end
		end
		
		def spawn_some_application(extra_options = {})
			stub = register_stub(RackStub.new('rack'))
			yield stub if block_given?
			
			defaults = {
				"app_root"    => stub.app_root,
				"lowest_user" => CONFIG['lowest_user']
			}
			options = defaults.merge(extra_options)
			@spawner ||= begin
				spawner = Rack::ApplicationSpawner.new(options)
				spawner.start
				spawner
			end
			app = @spawner.spawn_application(options)
			return register_app(app)
		end
		
		it_should_behave_like "an AbstractServer"
		it_should_behave_like "a spawn server"
		it_should_behave_like "a spawner"
		it_should_behave_like "a spawner that preloads app code"
	end
end
