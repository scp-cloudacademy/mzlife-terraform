# mzlife-terraform

terraform init

terraform plan

terraform apply

terraform output -raw bastion_private_key > mykey.pem

icacls mykey.pem /inheritance:r /grant:r "%USERNAME%:R"
