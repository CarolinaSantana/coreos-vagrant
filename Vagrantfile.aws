# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

if (!ARGV.nil? && ARGV.join('').include?('provider=virtualbox')) || (!ARGV.nil? && !ARGV.join('').include?('provider'))
  FileUtils.cp_r(File.join(File.dirname(__FILE__), "user-data.sampleapp.virtualbox"), File.join(File.dirname(__FILE__), "user-data"), :remove_destination => true)
end

if (!ARGV.nil? && ARGV.join('').include?('provider=aws'))
  unless Vagrant.has_plugin?("vagrant-aws") 
    abort("Did not detect vagrant-aws plugin... vagrant plugin install vagrant-aws")
  end

  unless ENV['AWS_KEY'] && ENV['AWS_SECRET'] && ENV['AWS_KEYNAME']
    abort("$AWS_KEY && $AWS_SECRET && $AWS_KEYNAME should set before...")
  end
  FileUtils.cp_r(File.join(File.dirname(__FILE__), "user-data.sampleapp.aws"), File.join(File.dirname(__FILE__), "user-data"), :remove_destination => true)
end

CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "user-data")
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

# Defaults for config options defined in CONFIG
$num_instances = 3
$instance_name_prefix = "core"
$update_channel = "alpha"
$image_version = "current"
$enable_serial_logging = false
$share_home = false
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$vb_cpuexecutioncap = 100
$shared_folders = {}
$forwarded_ports = {}

$aws_region = 'us-east-1'
$aws_availability_zone = 'us-east-1a'
$aws_subnet_id = 'subnet-b17d79ea'
$aws_security_groups = 'sg-3319964c'
$aws_ami = 'ami-00598116'
$aws_instance_type = 't2.micro'
$aws_elastic_ip = true

# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_instances = ENV["NUM_INSTANCES"].to_i
end

if File.exist?(CONFIG)
  require CONFIG
end

# Use old vb_xxx config variables when set
def vm_gui
  $vb_gui.nil? ? $vm_gui : $vb_gui
end

def vm_memory
  $vb_memory.nil? ? $vm_memory : $vb_memory
end

def vm_cpus
  $vb_cpus.nil? ? $vm_cpus : $vb_cpus
end

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false
  # forward ssh agent to easily ssh into the different machines
  config.ssh.forward_agent = true
  
  config.vm.box = "coreos-%s" % $update_channel
  if $image_version != "current"
      config.vm.box_version = $image_version
  end

  config.vm.provider :virtualbox do |vb, override|
    override.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    vb.check_guest_additions = false
    vb.functional_vboxsf     = false
    #override.vm.provision "shell", path: "coreos-service-units-deploy.sh"
  end

  config.vm.provider :aws do |aws, override|
    aws.access_key_id = ENV['AWS_KEY']
    aws.secret_access_key = ENV['AWS_SECRET']
    aws.keypair_name = ENV['AWS_KEYNAME']

    aws.security_groups = $aws_security_groups

    aws.ami = $aws_ami
    aws.instance_type = $aws_instance_type
    aws.region = $aws_region
    aws.subnet_id = $aws_subnet_id
    aws.elastic_ip = $aws_elastic_ip

    override.vm.synced_folder ".", "/vagrant", disabled: true
    override.ssh.username = "core"
    override.ssh.private_key_path = ENV['AWS_KEYPATH']
    override.ssh.insert_key = false
    override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        config.vm.provider :virtualbox do |vb, override|
          logdir = File.join(File.dirname(__FILE__), "log")
          FileUtils.mkdir_p(logdir)
          serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
          FileUtils.touch(serialFile)
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.provider :virtualbox do |vb, override|
          override.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), host_ip: "127.0.0.1", auto_correct: true
        end
      end

      config.vm.provider :virtualbox do |vb, override|
        $forwarded_ports.each do |guest, host|
          override.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
        end
        vb.gui = vm_gui
        vb.memory = vm_memory
        vb.cpus = vm_cpus
        vb.customize ["modifyvm", :id, "--cpuexecutioncap", "#{$vb_cpuexecutioncap}"]
        ip = "172.17.8.#{i+100}"
        override.vm.network :private_network, ip: ip
      end
 
      # Shared storage configuration
      config.vm.provider :virtualbox do |vb, override|
        # Uncomment below to enable NFS for sharing the host machine into the coreos-vagrant VM.
        #override.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true, :mount_options => ['nolock,vers=3,udp']
        $shared_folders.each_with_index do |(host_folder, guest_folder), index|
          override.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
        end

        if $share_home
          override.vm.synced_folder ENV['HOME'], ENV['HOME'], id: "home", :nfs => true, :mount_options => ['nolock,vers=3,udp']
        end
      end

      # Copy of the cloud-config to the machine
      if File.exist?(CLOUD_CONFIG_PATH) && ARGV[0].eql?('up')

        config.vm.provider :virtualbox do |vb, override|
          override.vm.provision :file, :source => "#{CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
          override.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
        end

        config.vm.provider :aws do |aws, override|   
          user_data_specific	=	"#{CLOUD_CONFIG_PATH}-#{i}"
          require 'yaml'
          data = YAML.load(IO.readlines(CLOUD_CONFIG_PATH)[1..-1].join)
          if data['coreos'].key? 'fleet' and i==1
            data['coreos']['fleet']['metadata'] = 'compute=proxy'
          end
          if data['coreos'].key? 'fleet' and i==2
            data['coreos']['fleet']['metadata'] = 'compute=db'
          end
          yaml = YAML.dump(data)
          File.open(user_data_specific, 'w') do |file|
            file.write("#cloud-config\n\n#{yaml}")
          end
          aws.private_ip_address = "10.0.0.#{100+i}"
          aws.user_data = File.read(user_data_specific)
        end

      end

    end

  end

end
