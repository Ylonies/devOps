# devOps 
## ДЗ #1: «Фундамент DevOps инфраструктуры»

### Развертывание инфраструктуры

1. Перейдите в директорию с Terraform

```bash
cd terraform
```

2. Инициализируйте проект:

```bash
terraform init
```

3. Проверить и утсановить план:

```bash
terraform plan -out=tfplan
```

4. Применить сохраненный план
   
```bash

terraform apply tfplan
```

### Запуск Ansible Playbook 
```bash
ansible-playbook -i inventory.ini setup_host.yml
```

### Проверка робоспособности

```bash
curl -i http://111.88.162.98
```




