# Create an Ingress Controller in AKS
Using NGINX controller in AKS cluster
### Prerequisites:
* Have latest release of Helm (Helm 3) installed
* Have access to ingress-nginx repository
* Run Azure CLI version 2.0.64 or later

## Create a controller
Add Ingress-nginx repository
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

```
Use helm to deploy an Ingress NGINX controller

```
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --set controller.replicaCount=2 \ (Kevin? explain replicaCount=2)
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \ (Kevin? explain beta\.kubernetes\.io/os"=linux)
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux

```
Dynamic public IP is assigned when the load balancer is created.  Get the address using:
```
 kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller
 
 (Kevin? show an example as in HTTP Application Routing doc)

```
## Deploy Instance of an application

create a yaml file, copy in the following: (Kevin? Ex. eclwatch-ingress.yaml)
```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  -  http:
      paths:
      - path: /
        pathType: Prefix
        backend:
         service:
           name: eclwatch
           port:
             number: 8010

```
create the ingress resource using: 
```
kubectl apply -f <file> (Kevin? using eclwatch-ingress.yaml)

```
## Test the Ingress controller
Open a web browser, enter the external IP address of your NGINX controller
The application will be displayed in the web browser
(Kevin? Show ex.: http://IP:8010)

## Delete resources
```
helm list --namespace ingress-basic

helm uninstall nginx-ingress

kubectl delete -f <file> (Kevin? using eclwatch-ingress.yaml)

```

