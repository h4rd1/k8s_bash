
Сделанно для RED OS 7.3
 
 Полезные для работы команды:

    kubectl delete node <имя_ноды> - удалить ноду;
    
    kubectl get nodes - посмотреть детальную информацию о количестве нод в кластере и их роли;

    kubectl exec -it nginx -- /bin/bash - выполнить вход в виртуальную консоль;

    kubectl delete pods <имя_пода> - удалить под;

    kubectl get pod -o wide - детальная информация о подах;

    kubectl get service --all-namespaces - подробная информация о сервисах;

    kubeadm token create --print-join-command  - токен для подключения;

    kubectl get pod -n kube-system - проверка старта всех систем k8s;

    kubectl run nginx --image=nginx - создание пода nginx;

    kubectl get pod -o wide - посмотреть детальную информацию о поде;
    

   ![изображение](https://github.com/user-attachments/assets/c3adb115-e657-4ee7-bfc0-2ed43857445c)






