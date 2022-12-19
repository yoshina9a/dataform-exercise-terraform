variable "project_id" {
  default = "xxx"
}

variable "dataform_service_account" {
  default = "service-yyy@gcp-sa-dataform.iam.gserviceaccount.com"
}

variable "authentication_token_secret" {
  default = "token"
}

variable "git_repository" {
  default = "repository_url"
}


provider "google-beta" {
  project = var.project_id
  region  = "us-central1"
}


resource "google_project_iam_member" "member_role" {
  provider  = google-beta
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ])
  role = each.key
  member = "serviceAccount:${var.dataform_service_account}"
  project = var.project_id
}

resource "google_secret_manager_secret" "dataform_exercise_git" {
  provider  = google-beta
  secret_id = "dataform-exercise-git"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "dataform_exercise_git_version" {
  provider    = google-beta
  secret      = google_secret_manager_secret.dataform_exercise_git.id
  secret_data = var.authentication_token_secret
}

resource "google_secret_manager_secret_iam_member" "member" {
  provider  = google-beta
  secret_id = google_secret_manager_secret.dataform_exercise_git.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.dataform_service_account}"
}

resource "google_dataform_repository" "dataform_exercise_repository" {
  provider = google-beta
  name     = "shrine"

  git_remote_settings {
    url                                 = var.git_repository
    default_branch                      = "main"
    authentication_token_secret_version = google_secret_manager_secret_version.dataform_exercise_git_version.id
  }
}
