# NGINX Rate Limiting
Allows you to limit the amount of HTTP requests a user can make in a given amount of time.  Used to mitigated DDoS attacks.  
## Apply annotations
Open a file, name it eclwatch-ratelimit.yaml ?Should be 'Create an Ingress configuration file with a name, ex. eclwatch-ratelimit.yaml'. You may want to mention that eclwatch is the application service you want to use. The 8010 is the port of the service. The eclwatch-ingress is the name of the Ingress control. Please use the same style in other docs.

```
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
? Should you add the following annotations below into the eclwatch-ratelimit.yaml? You may explain them as shown below.

Apply the annotation below to limit the number of requests from a given IP per second.  If the limit is exceeded, the user receives limit-req-status-code default: 503.
The burst limit is set to this limit multiplied by the burst multiplier.


```
nginx.ingress.kubernetes.io/limit-rps: "integer"

```
Use the annotation below to limit the number of requests from a given IP per minute.  If the limit is exceeded, the user receives limit-req-status-code default: 503.
The burst limit is set to this limit multiplied by the burst multiplier.

```
nginx.ingress.kubernetes.io/limit-rpm

```

Multiplier of rate limit for burst size.  The default is "5", so the annotation below will override the default.

```
nginx.ingress.kubernetes.io/limit-burst-multiplier

```

```
kubectl apply -f eclwatch-ratelimit.yaml

```

Tested the annotations by visiting the same IP address using two web browsers after setting rpm to "1".  One web browser's request is accepted, the other returns "503".
