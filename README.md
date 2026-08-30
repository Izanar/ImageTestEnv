# ImageTestEnv

В этом репозитории два сценария:

1. Manual EKS path — ручной вариант для реального Kubernetes
2. Push-triggered EC2 path — автоматический вариант для дешёвого и быстрых demo

## 1. Ручной вариант: EKS

Это правильный Kubernetes-вариант. Он показывает, как в реальном проекте можно создать EKS-кластер и задеплоить приложение.

Файлы:

- [terraform-eks/main.tf](terraform-eks/main.tf)
- [terraform-eks/variables.tf](terraform-eks/variables.tf)
- [terraform-eks/outputs.tf](terraform-eks/outputs.tf)
- [kubernetes/namespace.yaml](kubernetes/namespace.yaml)
- [kubernetes/deployment.yaml](kubernetes/deployment.yaml)
- [kubernetes/service.yaml](kubernetes/service.yaml)
- [kubernetes/ingress.yaml](kubernetes/ingress.yaml)

Как запустить вручную:

```bash
cd terraform-eks
terraform init
terraform validate
terraform plan
terraform apply
```

После apply можно обновить kubeconfig:

```bash
aws eks update-kubeconfig --region eu-central-1 --name $(terraform output -raw cluster_name)
```

Потом применить манифесты:

```bash
kubectl apply -f ../kubernetes/namespace.yaml
kubectl apply -f ../kubernetes/deployment.yaml
kubectl apply -f ../kubernetes/service.yaml
kubectl apply -f ../kubernetes/ingress.yaml
```

Проверить:

```bash
kubectl get pods -n weather-demo
kubectl get svc -n weather-demo
```

Удалить всё:

```bash
terraform destroy
```

Это рабочий Kubernetes шаблон и основной “правильный” путь для кластера.

## 2. Автоматический вариант: EC2 после пуша

Это основной CI/CD сценарий для demo. Он запускает инфраструктуру и приложение автоматически после каждого пуша в main.

Файлы:

- [.github/workflows/aws-weather-deploy.yml](.github/workflows/aws-weather-deploy.yml)
- [terraform/main.tf](terraform/main.tf)
- [terraform/variables.tf](terraform/variables.tf)
- [ansible/playbook.yml](ansible/playbook.yml)

Что происходит при push:

1. GitHub Actions запускает workflow
2. Terraform создаёт один EC2 instance
3. Ansible настраивает nginx
4. приложение публикуется на VM
5. делается smoke test
6. через 10 минут инфраструктура удаляется автоматически

То есть это именно “пуш → создать инстанс → сайт работает → удалить всё”.

Это самый дешёвый и безопасный вариант для демонстрации CD/CD и проверки infrastructure as code без долгого удержания ресурсов.

## Почему автоматический сценарий не k3s

Потому что в этом проекте автоматический сценарий должен быть чисто EC2 и дешёвым. k3s для push-демо не нужен, потому что он усложняет схему и не даёт ничего принципиально полезного при условии “не тратить деньги”.

## Почему Terragrunt здесь

Файл [terragrunt/terragrunt.hcl](terragrunt/terragrunt.hcl) — это обёртка над Terraform, а не отдельный способ деплоя. Он нужен как шаблон env-defaults и стандартизированных параметров для окружений.

## Требования

- AWS account
- Terraform 1.8.5+
- AWS CLI configured
- GitHub Secrets for AWS and SSH keys
- kubectl for the EKS path
- optional Terragrunt if you want to use the wrapper

## Важно

- Ручной сценарий — EKS, это реальный Kubernetes путь
- Автоматический сценарий — EC2, это дешёвый и быстрый demo-путь
- Для production лучше использовать EKS, но для бесплатного теста и автодестроя оптимален EC2

## Структура репозитория

```text
ImageTestEnv/
├── .github/
│   └── workflows/
│       └── aws-weather-deploy.yml
├── ansible/
│   └── playbook.yml
├── kubernetes/
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── terraform-eks/
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── versions.tf
├── terragrunt/
│   └── terragrunt.hcl
├── .gitignore
├── README.md
└── .gitignore
```