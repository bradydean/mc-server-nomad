job "postgres" {

  datacenters = ["dc1"]

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "postgres" {
    network {
      mode = "bridge"
      port "postgres" {
        host_network = "default"
        static       = 5432
        to           = 5432
      }
    }

    volume "postgres-data" {
      type      = "host"
      read_only = false
      source    = "postgres-data"
    }

    service {
      name = "postgres"
      tags = [
        "postgres",
        "db",
      ]
      port = "postgres"
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

    task "postgres" {
      driver = "docker"
      user = "1000"

      vault {
        policies = ["read-postgres-password"]
      }
      
      template {
        data = <<EOF
{{ with secret "secret/postgres" }}
POSTGRES_PASSWORD="{{ .Data.password }}"
{{ end }}
EOF
        destination = "secrets/file.env"
        env         = true
      }

      template {
        data = <<EOF
{{ with secret "secret/postgres" }}
CREATE USER dynmap WITH PASSWORD '{{ .Data.dynmap_password }}';
CREATE DATABASE dynmap;
GRANT ALL PRIVILEGES ON DATABASE dynmap TO dynmap;
{{ end }}
EOF
        destination = "local/init.sql"
      }
      
      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }
      
      config {
        image = "postgres:14"
        ports = ["postgres"]
        volumes = [
          "/local/init.sql:/docker-entrypoint-initdb.d/init.sql"
        ]
      }

      resources {
        cpu    = 500
        memory = 500
      }
    }
  }
}
