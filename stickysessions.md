# Sticky Sessions for Ingress NGINX controller
Achieve session affinity using cookies

# Prerequisites

__TLS certificates:__
Create a TLS secret and certificate using:
```
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"

kubectl create secret tls tls-secret --key tls.key --cert tls.crt
```
__CA Authentication__
To access the backend, client certificate must be passed:
*Generate the CA Key and Certificate:*
```
openssl req -x509 -sha256 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=My Cert Authority'

```
*Generate the Server key and cerficiate.  Sign in with CA Certificate:*
```
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=mydomain.com'

openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt

```
*Generate the Client Key and Certficate signin:*
```
openssl req -new -newkey rsa:4096 -keyout client.key -out client.csr -nodes -subj '/CN=My Client'
openssl x509 -req -sha256 -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out client.crt

```
After completing CA Authentication, follow the instructions [linked here](https://kubernetes.github.io/ingress-nginx/examples/auth/client-certs/#creating-certificate-secrets)
*Test HTTP Service*
```
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/docs/examples/http-svc.yaml
service "http-svc" created
replicationcontroller "http-svc" created

$ kubectl get po
NAME             READY     STATUS    RESTARTS   AGE
http-svc-p1t3t   1/1       Running   0          1d

$ kubectl get svc
NAME             CLUSTER-IP     EXTERNAL-IP   PORT(S)            AGE
http-svc         10.0.122.116   <pending>     80:30301/TCP       1d

```
Test if the HTTP Service works by exposing it temporarily:
```
$ kubectl patch svc http-svc -p '{"spec":{"type": "LoadBalancer"}}'
"http-svc" patched

$ kubectl get svc http-svc
NAME             CLUSTER-IP     EXTERNAL-IP   PORT(S)            AGE
http-svc         10.0.122.116   <pending>     80:30301/TCP       1d

$ kubectl describe svc http-svc
Name:                   http-svc
Namespace:              default
Labels:                 app=http-svc
Selector:               app=http-svc
Type:                   LoadBalancer
IP:                     10.0.122.116
LoadBalancer Ingress:   108.59.87.136
Port:                   http    80/TCP
NodePort:               http    30301/TCP
Endpoints:              10.180.1.6:8080
Session Affinity:       None
Events:
  FirstSeen LastSeen    Count   From            SubObjectPath   Type        Reason          Message
  --------- --------    -----   ----            -------------   --------    ------          -------
  1m        1m      1   {service-controller }           Normal      Type            ClusterIP -> LoadBalancer
  1m        1m      1   {service-controller }           Normal      CreatingLoadBalancer    Creating load balancer
  16s       16s     1   {service-controller }           Normal      CreatedLoadBalancer Created load balancer

$ curl 108.59.87.136
CLIENT VALUES:
client_address=10.240.0.3
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://108.59.87.136:8080/

SERVER VALUES:
server_version=nginx: 1.9.11 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=108.59.87.136
user-agent=curl/7.46.0
BODY:
-no body in request-

$ kubectl patch svc http-svc -p '{"spec":{"type": "NodePort"}}'
"http-svc" patched

```

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

