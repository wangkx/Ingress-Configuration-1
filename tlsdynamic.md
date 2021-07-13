# Use TLS with Let's Encrypt
Use a dynamic public IP address to create an HTTPS ingress controller on AKS
## Prerequisites:
* Install Helm 
* Use Helm to create an ingress controller
[Link for how to install](https://github.com/amy88ma/Ingress-Configuration/blob/fca7ab129e0e384efe5943d0bd7d4113c0f1b58e/Jupyter%20Notebooks/Install-NGINX.ipynb) the above.
* [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
#### Create an Ingress controller
Use Helm to deploy an NGINX ingress controller

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```
An Azure public IP address will be created for the ingress controller.  To get this public IP address, use
```bash
kubectl get service
```

## Configure an FQDN for the ingress controller IP address
Adds a record to the DNS zone
```bash
# Public IP address of your ingress controller
IP="20.75.130.86"

# Name to associate with public IP address
DNSNAME="ecl-aks-ingress"

# Get the resource-id of the public ip
PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)

# Update public ip address with DNS name
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME

# Display the FQDN
az network public-ip show --ids $PUBLICIPID --query "[dnsSettings.fqdn]" --output tsv

```

## Install cert-manager
The NGINX ingress controller supports TLS termination. There are several ways to retrieve and configure certificates for HTTPS. This demonstrates using cert-manager, which provides automatic Lets Encrypt certificate generation and management functionality.

To install the cert-manager controller,

First add the Jetstack Helm repository:
```
helm repo add jetstack https://charts.jetstack.io
```
Update local Helm chart repository cache:
```
helm repo update
```

Then install cert-manager using Helm chart:
```
helm install cert-manager jetstack/cert-manager \
  --set installCRDs=true \
  --set nodeSelector."kubernetes\.io/os"=linux \
  --set webhook.nodeSelector."kubernetes\.io/os"=linux \
  --set cainjector.nodeSelector."kubernetes\.io/os"=linux
```

## Creating a CA cluster issuer
Before certificates can be issued, cert-manager requires an Issuer or ClusterIssuer resource. These Kubernetes resources are identical in functionality, however Issuer works in a single namespace, and ClusterIssuer works across all namespaces. 

Create a cluster issuer file, with the name cluster-issuer.yaml, using the following example manifest. Replace the email address with a valid address from your organization:

```YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: MY_EMAIL_ADDRESS
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
```
To create the issuer:
```bash
kubectl apply -f cluster-issuer.yaml
```
## Run the application
An ingress controller and a certificate management solution have been configured, applications can be run.  Create a file with the name "eclwatch.yaml", the service that will be created is eclwatch
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
---
apiVersion: v1
kind: Service
metadata:
  name: eclwatch
spec:
  type: ClusterIP
  ports:
  - port: 8010
```

## Creating an Ingress route
Create a file using the below example YAML named *example-ingress.yaml*. Replace the host and hostnames with FQDN name created previously.

```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    #nginx.ingress.kubernetes.io/ssl-redirect: "false"
    #nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - hpcc.eastus.cloudapp.azure.com
    secretName: aks-ingress-tls

  rules:
  - host: hpcc.eastus.cloudapp.azure.com
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
Create the ingress resource using 'kubectl apply' command.
```bash
kubectl apply -f example-ingress.yaml
```
## Verify the certificate object has been created

```
kubectl get certificate
```
Use this command to verify that *READY* is *True*.

## Test the ingress configuration

Test this configuration by opening a web browser, and go to the FQDN server of the controller.

```
https://hpcc.eastus.cloudapp.azure.com
```

The result should show that a valid certificate is created and the page is secure.
## Clean up Resources

Delete resources indiviudally:

```
kubectl delete -f cluster-issuer.yaml

helm uninstall cert-manager nginx

kubectl delete -f example-ingress.yaml
```
