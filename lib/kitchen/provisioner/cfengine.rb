# -*- encoding: utf-8 -*-
#
# Author:: Sam Crang (<sam.crang@gmail.com>)
#
# Copyright (C) 2013, Sam Crang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'

module Kitchen

  module Provisioner

    class Cfengine < Base

      include Logging

      def initialize(instance, config)
        @instance = instance
        @config = config
        @logger = instance.logger
      end

      def install_command
        <<-INSTALL.gsub(/^ {10}/, '')
          sudo bash -c '
            echo "deb http://cfengine.com/pub/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/cfengine-community.list
            wget --output-document=/tmp/cfengine-gpg.key http://cfengine.com/pub/gpg.key
            sudo apt-key add /tmp/cfengine-gpg.key
            rm /tmp/cfengine-gpg.key
            apt-get update
            apt-get -y install cfengine-community
            /var/cfengine/bin/cf-key
            /var/cfengine/bin/cf-agent --bootstrap `hostname -I`'
        INSTALL
      end

      def cleanup_sandbox ; end

      def create_sandbox
        @tmpdir = Dir.mktmpdir("#{instance.name}-sandbox-")
        File.chmod(0755, @tmpdir)
		cfengine_tmp = File.join(tmpdir, "cfengine")

		instance.bundle_list
			.map { |cf_file| File.dirname(cf_file) }
			.uniq
			.each { |source_path|
				sandbox_path = File.join(cfengine_tmp, source_path)
				FileUtils.mkdir_p(sandbox_path)
				FileUtils.cp_r(Dir.glob("#{source_path}/*"), sandbox_path)
			}

		cfengine_tmp
      end

      def init_command ; end

      def prepare_command ; end

      def run_command
        instance.bundle_list.map { |x| "sudo /var/cfengine/bin/cf-agent -KI -f #{home_path}/" + x }.join(" && ")
      end

      def home_path
        "/tmp/cfengine".freeze
      end
    end
  end
end
