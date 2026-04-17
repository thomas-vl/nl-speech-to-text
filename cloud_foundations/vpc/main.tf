provider "google" {
  impersonate_service_account = "sa-root-tf-vpc@pj-speech-text-state.iam.gserviceaccount.com"
  user_project_override       = true
  billing_project             = "pj-speech-text-state"
}

terraform {
  backend "gcs" {
    bucket                      = "gcs-tf-state-rm-pj-speech-text-state"
    prefix                      = "terraform/state/vpc"
    impersonate_service_account = "sa-root-tf-vpc@pj-speech-text-state.iam.gserviceaccount.com"
  }
}

module "basic" {
  source    = "./basic"
  firewalls = merge(var.cloud_firewalls, var.data_firewalls, var.ai_firewalls)
  vpc       = merge(var.cloud_vpc, var.data_vpc, var.ai_vpc)
  nats      = merge(var.cloud_nats, var.data_nats, var.ai_nats)
}
