terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {}
  required_version = ">= 1.2.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "instance" {
  description = "The name of this HydroServer instance."
  type        = string
}
variable "project_id" {
  description = "The project ID for this HydroServer instance."
  type        = string
}
variable "vpc_name" {
  description = "The VPC that this HydroServer instance will run in."
  type        = string
}
variable "region" {
  description = "The GCP region this HydroServer instance will be deployed in."
  type        = string
}
variable "hydroserver_version" {
  description = "The version of HydroServer to deploy."
  type        = string
  default     = "latest"
}
variable "label_key" {
  description = "The key of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = "hydroserver-instance"
}
variable "label_value" {
  description = "The value of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = ""
}

locals {
  label_value = var.label_value != "" ? var.label_value : var.instance
}

data "google_project" "gcp_project" {
  project_id = var.project_id
}
data "google_client_config" "current" {}




resource "google_storage_bucket" "target_bucket" {
  name     = "hydroserver-target-${var.instance}"
  location = var.region
}


resource "google_storage_bucket" "general_bucket" {
  name     = "hydroserver-general-${var.instance}"
  location = var.region
}


