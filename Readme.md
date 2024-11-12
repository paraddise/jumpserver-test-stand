
Это тестовое окружение для jumpserver.
Описан Vagrantfile в котором разворачивается куб. Туда нужно задеплоить cilium, ingress, kubevirt, postgres, redis и jumpserver.

Через kubevirt создается вмка, их можно создать несколько.

Был использован vagrant потому что нужна ВМ для запуска kubevirt, на MacOS kind,minikube,etc kubevirt не запустит новую машину.

## Запуск

```bash
vagrant up
vagrant dns --install
# ждем запуска и пока не появится kubeconfig
# Устанавливаем пока плагин
make install-krew-virt
# или можно установить virtctl
# make install-virtctl

# Kubernetes basic setup
export KUBECONFIG=./kubeconfig
make install-cilium
make install-ingress
make install-lpp

# Устанавливаем kubevirt и создаем вмки
./install-kubevirt.sh
make configure-kubevirt
make create-vms

# Jumpserver
make build
make deploy # каждый бандл
```

## Что не описано

При первом запуске куб не поднимается и будет ошибка что превышен лимит указанных DNS серверов, это потому что указывается более 3 серверов и куб не может вставить еще один свой. Для этого нужно удалить днс сервера из `/etc/netplan` и `/etc/systemd/resolve.conf`.

Не описано создание ассетов и пользователей jumpserver.
Там создаются ассеты:
- kubernetes, в котором задеплоен сам jumpserver, токен берется из бандла `04.ko-token`
- postgresql, который использует сам jumpserver
- testvm-ssh, доступ к машине развернутой с kubevirt
- redis, которым пользуется сам jumpserver

