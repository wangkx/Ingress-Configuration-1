# Sticky Sessions for Ingress NGINX controller
Achieve session affinity using cookies


## Deployment
Use the following annotations to configure session affinity:
```
nginx.ingress.kubernetes.io/affinity: "cookie"

```
Use the above command to enable session affinity

```
nginx.ingress.kubernetes.io/affinity-mode: "persistent"

```
"balanced" is the default.  This mode defines how sticky the session is.  Defauly is used to redistrubute some sessions when scaling pods.$
```
nginx.ingress.kubernetes.io/session-cookie-name

```
Name of the cookie to be created, default is INGRESSCOOKIE

```
nginx.ingress.kubernetes.io/session-cookie-path

```
This path will be set on the cookie, required if your ingress path use regular expressions.


```
nginx.ingress.kubernetes.io/session-cookie-max-age: " "

```
Define time until cookie expires in seconds.


```
nginx.ingress.kubernetes.io/session-cookie-change-on-failure

```
When set to *false* ingress, will send request to upstream pointed by sticky cookie even if previous attempt failed.  When set to *true* ,$


## Create a file to test the annotations
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    ANNOTATIONS HERE

spec:
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /
        pathType: Prefix
```
```
kubectl apply -f <file-name>

```

## Validation
```
kubectl describe ing nginx-test

```
Use this command to confirm that the Ingress works

The output should be similar to:
```
Name:           nginx-test
Namespace:      default
Address:
Default backend:    default-http-backend:80 (10.180.0.4:8080,10.240.0.2:8080)
Rules:
  Host                          Path    Backends
  ----                          ----    --------
  stickyingress.example.com
                                /        nginx-service:80 (<none>)
Annotations:
  affinity: cookie
  session-cookie-name:      INGRESSCOOKIE
  session-cookie-expires: 172800
  session-cookie-max-age: 172800
Events:
  FirstSeen LastSeen    Count   From                SubObjectPath   Type        Reason  Message
  --------- --------    -----   ----                -------------   --------    ------  -------
  7s        7s      1   {nginx-ingress-controller }         Normal      CREATE  default/nginx-test

```

```
curl -I http://<IP_ADDRESS>

```
The output should be similar to:
```
HTTP/1.1 200 OK
Server: nginx/1.11.9
Date: Fri, 10 Feb 2017 14:11:12 GMT
Content-Type: text/html
Content-Length: 612
Connection: keep-alive
Set-Cookie: INGRESSCOOKIE=a9907b79b248140b56bb13723f72b67697baac3d; Expires=Sun, 12-Feb-17 14:11:12 GMT; Max-Age=172800; Path=/; HttpOnly
Last-Modified: Tue, 24 Jan 2017 14:02:19 GMT
ETag: "58875e6b-264"
Accept-Ranges: bytes

```

