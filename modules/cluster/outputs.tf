
output "k8s_lb_ingress_ip" {
  value = kubernetes_service.todoapp.load_balancer_ingress[0].ip
}
