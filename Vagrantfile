# encoding: utf-8
# This file originally created at http://rove.io/d348301e6bed56b478925c670eecd1c3

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/trusty64"
  # config.vm.box = "opscode-ubuntu-12.04_chef-11.4.0"
  # config.vm.box_url = "https://opscode-vm-bento.s3.amazonaws.com/vagrant/opscode_ubuntu-12.04_chef-11.4.0.box"
  config.ssh.forward_agent = true

  config.vm.provider 'virtualbox' do |v|
    v.gui = true
    v.memory = 1024
  end

  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks"]
    chef.add_recipe 'apt'
    chef.add_recipe "nodejs"
    # chef.add_recipe 'git'
    chef.add_recipe 'ruby_build'
    chef.add_recipe 'rbenv::user'
    chef.add_recipe 'rbenv::vagrant'
    chef.json = {
      :git     => {
        :prefix => "/usr/local"
      },
      :rbenv   => {
        :user_installs => [
          {
            :user   => "vagrant",
            :rubies => [
              "2.1.5"
            ],
            :global => "2.1.5"  #,
            # gems: {
            #   "2.1.2" => [
            #     { name: "bundler" }
            #   ]
            # }
          }
        ]
      }
    }
  end
end
