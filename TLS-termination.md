# TLS termination
Terminate HTTPS traffic from clients, relieving your upstream web and application servers of the computational load of SSL/TLS encryption.

This example demonstrates how to terminate TLS through the ingress-nginx controller.

## Prerequisites
* Have a running Kubernetes cluster
* Create a TLS certificate
* Have the NGINX controller installed

1. Creating a TLS certificate

OpenSSL is a tool that allows you to create self-signed certificates for opening a TLS encrypted connection. 
The openssl command below will create a create a certificate and private key pair for TLS termination.

Create a private key and certificate:

```
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"

Generating a 2048 bit RSA private key
................+++
................+++
writing new private key to 'tls.key'
-----
```
2. Store the certificate and key in a Kubernetes Secret
```
$ kubectl create secret tls tls-secret --key tls.key --cert tls.crt

secret "tls-secret" created
```

3. Installing the NGINX Controller

This [tutorial](https://github.com/amy88ma/Ingress-Configuration/blob/c9779567dca7f49b22ef6a8039edc0acdfcdb30d/Deployment/Nginx_Install%20(1).ipynb) shows how to install the NGINX controller needed for the example.
## Deployment
Now that you have stored your certificate and private key in a Kubernetes secret named tls-secret, you need to tell the service to use this certificate for terminating TLS on a domain.

Create ```hpcc-ingress.yaml``` file, to use the secret created previously for terminating TLS on all domains.
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hpcc-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  tls:
    - hosts:
      secretName: tls-secret
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /eclwatch(/|$)(.*)
      - backend:
          serviceName: eclqueries
          servicePort: 8002
        path: /eclqueries(/|$)(.*)
      - backend:
          serviceName: esdl-sandbox
          servicePort: 8899
        path: /esdl(/|$)(.*)
      - backend:
          serviceName: sql2ecl
          servicePort: 8510
        path: /wssql(/|$)(.*)
      - backend:
          serviceName: eclservices
          servicePort: 8010
        path: /(.*)
```
The following command instructs the controller to terminate traffic using the provided TLS cert, and forward un-encrypted HTTP traffic to an HTTP service:
```
kubectl apply -f hpcc-ingress.yaml
```
Hpcc-ingress is now configured to terminate TLS using the self-signed certificate.
## Validation
You can confirm that the Ingress works:
```
$ kubectl describe ing hpcc-ingress
Name:             hpcc-ingress
Namespace:        default
Address:          20.190.209.141
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
TLS:
  tls-secret terminates 
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /eclwatch(/|$)(.*)     eclwatch:8010 (10.244.0.8:8888)
              /eclqueries(/|$)(.*)   eclqueries:8002 (10.244.0.13:8880)
              /esdl(/|$)(.*)         esdl-sandbox:8899 (10.244.1.13:8880)
              /wssql(/|$)(.*)        sql2ecl:8510 (10.244.1.10:8880)
              /(.*)                  eclservices:8010 (10.244.1.5:8880)
Annotations:  kubernetes.io/ingress.class: nginx
              nginx.ingress.kubernetes.io/rewrite-target: /$1
              nginx.ingress.kubernetes.io/use-regex: true
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    27m (x2 over 28m)  nginx-ingress-controller  Scheduled for sync


```
Note: 

Since you are using a self-signed certificate, you must set the -k flag in curl to disable hostname validation.

send a request to your backend service with curl:

```curl -Lk https://20.190.209.141/backend/```

## Next Steps:
Get a valid certificate from a certificate authority
While a self-signed certificate is a simple and quick way to terminate TLS. In order to serve HTTPS traffic without being returned a security warning, you will need to get a certificate from an official Certificate Authority like Let's Encrypt.

For the Open-Source API Gateway, Jetstack's cert-manager provides a simple way to manage certificates from Let's Encrypt. 

To configure Jetstack cert-manager for HPCC TLS: [link](https://github.com/amy88ma/Ingress-Configuration/blob/dc5a5a06fb670d424e629899b2ac106b3339316a/Jupyter%20Notebooks/HPCC_TLS.ipynb)
