# Create an Ingress rule for User/Pass Authentication

Protect an Application (eclWatch) with basic authentication, behind NGINX

# Prerequisites
First, install homebrew [here](https://brew.sh).  Then install wget

```
brew install wget
```     

### Create NGINX Controller
```
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml

```
The output should be similar to :
```
20XX-XX-XX 10:27:35 (5.61 MB/s) - ‘deploy.yaml’ saved [18333/18333] 

```
open the file above, and modify type: from LoadBalancer to NodePort
``` 
vi deploy.yaml 

```
Create the controller:
``` 
kubectl apply -f deploy.yaml

```
## Create application
Create application and service
Open a file named eclwatch-ingress.yaml

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
```
kubectl apply -f eclwatch-ingress.yaml

```
## Create a Password file 
contains username and password for users

```
htpasswd -c auth <username>

```
Generate a password when prompted. Run:
```
cat auth

```
to see the password that is generated.

## Use a file to create Ingress rule
This file protects the application.  

```
kubectl create secret generic basic-auth --from-file=auth

``` 
Then, create the ingress rule.
```
nano ingress-rule.yaml

```
```YAML

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/auth-type: basic # Specifiying basic authentication
    nginx.ingress.kubernetes.io/auth-secret: basic-auth # name of secret
    nginx.ingress.kubernetes.io/auth-realm: "Authetnication required"
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
```
kubectl apply -f ingress-rule.yaml
```

**Run 'kubectl get secret', which should show the basic authentication created**
```
kubectl get svc -n ingress-nginx

```
Go to the external IP for the specified service that will be protected, it will prompt for user and password.
