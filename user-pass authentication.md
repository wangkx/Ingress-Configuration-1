# Create an Ingress rule for User/Pass Authentication

Add an authentication in an Ingress rule using a secret that generates a file with *htpasswd*

## Prerequisites
First, install homebrew [here](https://brew.sh).  Then install wget ?Use bullet

```
brew install wget
```     
* Run the latest version of Helm
**Deploy NGINX controller** ?in other documents, I saw different titles like "Add Ingress-nginx repository, ...". We should use the same terms. ?add new line for option 1
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
Option 3: Download the file with wget:

```
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml

```
*Create the controller and dependencies:* ?not clear this is for option 3 only or not
``` 
kubectl apply -f deploy.yaml

```

## Create service ?in other documents, I saw different titles like "Deploy Instance of an application ...". We should use the same terms.
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
contains username and password for users ?no subject

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
```?Add a line to describe what you do next
nano ingress-rule.yaml

```
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
Apply ?add 'the ingress-rule.yaml'. In your documents, there are many places for 'kubectl apply'. You should use the same style for the explainations.
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
* auth-map - the keys of the secret are the usernames, and the values are the hashed passwords ?Can we give some examples for auth-map

```
nginx.ingress.kubernetes.io/auth-secret-type: [auth-file|auth-map]
```

