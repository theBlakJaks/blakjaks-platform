variable "project_id"    {}
variable "region"        {}
variable "environment"   {}
variable "instance_name" {}
variable "db_name"       {}
variable "db_user"       {}
variable "db_password"   { sensitive = true }
variable "network"       {}
