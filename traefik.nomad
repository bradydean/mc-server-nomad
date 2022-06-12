job "traefik" {

  datacenters = ["dc1"]

  group "traefik" {

    count = 1

    network {
      mode = "bridge"
      port "minecraft" {
        static = 25565
      }
      port "http" {
        static = 8080
      }
      port "traefik" {
        static = 8081
      }
      port "postgres" {
        static = 5432
      }
    }

    service {
      name = "traefik"
      connect {
        sidecar_service {}
      }      
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.7"
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
    [entryPoints.postgres]
    address = ":5432"

[api]
    dashboard = true
    insecure  = true

[http.routers.traefik]
    rule = "Host(`traefik.mc-server.lan`)"
    entryPoints = ["traefik"]
    service = "api@internal"

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
