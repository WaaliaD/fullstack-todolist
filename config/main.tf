terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Сервисный аккаунт
resource "yandex_iam_service_account" "sa" {
  name        = "todolist-sa-${var.project_id}"
  description = "Service account for todolist application"
}

# Назначение ролей
resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.yc_folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Статический ключ доступа
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for object storage"
}

resource "time_sleep" "wait_for_iam" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin,
    yandex_resourcemanager_folder_iam_member.editor
  ]
  
  create_duration = "1m"
}

# Бакет Object Storage
resource "yandex_storage_bucket" "todo_bucket" {
  depends_on = [time_sleep.wait_for_iam]

  bucket     = "todo-bucket-${var.project_id}"
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  acl        = "public-read"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

# Загрузка фронтенда в бакет
resource "null_resource" "deploy_frontend" {
  depends_on = [yandex_storage_bucket.todo_bucket]

  provisioner "local-exec" {
    command = <<-EOT
      # Абсолютный путь к фронтенду
      FRONTEND_DIR="/home/butakov/todolist/fullstack-todolist/frontend"
      
      # Сборка проекта
      cd "$FRONTEND_DIR" && npm install && npm run build
      
      # Загрузка в бакет
      AWS_ACCESS_KEY_ID=${yandex_iam_service_account_static_access_key.sa_static_key.access_key} \
      AWS_SECRET_ACCESS_KEY=${yandex_iam_service_account_static_access_key.sa_static_key.secret_key} \
      aws --endpoint-url=https://storage.yandexcloud.net s3 sync "$FRONTEND_DIR/dist/" s3://${yandex_storage_bucket.todo_bucket.bucket}/ \
      --delete \
      --acl public-read
    EOT

    interpreter = ["/bin/bash", "-c"]
  }
}

# VPC сеть
resource "yandex_vpc_network" "todolist_network" {
  name = "todolist-network-${var.project_id}"
}

# Подсеть
resource "yandex_vpc_subnet" "todolist_subnet" {
  name           = "todolist-subnet-${var.project_id}"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.todolist_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Кластер PostgreSQL
resource "yandex_mdb_postgresql_cluster" "todolist_db" {
  name        = "todolist-db-${var.project_id}"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.todolist_network.id

  config {
    version = 15
    resources {
      resource_preset_id = "b1.medium"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.todolist_subnet.id
    assign_public_ip = true
  }
}

# Пользователь и БД
resource "yandex_mdb_postgresql_user" "todolist_user" {
  cluster_id = yandex_mdb_postgresql_cluster.todolist_db.id
  name       = "todolist_user"
  password   = var.db_password
}

resource "yandex_mdb_postgresql_database" "todolist_db" {
  cluster_id = yandex_mdb_postgresql_cluster.todolist_db.id
  name       = "todolist"
  owner      = yandex_mdb_postgresql_user.todolist_user.name
}

# Генерация backend.env
resource "local_file" "backend_env" {
  content = templatefile("${path.module}/backend.env.tmpl", {
    db_user     = yandex_mdb_postgresql_user.todolist_user.name
    db_password = var.db_password
    db_host     = yandex_mdb_postgresql_cluster.todolist_db.host[0].fqdn
    db_name     = yandex_mdb_postgresql_database.todolist_db.name
    bucket_name = yandex_storage_bucket.todo_bucket.bucket
  })
  filename = "${path.module}/backend.env"
}

# ВМ для бэкенда
resource "yandex_compute_instance" "backend" {
  name        = "todolist-backend-${var.project_id}"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit" # Ubuntu 22.04 LTS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.todolist_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  depends_on = [
    yandex_mdb_postgresql_database.todolist_db,
    yandex_storage_bucket.todo_bucket,
    local_file.backend_env
  ]

  provisioner "file" {
    source      = "backend.env"
    destination = "/home/ubuntu/backend.env"
    connection {
      type        = "ssh"
      host        = self.network_interface[0].nat_ip_address
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
    }
  }

  # Затем выполняем настройку
  provisioner "remote-exec" {
    inline = [
      # Логируем начало выполнения
      "echo '=== STARTING PROVISIONING ==='",
      "date",
      "lsb_release -a",
      
      # Установка зависимостей
      "echo '=== INSTALLING DEPENDENCIES ==='",
      "sudo apt-get update -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      
      # Добавляем Docker репозиторий
      "echo '=== SETTING UP DOCKER REPO ==='",
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      # Устанавливаем Docker
      "echo '=== INSTALLING DOCKER ==='",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      
      # Настройка Docker
      "echo '=== CONFIGURING DOCKER ==='",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      
      # Аутентификация в Yandex Container Registry
      "echo '=== AUTHENTICATING TO YANDEX CR ==='",
      "echo '${var.yc_iam_token}' | sudo docker login --username iam --password-stdin cr.yandex",
      
      # Запуск контейнера
      "echo '=== DEPLOYING CONTAINER ==='",
      "sudo docker rm -f todolist-backend || true",
      "sudo docker pull ${var.docker_image}",
      "sudo docker run -d --name todolist-backend -p 3000:3000 --restart unless-stopped --env-file /home/ubuntu/backend.env ${var.docker_image}",
      
      # Проверка
      "echo '=== VERIFYING DEPLOYMENT ==='",
      "sudo docker ps",
      "curl -v http://localhost:3000/healthcheck || true",
      "echo '=== PROVISIONING COMPLETE ==='"
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface[0].nat_ip_address
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      timeout     = "20m"  # Увеличенный таймаут
    }
  }
}

# Target Group
resource "yandex_lb_target_group" "todolist_tg" {
  name      = "todolist-tg"
  region_id = "ru-central1"

  target {
    subnet_id  = yandex_vpc_subnet.todolist_subnet.id
    address    = yandex_compute_instance.backend.network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "todolist_lb" {
  name = "todolist-lb-${var.project_id}"

  listener {
    name = "http-listener"
    port = 80
    target_port = 3000  # Вот здесь указываем порт целевой ВМ
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.todolist_tg.id
    
    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 3000
        path = "/healthcheck"
      }
      interval            = 10
      timeout             = 5
      unhealthy_threshold = 5
      healthy_threshold   = 3
    }
  }
}