### Initialization
- #### Configure AWS 
```
aws configure
```
- #### Validate Configuration

```
aws sts get-caller-identity
```

- #### Setup the S3 backend for storing terraform state files 
  Create a versioned bucket in AWS with name: `my-terraform-state-bucket-project-group10`
<br/>

### Setting required TF_VARS
```
TF_VAR_db_password=mysecret
```

### Managing Infrastructure
```
terraform init

terraform plan -out ecapp-infra-setup

terraform apply ecapp-infra-setup
```
