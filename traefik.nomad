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
      provider = "nomad"
      port = "traefik"
      tags = [
        "traefik",
        "traefik.enable=true",
        "traefik.http.routers.traefik.rule=Host(`traefik.mc-server.lan`)",
        "traefik.http.routers.traefik.entrypoints=traefik",
        "traefik.http.routers.traefik.service=api@internal",
      ]
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.8.0-rc1"
        ports = ["minecraft", "http", "traefik"]
        args  = [
          "--api.dashboard=true",
          "--api.insecure=true",
          "--entrypoints.http.address=:8080",
          "--entrypoints.traefik.address=:8081",
          "--entrypoints.minecraft.address=:25565",
          "--entrypoints.postgres.address=:5432",
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://192.168.1.103:4646",
          "--providers.nomad.exposedByDefault=false",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
