# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-server-focal" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_api_url}"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token_secret}"
  # (Optional) Skip TLS Verification
  # insecure_skip_tls_verify = true

  # VM General Settings
  node                 = "z640"
  vm_id                = "9000"
  vm_name              = "ubuntu-server-focal"
  template_description = "Ubuntu Server Focal Image"

  # VM OS Settings
  # (Option 1) Local ISO File
  iso_file = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
  # - or -
  # (Option 2) Download ISO
  # iso_url = "https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso"
  # iso_checksum = "45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
  iso_storage_pool = "local"
  unmount_iso      = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "20G"
    storage_pool = "local-lvm"
    type         = "virtio"
  }

  # VM CPU Settings
  cores = "1"

  # VM Memory Settings
  memory = "2048"

  # VM Network Settings
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # PACKER Boot Commands
  # boot_command = [
  #   "<esc><wait><esc><wait>",
  #   "<f6><wait><esc><wait>",
  #   "<bs><bs><bs><bs><bs>",
  #   "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
  #   "--- <enter>"
  # ]

  boot_command = [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  # PACKER Autoinstall Settings
  http_directory = "http"
  # (Optional) Bind IP Address and Port
  # http_bind_address = "0.0.0.0"
  # http_port_min = 8802
  # http_port_max = 8802

  ssh_username = "jokerwrld"

  # (Option 1) Add your Password here
  # ssh_password = "your-password"
  # - or -
  # (Option 2) Add your Private SSH KEY file here
  # ssh_private_key_file = "~/.ssh/id_rsa"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-server-focal"
  sources = ["source.proxmox-iso.ubuntu-server-focal"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Add additional provisioning scripts here
  # ...
}