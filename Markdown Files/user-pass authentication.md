# Create an Ingress rule for Basic Authentication- Nginx

Add an authentication in an Ingress rule using a secret that generates a file with *htpasswd*

## Prerequisites
* First, install homebrew [here](https://brew.sh).  
* Then install wget

```
brew install wget
```     
* Run the latest version of Helm
**Add NGINX repository**
Option 1: using Helm:
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx
```
Option 2: Docker Desktop:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml
```
Option 3, Step 1: Download the file with wget:

```
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml

```
*Step 2:*
``` 
kubectl apply -f deploy.yaml

```

## Deploy instance of an application
Create service
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
File 'auth' contains username and password for users

```
htpasswd -c auth user1

```
Generate a password when prompted. 

***

Display contents of auth file:

```
cat auth

```
## Create a secret
basic-auth secret is used for credentials for basic authentication
```
kubectl create secret generic basic-auth --from-file=auth

``` 
## Create ingress rule
Protect the application
* Applying annotations to protect the service in spec
* Open the yaml file, named ingress-rule.yaml
```
nano ingress-rule.yaml

```
* Add annotations to specify basic authentication and name of secret
```YAML

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/auth-type: basic # Specifiying type: basic authentication
    nginx.ingress.kubernetes.io/auth-secret: basic-auth # name of secret that contains user/passwd definitions
    nginx.ingress.kubernetes.io/auth-realm: "Authetnication required" # message to display with an appropriate context why the authentication is required
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
Deploy the application using "kubectl apply"
```
kubectl apply -f ingress-rule.yaml
```
## Test rule
Get external IP address
```
kubectl get svc -n ingress-nginx

```
Go to the external IP for the specified service that will be protected, it will prompt for user and password.
If "cancel" is clicked or user/pass is incorrect, 401 Authorization error is returned.



# Additional annotations
### Use Whitelisting
Specify allowed client IP source ranges through the annotation:
```
nginx.ingress.kubernetes.io/whitelist-source-range:

```
The value is a comma separated list of CIDRs, e.g. **10.0.0.0/24,172.10.0.1**.
When an IP address not specified in the annotation tries to access the IP address,
403 forbidden error is returned.

### Authentication for multiple users
The auth-secret can have two forms:

* auth-file - default, an htpasswd file in the key auth within the secret
* auth-map - the keys of the secret are the usernames, and the values are the hashed passwords

```
nginx.ingress.kubernetes.io/auth-secret-type: [auth-file|auth-map]
```

