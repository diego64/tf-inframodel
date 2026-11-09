provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = upper(var.project)
      ManagedBy = "terraform"
      Stack     = "00-remote-state-stack"
    }
  }
}
