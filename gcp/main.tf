################################################################################
# SETUP
################################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = "us-west2"
  credentials = file(var.service_account_key_file)
}

## You should enable the Compute Engine API via the Cloud Console
# resource "google_project_service" "compute" {
#   service = "compute.googleapis.com"
# }

output "ssh" {
  value       = "ssh -i '${var.ssh_key}' ubuntu@${google_compute_instance.pi-hole.network_interface[0].access_config[0].nat_ip}"
  description = "Command to ssh into the box"
}

################################################################################
# NETWORK
################################################################################

resource "google_compute_network" "pi-hole-network" {
  name                    = "pi-hole-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "pi-hole-admin-ports" {
  name    = "pi-hole-admin-ports"
  network = google_compute_network.pi-hole-network.name

  # SSH, HTTP
  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "pi-hole-dns-ports" {
  name    = "pi-hole-dns-ports"
  network = google_compute_network.pi-hole-network.name

  # DNS
  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  # DNS, OpenVPN
  allow {
    protocol = "udp"
    ports    = ["53", "1194"]
  }

  source_ranges = var.source_ranges
}

resource "google_compute_address" "pi-hole-static-ip" {
  name         = "pi-hole-static-ip"
  region       = "us-west2"
  network_tier = "STANDARD"
}

################################################################################
# COMPUTE
################################################################################

resource "google_compute_instance" "pi-hole" {
  name         = "pi-hole"
  machine_type = "f1-micro"
  zone         = "us-west2-a"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.pi-hole-network.name
    access_config {
      nat_ip       = google_compute_address.pi-hole-static-ip.address
      network_tier = "STANDARD"
    }
  }

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-1-0"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key)}"
    enable-osconfig = "TRUE"
  }
}
