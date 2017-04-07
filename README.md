# CoreOS Vagrant

This repo provides a template Vagrantfile to create a CoreOS virtual machine using the VirtualBox software hypervisor.
After setup is complete you will have a single CoreOS virtual machine running on your local machine.

## Contact
IRC: #coreos on freenode.org

Mailing list: [coreos-dev](https://groups.google.com/forum/#!forum/coreos-dev)

## Streamlined setup

1) Install dependencies

* [VirtualBox][virtualbox] 4.3.10 or greater.
* [Vagrant][vagrant] 1.6.3 or greater.

2) Clone this project and get it running!

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
```

3) Startup and SSH

There are two "providers" for Vagrant with slightly different instructions.
Follow one of the following two options:

**VirtualBox Provider**

The VirtualBox provider is the default Vagrant provider. Use this if you are unsure.

```
vagrant up
vagrant ssh
```

**VMware Provider**

The VMware provider is a commercial addon from Hashicorp that offers better stability and speed.
If you use this provider follow these instructions.

VMware Fusion:
```
vagrant up --provider vmware_fusion
vagrant ssh
```

VMware Workstation:
```
vagrant up --provider vmware_workstation
vagrant ssh
```

``vagrant up`` triggers vagrant to download the CoreOS image (if necessary) and (re)launch the instance

``vagrant ssh`` connects you to the virtual machine.
Configuration is stored in the directory so you can always return to this machine by executing vagrant ssh from the directory where the Vagrantfile was located.

4) Get started [using CoreOS][using-coreos]

[virtualbox]: https://www.virtualbox.org/
[vagrant]: https://www.vagrantup.com/downloads.html
[using-coreos]: http://coreos.com/docs/using-coreos/

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.network "private_network", ip: "172.17.8.150"
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

#### Provisioning with user-data

The Vagrantfile will provision your CoreOS VM(s) with [coreos-cloudinit][coreos-cloudinit] if a `user-data` file is found in the project directory.
coreos-cloudinit simplifies the provisioning process through the use of a script or cloud-config document.

To get started, copy `user-data.sample` to `user-data` and make any necessary modifications.
Check out the [coreos-cloudinit documentation][coreos-cloudinit] to learn about the available features.

[coreos-cloudinit]: https://github.com/coreos/coreos-cloudinit

#### Configuration

The Vagrantfile will parse a `config.rb` file containing a set of options used to configure your CoreOS cluster.
See `config.rb.sample` for more information.

## Cluster Setup

Launching a CoreOS cluster on Vagrant is as simple as configuring `$num_instances` in a `config.rb` file to 3 (or more!) and running `vagrant up`.
Make sure you provide a fresh discovery URL in your `user-data` if you wish to bootstrap etcd in your cluster.

## New Box Versions

CoreOS is a rolling release distribution and versions that are out of date will automatically update.
If you want to start from the most up to date version you will need to make sure that you have the latest box file of CoreOS. You can do this by running
```
vagrant box update
```


## Docker Forwarding

By setting the `$expose_docker_tcp` configuration value you can forward a local TCP port to docker on
each CoreOS machine that you launch. The first machine will be available on the port that you specify
and each additional machine will increment the port by 1.

Follow the [Enable Remote API instructions][coreos-enabling-port-forwarding] to get the CoreOS VM setup to work with port forwarding.

[coreos-enabling-port-forwarding]: https://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket

Then you can then use the `docker` command from your local shell by setting `DOCKER_HOST`:

    export DOCKER_HOST=tcp://localhost:2375

# CoreOS Vagrant deploying sample app Ruby Application in VirtualBox

Apply the use of the containers oriented operating system CoreOS creating systemd service units responsible for performing the necessary tasks for the correct operation of the Docker containers in which the application is divided. In this way, the main idea is deploy the next structure, manually and automatically:

![alt tag](https://github.com/carmelocuenca/csantana_project/blob/master/tfm_doc/images/figures/coreosdiagram.png?raw=true)

First of all you have to copy the *config.rb* file:

    cd coreos-vagrant
    cp config.rb.sample config.rb

*Vagrantfile* has been configured to uses the *user-data* VirtualBox version when this provider is choosen. This *cloud-config* is called *user-data.sampleapp.virtualbox*.


## Manual deploy

The 5 service units have been configured and written so the next step is prepare the deployment. To recognize the units these must be located under the systemd service. So the first step will be copy them to the */etc/systemd/system/directory*. The operation of the units passes through two states. The first state is the service enable, this will create the symbolic link of the unit for all users. The second state is the beginning of it.
That said, a script called **coreos-service-units-deploy.sh is created**, with permissions chmod + x, which will be in charge of making the copy of the units under systemd and that will enable and start the services.

In order of this script be executed when the CoreOS machine is started, a line will be added to the Vagrantfile file, which will indicate the path of the file to make use of the file and provision the machine with the directives included in it.

As a nfs share folder is being used you need to install *nfs-kernel-server*:

    sudo apt install nfs-kernel-server

Finally, you have to execute this to up the machine, provision it with the script and access to the machine. Remember that the default provider is VirtualBox and *vagrant up* is enough.

    vagrant up --provider=virtualbox
    vagrant ssh core-01

Access to the service:

    curl http://localhost:80

## Automatic deploy

The ideal deployment of the application through their service units would be automatically. This is implemented in CoreOS from the file named cloud-config that corresponds to user-data so that it specifies the order of the units to be deployed and the enable and start actions of the services to which they refer.

As you can see, it is no longer necessary to copy the files from the local drives to the CoreOS machine. Now, you use these files simply and those corresponding to fleet_machines.env and nginx.conf from the shared directory. Therefore the line of provision of the script in the Vagranfile file is no longer necessary. So, comment this line **config.vm.provision "shell", path: "coreos-service-units-deploy.sh"** in Vagrantfile.

Finally, you have to execute this to up the machine, provision it with the script and access to the machine. Remember that the default provider is VirtualBox and *vagrant up* is enough.

    vagrant up --provider=virtualbox
    vagrant ssh core-01

Access to the service:

    curl http://localhost:80

# CoreOS Vagrant deploying sample app Ruby Application in Amazon Web Services (AWS)

First of all you have to copy the *config.rb* file:

    cd coreos-vagrant
    cp config.rb.sample config.rb

In order to log in to the AWS account add a local executable file called in which it specifies your AWS credentials information, with the intention of being treated as environment variables in *Vagrantfile*. The content must have the following structure:

export AWS_KEY='XXXXXXXXXXXXXXXXXXX'
export AWS_SECRET='XXXXXXXXXXXXXXXXXXXXXXXXXXX'
export AWS_KEYNAME='XXXXXX'
export AWS_KEYPATH='XXXXXXXXXXXXXXXXXXXXXX'

Then run it:

    . *path-to-your-file*

Change in *Vagrantfile* to your particular values referred to your AWS account. This values are:

- *access_key_id*
- *secret_access_key*
- *keypair_name*
- *aws_region*
- *aws_availability_zone*
- *aws_subnet_id*
- *aws_security_groups*
- *aws_ami*
- *aws_instance_type*

*Vagrantfile* has been configured to uses the *user-data* AWS version when this provider is choosen. This *cloud-config* is called *user-data.sampleapp.aws*.


## 1 instance cluster

Execute this to up the infraestructure and then access to the machine:

    vagrant up --provider=aws
    vagrant ssh core-01

To check the cluster-health:
    
    # etcdctl cluster-health

To check the virtual network:

    # sudo systemctl status flanneld
    
Access to the service:

    curl http://localhost:80

## 3 instances cluster

Execute this to up the infraestructure:

    vagrant up --provider=aws

To check the cluster-health:
    
    for i in 1 2 3; do vagrant ssh core-0$i -c 'etcdctl cluster-health'; done

To check the virtual network:

    for i in 1 2 3; do vagrant ssh core-0$i -c 'sudo systemctl flanneld | head -n16'; done
    
To check virtual machines have connection with other virtual machines containers:

-Access to, for example, the virtual machine *core-03*:

    vagrant ssh core-03

-Inspect, for example, *some-postgres* container to know its IP address:

    # docker inspect some-postgress

-Test connection between *core-01* and *some-postgres* *core-03* container:

    # ping *some-postgres--core-03--IP-address*

Access to the service:

    for i in 1 2 3; do vagrant ssh core-0$i -c 'curl http://localhost:80 \
| tail -n 15'; done
