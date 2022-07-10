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
      mode = "bridge"
      port "minecraft" {
        host_network = "default"
        to           = 25565
      }
      dns {
        servers  = ["192.168.1.103"]
        searches = ["."]
        options  = []
      }
    }

    volume "paper-data" {
      type      = "host"
      read_only = false
      source    = "mc-server-data"
    }

    service {
      name = "paper"
      provider = "nomad"
      tags = [
        "minecraft",
        "paper",
        "traefik.enable=true",
        "traefik.tcp.routers.minecraft.rule=HostSNI(`*`)",
        "traefik.tcp.routers.minecraft.entrypoints=minecraft",
      ]
      port = "minecraft"
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

      vault {
        policies = ["read-postgres-password"]
      }

      artifact {
        source      = "https://api.papermc.io/v2/projects/paper/versions/1.19/builds/58/downloads/paper-1.19-58.jar"
        destination = "local/paper.jar"
        mode        = "file"
        options {
          checksum = "sha256:c87853831bc00ab717145bdb1e1717d23b5d1a0acc109b23bb77f458fe14acf4"
        }
      }

      artifact {
        source      = "https://dynmap.us/releases/Dynmap-3.4-beta-4-spigot.jar"
        destination = "local/dynmap.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/jars/EssentialsX-2.19.5-dev+27-4a53cfe.jar"
        destination = "local/EssentialsX.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/jars/EssentialsXChat-2.19.5-dev+27-4a53cfe.jar"
        destination = "local/EssentialsXChat.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/jars/EssentialsXSpawn-2.19.5-dev+27-4a53cfe.jar"
        destination = "local/EssentialsXSpawn.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://download.luckperms.net/1438/bukkit/loader/LuckPerms-Bukkit-5.4.30.jar"
        destination = "local/LuckPerms-Bukkit.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://mediafiles.forgecdn.net/files/3462/546/Multiverse-Core-4.3.1.jar"
        destination = "local/Multiverse-Core.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://mediafiles.forgecdn.net/files/3687/469/Multiverse-Inventories-4.2.3.jar"
        destination = "local/Multiverse-Inventories.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://mediafiles.forgecdn.net/files/3113/114/Multiverse-Portals-4.2.1.jar"
        destination = "local/Multiverse-Portals.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://mediafiles.forgecdn.net/files/3007/470/Vault.jar"
        destination = "local/Vault.jar"
        mode        = "file"
      }

      artifact {
        source      = "https://mediafiles.forgecdn.net/files/3697/296/worldedit-bukkit-7.2.10.jar"
        destination = "local/worldedit-bukkit.jar"
        mode        = "file"
      }            

      volume_mount {
        volume      = "paper-data"
        destination = "/paper"
        read_only   = false
      }

      template {
        data        = file("./configuration.txt.tpl")
        destination = "local/configuration.txt"
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
          "paper.jar",
          "nogui",
        ]
        dns_servers = ["192.168.1.103"]
        volumes = [
          "local/configuration.txt:/paper/plugins/dynmap/configuration.txt",
          "local/paper.jar:/paper/paper.jar",
          "local/dynmap.jar:/paper/plugins/dynmap.jar",
          "local/EssentialsX.jar:/paper/plugins/EssentialsX.jar",
          "local/EssentialsXChat.jar:/paper/plugins/EssentialsXChat.jar",
          "local/EssentialsXSpawn.jar:/paper/plugins/EssentialsXSpawn.jar",
          "local/LuckPerms-Bukkit.jar:/paper/plugins/LuckPerms-Bukkit.jar",
          "local/Multiverse-Core.jar:/paper/plugins/Multiverse-Core.jar",
          "local/Multiverse-Inventories.jar:/paper/plugins/Multiverse-Inventories.jar",
          "local/Multiverse-Portals.jar:/paper/plugins/Multiverse-Portals.jar",
          "local/Vault.jar:/paper/plugins/Vault.jar",
          "local/worldedit-bukkit.jar:/paper/plugins/worldedit-bukkit.jar",
        ]
      }

      resources {
        cpu    = 1750
        memory = 3072
      }
    }
  }
}
