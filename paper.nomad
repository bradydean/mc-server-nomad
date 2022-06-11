job "paper" {

  datacenters = ["dc1"]

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "paper-server" {
    network {
      mode     = "bridge"
      port "minecraft" {
        host_network = "default"
        to           = 25565
      }
    }

    volume "paper-data" {
      type      = "host"
      read_only = false
      source    = "mc-server-data"
    }

    service {
      name = "paper"
      tags = [
	"minecraft",
	"paper",
	"traefik.enable=true",
	"traefik.tcp.routers.minecraft.rule=HostSNI(`*`)",
      ]
      port = "minecraft"

      check {
        name     = "alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    affinity {
      attribute = "${node.datacenter}"
      value  = "dc1"
      weight = 100
    }

    task "paper" {
      driver = "docker"
      user = "1000"

      volume_mount {
        volume      = "paper-data"
        destination = "/paper"
        read_only   = false
      }
      
      config {
        image = "amazoncorretto:18"
        ports = ["minecraft"]
        command = "java"
        interactive = true
        tty = true
        work_dir = "/paper"
        args = [
          "-Xmx3G",
          "-jar",
          "paper-1.18.2-378.jar",
          "nogui",
        ]
      }

      resources {
        cpu    = 1750
        memory = 3072
      }
    }
  }
}
