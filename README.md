 Полезные для работы команды:

    kubectl delete node <имя_ноды> - удалить ноду;

    kubectl exec -it nginx -- /bin/bash - выполнить вход в виртуальную консоль;

    kubectl delete pods <имя_пода> - удалить под;

    kubectl get pod -o wide - детальная информация о подах;

    kubectl get service --all-namespaces - подробная информация о сервисах.

    kubeadm token create --print-join-command  - токен для подключения 

    kubectl get pod -n kube-system - проверка старта всех систем k8s





