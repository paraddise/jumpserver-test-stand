# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/ubuntu2204"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false


  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "172.17.100.10"

  config.dns.tld = "test"
  config.dns.patterns = [/^(\w+\.)*jumpserver\.test$/,]

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "private_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessable to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  config.vm.synced_folder ".", "/vagrant", create: true, disabled: false

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true
    vb.cpus = "4"
    # Customize the amount of memory on the VM:
    vb.memory = "10240"
    # vb.customize ["modifyvm", :id, "--nic1", "none"]  # Disable NAT (eth0)
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", name: "sysctl", inline: <<-SHELL
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/k8s.conf
    sudo sysctl --system

    sudo modprobe overlay
    sudo modprobe br_netfilter
    echo overlay > /etc/modules-load.d/crio.conf
    echo br_netfilter >> /etc/modules-load.d/crio.conf
    sudo swapoff /swap.img
    sudo cat /etc/fstab | grep -v /swap.img  | sudo tee /etc/fstab
  SHELL

  config.vm.provision "shell", name: "containerd", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    # install containerd
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install containerd.io
    sudo systemctl enable --now containerd
    sudo mkdir -p /etc/containerd/
    containerd config default | sed -e 's/^\(\s*\)SystemdCgroup.*$/\1SystemdCgroup = true/g' | sudo tee /etc/containerd/config.toml
    sudo systemctl restart containerd
  SHELL

  # Apply sysctl params without reboot
  config.vm.provision "shell", name: "kubeadm", inline: <<-SHELL
    # install kubernetes
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl jq
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo systemctl enable --now kubelet

    local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
    sudo kubeadm reset -f
    sudo kubeadm init \
      --cri-socket unix:///run/containerd/containerd.sock \
      --apiserver-advertise-address $local_ip \
      --control-plane-endpoint $local_ip \
      --upload-certs

    sudo cp /etc/kubernetes/admin.conf /vagrant/config
    mkdir -p $HOME/.kube
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    sudo cp /etc/kubernetes/admin.conf /vagrant/kubeconfig

    kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule-
  SHELL
end

VagrantDNS::Config.logger = Logger.new("dns.log")
