job "folding-at-home" {
  datacenters = ["dc1"]
    group "folding-at-home" {
      task "folding-at-home" {
        driver = "docker"
          config {
            image  = "kentgruber/fah-client:latest"
          }
      }
    }
}