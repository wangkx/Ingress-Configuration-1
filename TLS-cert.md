# Create an HTTPS ingress controller and use your own TLS certificates on AKS
First deploy the NGINX ingress controller in an Azure Kubernetes Service (AKS) cluster.
Then, generate certificates, and create a Kubernetes secret for use with the ingress route. 
Two applications are run in the AKS cluster, both accessible over one IP address.
* Run Azure [CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.0.64 or later
* Use the latest release of [Helm](https://helm.sh/docs/intro/install/).

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
```
kubectl create secret tls <name> \
    --key hpcc-secret.key \
    --cert hpcc-secret.crt
 ```
 ?What are hpcc-secret.key and hpcc-secret.key? You may need to explain them here.
## Run Application
Open this file, name tls-cert.yaml
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
$ kubectl apply -f tls-ingress.yaml ?Do we need to apply both tls-ingress.yaml and tls-cert.yaml
# example output ?Showing example output is a good idea. We may need to try that for every places when you run a conmmand. 
ingress.extensions/eclwatch-ingress created
```

## Test the Ingress Configuration
Test the certificates, allows you to map host name hpcc.azure.com to Public IP address of your Ingress controller.  Specify the external IP address below.
```
curl -v -k --resolve hpcc.azure.com:443:EXTERNAL_IP https://azure.azure.com

```
The -v parameter in the curl command outputs verbose information, including the TLS certificate received. Half-way through your curl output, you can verify that your own TLS certificate was used. The -k parameter continues loading the page even though we're using a self-signed certificate.

# Clean up resources
```
helm list ?Should you explain the result of this command and what you need from the result? Do the same for other documents.
```
Uninstall the releases with the helm uninstall command.
Remove the sample applications: ?Should we change it to 'Release the resources using the helm uninstall command.'  Do the same for other documents.
```
kubectl delete -f tls-ingress.yaml
kubectl delete -f tls-cert.yaml
```
