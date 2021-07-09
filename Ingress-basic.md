# Create an Ingress Controller in AKS
Using Nginx controller and ingress rules, a single IP address can be used to route traffic to multiple services in a Kubernetes cluster.
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
    --set controller.replicaCount=2 \ # two replicas of the NGINX ingress controllers are deployed 
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux

```
Dynamic public IP is assigned when the load balancer is created.  Get the address using:
```
 kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller

```
## Deploy Instance of an application

create a yaml file named eclwatch-ingress.yaml, copy in the following:
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
kubectl apply -f eclwatch-ingress.yaml

```
## Create an Ingress route
The application is now running on your Kubernetes cluster. To route traffic to each application, create a Kubernetes ingress resource. The ingress resource configures the rules that route traffic to one of the two applications.

In the following example, traffic to EXTERNAL_IP is routed to the service named eclwatch. Traffic to EXTERNAL_IP/static is routed to the service named eclwatch for static assets.

Create a file named route-ingress.yaml and copy in the following example YAML:

```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - http:
      paths:
      - path: /(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: eclwatch
            port:
              number: 8010
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /static/$2
spec:
  rules:
  - http:
      paths:
      - path:
        pathType: Prefix
        backend:
          service:
            name: eclwatch
            port: 
              number: 8010
        path: /static(/|$)(.*)
```

## Test the Ingress controller
Open a web browser, enter the external IP address of your NGINX controller.  

To get the external IP address:
```
kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller
```

Then, the application will be displayed in the web browser.

## Delete resources
```
helm uninstall nginx-ingress

kubectl delete -f eclwatch-ingress.yaml

```

