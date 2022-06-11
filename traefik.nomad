job "traefik" {

  datacenters = ["dc1"]

  group "traefik" {

    count = 1

    network {
      port "minecraft" {
	static = 25565
      }
      port "http" {
	static = 8080
      }
      port "traefik" {
	static = 8081
      }
    }

    service {
      name = "traefik"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "minecraft"
        interval = "10s"
        timeout  = "2s"	
      }
    }

    task "traefik" {
      driver = "docker"

      config {
	image        = "traefik:v2.7"
	network_mode = "host"
	volumes = [
	  "local/traefik.toml:/etc/traefik/traefik.toml"
	]
      }

      template {
	data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":8080"
    [entryPoints.traefik]
    address = ":8081"
    [entryPoints.minecraft]
    address = ":25565"

[api]
    dashboard = true
    insecure  = true

[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.consulCatalog.endpoint]
      address = "127.0.0.1:8500"
      scheme  = "http"
EOF
	destination = "local/traefik.toml"
      }

      resources {
	cpu    = 100
	memory = 128
      }
    }
  }
}
