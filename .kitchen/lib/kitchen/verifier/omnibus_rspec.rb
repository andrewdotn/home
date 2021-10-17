module Kitchen

  module Verifier

    # Busser is too slow to install. Just run rspec from the Chef omnibus
    # package. It already includes serverspec.
    class OmnibusRspec < Kitchen::Verifier::Base

      def call(state)
        instance.transport.connection(state) do |conn|
          puts 'running upload'
          conn.upload(File.join(config[:test_base_path], config[:suite_name]),
                      config[:root_path])
          conn.execute "/opt/chef/embedded/bin/rspec " +
            File.join(config[:root_path], config[:suite_name], 'rspec').to_s
        end
      end

    end

  end

end
