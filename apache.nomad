job "apache" {

  datacenters = ["dc1"]

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "apache" {

    network {
      mode = "bridge"
      port "http" {
        host_network = "default"
        to           = 8080
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
      name = "apache"
      tags = [
        "nginx",
        "traefik.enable=true",
        "traefik.http.routers.nginx.entrypoints=http",
        "traefik.http.routers.nginx.rule=PathPrefix(`/`)",
      ]
      port = "http"
      check {
        name     = "alive"
        path     = "/"
        port     = "http"
        timeout  = "5s"
        type     = "http"
        interval = "10s"
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

    task "apache" {
      driver = "docker"

      template {
        data        = file("./php.ini")
        destination = "local/php.ini"
      }

      template {
        data        = file("./apache2.conf")
        destination = "local/apache2.conf"
      }

      template {
        data        = <<EOF
Listen 8080
EOF
        destination = "local/ports.conf"
      }

      template {
        data        = <<EOF
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /paper/plugins/dynmap/web
    LogLevel info
</VirtualHost>
EOF
        destination = "local/000-default.conf"
      }

      volume_mount {
        volume      = "paper-data"
        destination = "/paper"
        read_only   = false
      }
      
      config {
        image = "2bdkid/dynmap-apache:latest"
        ports = ["http"]
        dns_servers = ["192.168.1.103"]
        volumes = [
          "local/php.ini:/usr/local/etc/php/conf.d/php.ini",
          "local/apache2.conf:/etc/apache2/apache2.conf",
          "local/ports.conf:/etc/apache2/ports.conf",
          "local/000-default.conf:/etc/apache2/sites-available/000-default.conf",
        ]
      }

      resources {
        cpu    = 500
        memory = 500
      }
    }
  }
}
