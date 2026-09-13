<div align="center">

# db-oficina-mecanica

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.11-844FBA?logo=terraform&logoColor=white)
![AWS Provider](https://img.shields.io/badge/AWS%20Provider-%7E%3E5.0-FF9900?logo=amazonaws&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![Amazon RDS](https://img.shields.io/badge/Amazon%20RDS-FF9900?logo=amazonrds&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

</div>

Scripts Terraform responsáveis por provisionar o banco de dados gerenciado (Amazon RDS PostgreSQL) usado pelo sistema Oficina Mecânica.

## O que este repositório provisiona

- `aws_db_instance` — instância RDS PostgreSQL (engine 16, `db.t3.micro` por padrão, `gp3` 20GB)
- `aws_db_subnet_group` — subnet group usando as subnets da VPC default da conta
- `aws_security_group` — libera a porta `5432` apenas dentro do CIDR da VPC (sem acesso público)

A VPC e as subnets **não são criadas aqui**: o Terraform apenas consulta a VPC default da conta via `data "aws_vpc"` / `data "aws_subnets"` (ver [main.tf](main.tf)). Não há dependência de remote state de outro repositório.

Este é um ambiente de **lab**: `deletion_protection = false` e `skip_final_snapshot = true`, ou seja, o banco pode ser destruído a qualquer momento sem snapshot de segurança.

## Repositórios relacionados

| Repositório | Papel |
|---|---|
| [k8s-infra-oficina-mecanica](https://github.com/Grupo-SOAT/k8s-infra-oficina-mecanica) | Cluster EKS, ECR, API Gateway, observability. É acionado via `repository_dispatch` (`db-deployed`) assim que o RDS sobe |
| [sistema-oficina-mecanica](https://github.com/Grupo-SOAT/sistema-oficina-mecanica) | Aplicação Spring Boot que consome este banco |

## Pré-requisitos

- Terraform `>= 1.11`
- Credenciais AWS com permissão para RDS, EC2 (VPC/SG) e acesso ao bucket de state
- Acesso ao bucket S3 do backend remoto (nome definido em tempo de `init`, ver [backend.tf](backend.tf) e seção [Backend do state](#backend-do-state))

## Variáveis

| Nome | Obrigatória | Default | Descrição |
|---|---|---|---|
| `aws_region` | não | `us-east-1` | Região AWS |
| `db_identifier` | não | `oficina-mecanica-db` | Identifier da instância RDS |
| `db_name` | não | `oficina_mecanica_db` | Nome do banco criado dentro da instância |
| `db_username` | **sim** | — | Usuário master. **Não pode ser uma palavra reservada do engine** (ex.: `postgres`, `rdsadmin`) |
| `db_password` | **sim** | — | Senha master (sensível) |
| `db_port` | não | `5432` | Porta do PostgreSQL |
| `db_instance_class` | não | `db.t3.micro` | Classe da instância RDS |

`db_username` e `db_password` são `sensitive` e não têm default — precisam ser passados via `-var`, `terraform.tfvars` (fora do controle de versão) ou variável de ambiente `TF_VAR_*`.

## Backend do state

O bucket S3 do backend remoto não fica fixo no [backend.tf](backend.tf) — é injetado em tempo de `terraform init` via `-backend-config`, para usar a mesma conta/bucket configurados no repositório (padrão espelhado do `k8s-infra-oficina-mecanica`). A variável do GitHub Actions é `TF_STATE_BUCKET` (Settings → Secrets and variables → Actions → Variables).

## Como rodar

### Local

```bash
terraform init -backend-config="bucket=<nome-do-bucket>"
terraform plan -var="db_username=<usuario>" -var="db_password=<senha>"
terraform apply -var="db_username=<usuario>" -var="db_password=<senha>"
```

### Via GitHub Actions

Dois workflows manuais (`workflow_dispatch`), usando os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `POSTGRES_USER`, `POSTGRES_PASSWORD` e a variável `TF_STATE_BUCKET`:

- [`Deploy Database`](.github/workflows/db.yaml) — `terraform apply` e, ao final, dispara um `repository_dispatch` (`db-deployed`) para o `k8s-infra-oficina-mecanica` com host/porta/nome do banco
- [`Destroy Database`](.github/workflows/db-destroy.yaml) — `terraform destroy`, apaga a instância **sem snapshot final** (ambiente de lab)

## Outputs

| Output | Descrição |
|---|---|
| `db_host` | Hostname da instância RDS |
| `db_port` | Porta do PostgreSQL |
| `db_name` | Nome do banco |
| `db_endpoint` | Endpoint completo (`host:porta`) |
