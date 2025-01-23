resource "local_file" "hosts_templatefile" {
  content = templatefile("${path.module}/hosts.tftpl",

  { webservers = yandex_compute_instance.web 
    databases  = yandex_compute_instance.db
    storage    = yandex_compute_instance.storage })

  filename = "${abspath(path.module)}/hosts.ini"
}

resource "local_file" "hosts_for" {
  content = <<EOT
  %{if length(yandex_compute_instance.web) > 0}
  [webservers]
  %{for idx, inst in yandex_compute_instance.web }
  ${inst.name}   ansible_host=${inst.network_interface[0].nat_ip_address} fqdn=${inst.fqdn}
  %{endfor}
  %{endif}

  %{if length(yandex_compute_instance.db) > 0}
  [databases]
  %{for name, inst in yandex_compute_instance.db }
  ${inst.name}   ansible_host=${inst.network_interface[0].nat_ip_address} fqdn=${inst.fqdn}
  %{endfor}
  %{endif}

  %{if yandex_compute_instance.storage != null}
  [storage]
  ${yandex_compute_instance.storage.name}   ansible_host=${yandex_compute_instance.storage.network_interface[0].nat_ip_address} fqdn=${yandex_compute_instance.storage.fqdn}
  %{endif}

  [all:vars]
  ansible_ssh_user=ubuntu
  ansible_ssh_private_key_file=~/.ssh/id_ed25519
  EOT
  filename = "${abspath(path.module)}/for.ini"
}

locals {
  instances_yaml = concat(
    yandex_compute_instance.web,
    values(yandex_compute_instance.db),
    [yandex_compute_instance.storage]
  )
}

resource "local_file" "hosts_yaml" {
  content = <<-EOT
  all:
    hosts:
    %{ for i in local.instances_yaml ~}
      ${i.name}:
        ansible_host: ${i.network_interface[0].nat_ip_address}
        fqdn: ${i.fqdn}
    %{ endfor ~}
    vars:
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
  EOT
  filename = "${abspath(path.module)}/hosts.yaml"
}
