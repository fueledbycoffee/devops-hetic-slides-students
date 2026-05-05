output "container_ids" {
  value = docker_container.app[*].id
}

output "urls" {
  value = [
    for c in docker_container.app :
    "http://localhost:${c.ports[0].external}"
  ]
}