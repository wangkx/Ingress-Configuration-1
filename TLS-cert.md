# Create an HTTPS ingress controller and use your own TLS certificates on AKS
First deploy the NGINX ingress controller in an Azure Kubernetes Service (AKS) cluster.
Then, generate certificates, and create a Kubernetes secret for use with the ingress route. 
Two applications are run in the AKS cluster, both accessible over one IP address.
* Have Azure [CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.0.64 or later installed and running
* Install the latest release of [Helm](https://helm.sh/docs/intro/install/).
* Create the Nginx controller with Helm
## Create an Ingress Controller

```
# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```
Azure public IP address is created for the ingress controller.
```
kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller

```
## Generate TLS certificates
Generate a self-signed certificate with openssl.
*For production use, specify your own organizational values for the -subj parameter,
also request a trusted, signed certificate through a provider or your own certificate authority (CA)*
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    #-subj "/CN=hpcc.azure.com/O=aks-ingress-tls"
```
## Create Kubernetes secret for TLS certificate
To allow Kubernetes to use the TLS certificate and private key for the ingress controller, create and use a Secret.
 The secret is defined once, and uses the certificate and key file created in the previous step. You then reference this secret when you define ingress routes.

The following example creates a Secret name aks-ingress-tls:
```
kubectl create secret tls <name> \
    --key hpcc-secret.key \ # key file created in previous step
    --cert hpcc-secret.crt # certificate created in pervious step
 ```
## Run Application
Open this file, name tls-cert.yaml.  Eclwatch is the name of the service.
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
Create the service using:
```
kubectl apply -f tls-cert.yaml
```
## Create an Ingress route
Use regex, regular expression annotation.
Traffic to the address https://hpcc.azure.com/ is routed to the service named eclwatch.  The tls section tells the ingress route to use the Secret named hpcc-secret for the host hpcc.azure.com

Open a file, name it: tls-ingress.yaml
```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    #nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - hpcc.azure.com
    secretName: hpcc-secret
  rules:
  - host: hpcc.azure.com
    http:
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
# create an ingress resource
$ kubectl apply -f tls-ingress.yaml
# example output
ingress.extensions/eclwatch-ingress created
```

## Test the Ingress Configuration
Test the certificates, allows you to map host name hpcc.azure.com to Public IP address of your Ingress controller.  Specify the external IP address below.
```
curl -v -k --resolve hpcc.azure.com:443:EXTERNAL_IP https://azure.azure.com

```
The -v parameter in the curl command outputs verbose information, including the TLS certificate received. Half-way through your curl output, you can verify that your own TLS certificate was used. The -k parameter continues loading the page even though we're using a self-signed certificate.

# Clean up resources
List the Helm releases with the helm list command.
```
helm list
```
Look for chart named nginx-ingress
```
$ helm list
NAME                    
nginx-ingress
```
Uninstall this release using:
```
helm uninstall nginx-ingress
```
Delete the releases with the helm uninstall command.
```
kubectl delete -f tls-ingress.yaml
kubectl delete -f tls-cert.yaml
```
