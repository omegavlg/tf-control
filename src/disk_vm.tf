resource "yandex_compute_disk" "vm_disks" {
  count       = 3
  name        = "disk-${count.index + 1}"
  zone        = var.default_zone
  size        = 1
  type        = "network-hdd"
}

resource "yandex_compute_instance" "storage" {
  name  = "storage"
  zone  = var.default_zone

  resources {
    cores         = var.vms_resources.storage.cores
    memory        = var.vms_resources.storage.memory
    core_fraction = var.vms_resources.storage.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }

  metadata = var.metadata   

  scheduling_policy {
    preemptible = var.vm_preemptible
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.vm_disks[*]
    content {
      disk_id = secondary_disk.value.id
    }
  }
}