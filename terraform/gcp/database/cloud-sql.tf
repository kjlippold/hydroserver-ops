# -------------------------------------------------- #
# HydroServer GCP Cloud SQL Database                 #
# -------------------------------------------------- #

resource "google_sql_database_instance" "hydroserver_db_instance" {
  name             = "hydroserver-${var.instance}"
  database_version = "POSTGRES_15"
  region           = var.region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${data.google_project.gcp_project.project_id}/global/networks/hydroserver-${var.instance}"
      require_ssl     = false
    }
    database_flags {
      name  = "max_connections"
      value = "100"
    }
    user_labels = {
      "${var.label_key}" = local.label_value
    }
  }
}

resource "google_sql_database" "hydroserver_db" {
  name     = "hydroserver"
  instance = google_sql_database_instance.hydroserver_db_instance.name
}

resource "random_password" "hydroserver_db_user_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "hydroserver_db_user" {
  name     = "hsdbadmin"
  instance = google_sql_database_instance.hydroserver_db_instance.name
  password = random_password.hydroserver_db_user_password.result
}

# -------------------------------------------------- #
# HydroServer GCP Cloud SQL Database Connection      #
# -------------------------------------------------- #

resource "google_secret_manager_secret" "hydroserver_database_url" {
  secret_id = "hydroserver-database-url-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_database_url_version" {
  secret      = google_secret_manager_secret.hydroserver_database_url.id
  secret_data = "postgresql://${google_sql_user.hydroserver_db_user.name}:${google_sql_user.hydroserver_db_user.password}@${google_sql_database_instance.hydroserver_db_instance.ip_address[0].ip_address}/${google_sql_database.hydroserver_db.name}?sslmode=disable"
}

resource "random_password" "hydroserver_api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  number           = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "google_secret_manager_secret" "hydroserver_api_secret_key" {
  secret_id = "hydroserver-api-secret-key-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_api_secret_key_version" {
  secret      = google_secret_manager_secret.hydroserver_api_secret_key.id
  secret_data = random_password.hydroserver_api_secret_key.result
}
