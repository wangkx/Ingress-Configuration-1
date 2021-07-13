# NGINX Rate Limiting
Allows you to limit the amount of HTTP requests a user can make in a given amount of time.  Used to mitigated DDoS attacks.  
## Prerequisites
* Install Helm
* Create the Nginx controller with Helm
To install the above [prerequisites](http://localhost:8888/notebooks/Install-NGINX.ipynb)
## Apply annotations in ingress file
Create Ingress Configuration file with name "eclwatch-ratelimit".yaml
Ecl watch is the name of the service that will be used in the following example.

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/limit-rps: "integer"
    nginx.ingress.kubernetes.io/limit-burst-multiplier: "integer"

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
             number: 8010 # Port of the service 'eclwatch'
             
```

The burst limit is set to this limit multiplied by the burst multiplier.


```
nginx.ingress.kubernetes.io/limit-rps: "integer"

```
Use the annotation below to limit the number of requests from a given IP per minute.  If the limit is exceeded, the user receives limit-req-status-code default: 503.
The burst limit is set to this limit multiplied by the burst multiplier.

```
nginx.ingress.kubernetes.io/limit-rpm:

```

Multiplier of rate limit for burst size.  The default is "5", so the annotation below will override the default.

```
nginx.ingress.kubernetes.io/limit-burst-multiplier:

```

```
kubectl apply -f eclwatch-ratelimit.yaml

```

Tested the annotations by visiting the same IP address using two web browsers after setting rpm to "1".  One web browser's request is accepted, the other returns "503".

