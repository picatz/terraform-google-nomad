// Not actually used because it breaks things: https://github.com/hashicorp/nomad/issues/9991
// 
// However, using a cloud storage bucket with an atrifact stanza works to share/run private containers.
resource "google_container_registry" "nomad" {
  location = "US"
}