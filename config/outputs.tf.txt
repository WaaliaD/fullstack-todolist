output "frontend_url" {
  value = "http://${yandex_storage_bucket.todo_bucket.bucket}.website.yandexcloud.net"
}

output "backend_url" {
  value = try(
    one([
      for listener in yandex_lb_network_load_balancer.todolist_lb.listener :
      "http://${listener.external_address_spec[0].address}"
    ]),
    "load_balancer_not_configured"
  )
}

output "database_host" {
  value = yandex_mdb_postgresql_cluster.todolist_db.host[0].fqdn
}

output "vm_public_ip" {
  value = yandex_compute_instance.backend.network_interface[0].nat_ip_address
}
