# Microservices build & deploy notes

## Build images
Build images locally (consider using buildx for multi-arch builds — see Troubleshooting).
```

docker build -t patient-service:latest .
docker build -t application-service:latest .
docker build -t order-service:latest .
```

## Local image listing (example)
```
REPOSITORY           TAG     IMAGE ID       CREATED         SIZE
patient-service      latest  3c391a50af42   3 minutes ago   136MB
order-service        latest  dedf75859667   8 minutes ago   341MB
application-service  latest  7286a207ed7f   34 minutes ago  133MB
```

## Run containers (note port conflicts)
Avoid starting two containers on the same host port.
```
docker run -d -p 3000:3000 --name patient-service patient-service:latest
docker run -d -p 8080:8080 --name order-service order-service:latest
# Do not run another container with -p 3000:3000 unless you change the host port
```
<img width="1015" height="177" alt="image" src="https://github.com/user-attachments/assets/6670ac14-6da7-4f2d-a953-f840bd7d6d66" />
<img width="1379" height="186" alt="image" src="https://github.com/user-attachments/assets/6d0403ce-7125-4ef3-9967-27a2c484ea0e" />
<img width="1230" height="187" alt="image" src="https://github.com/user-attachments/assets/d2877396-98e2-4a83-a643-91188649db98" />

<img width="820" height="178" alt="image" src="https://github.com/user-attachments/assets/cc1bc66a-fa33-42e0-961a-68ba950e2960" />


## Create Artifact Registry (GCP)
```
gcloud artifacts repositories create hcl-microservices \
    --repository-format=docker \
    --location=asia-south1 \
    --description="Hackathon microservices repo"
```

Tag and push images (use the repository you created)
```
docker tag patient-service:latest asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/patient-service:latest
docker tag application-service:latest asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/application-service:latest
docker tag order-service:latest asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/order-service:latest

docker push asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/patient-service:latest
docker push asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/application-service:latest
docker push asia-south1-docker.pkg.dev/<PROJECT>/hcl-microservices/order-service:latest
```
Replace `<PROJECT>` with your GCP project ID.

Artiftory location for images 
<img width="1281" height="551" alt="image" src="https://github.com/user-attachments/assets/dee8be2b-26b4-43f0-8e73-f292d10b3245" />
<img width="1315" height="513" alt="image" src="https://github.com/user-attachments/assets/5070ea42-ad2c-453d-8c66-24519ad9d736" />
<img width="1424" height="508" alt="image" src="https://github.com/user-attachments/assets/e36330c5-38e1-4105-9ad7-05f397171609" />
<img width="1369" height="549" alt="image" src="https://github.com/user-attachments/assets/3131e13c-9100-4fb7-b031-6bd67c7cd394" />



## Kubernetes (apply manifests)
```
kubectl apply -f k8s/patient-service.yaml
kubectl apply -f k8s/application-service.yaml
kubectl apply -f k8s/order-service.yaml
kubectl apply -f k8s/ingress.yaml
```

Example service listing:
```
NAME                  TYPE     CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
application-service   NodePort 34.118.233.181   <none>        80:32072/TCP   65m
order-service         NodePort 34.118.225.98    <none>        80:32747/TCP   65m
patient-service       NodePort 34.118.231.205   <none>        80:30609/TCP   66m
```
## Created GKE cluster but stuck with ARM64 Image issues during pod errors as i am using macbook pro M1
<img width="1180" height="535" alt="image" src="https://github.com/user-attachments/assets/716bf0f3-78aa-4a8f-8cf3-92e6babc213d" />
PODS issues in workfloads
<img width="1128" height="618" alt="image" src="https://github.com/user-attachments/assets/60204b48-7841-4460-95e7-ab4c26681570" />
INGRESS Created but having error 


<img width="1325" height="505" alt="image" src="https://github.com/user-attachments/assets/ef8bcf08-9022-47e3-af95-cc65b55d1942" />

with above issues i am going for KIND cluster creation 

## Kind cluster
Create a kind cluster:
```
kind create cluster --name hackathon1 --image kindest/node:v1.27.3
```

If using Kind with ingress, install the ingress controller (example using ingress-nginx):
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
```
<img width="829" height="236" alt="image" src="https://github.com/user-attachments/assets/b17640b3-c07e-4155-8e73-3b81a17eb049" />

## Observed issues & troubleshooting
- ARM64 image issues:
    - On ARM64 nodes, amd64 images will fail with ImagePullBackOff / incompatible platform.
    - Solution: build multi-arch images (docker buildx) or build for the node platform:
        ```
        docker buildx create --use
        docker buildx build --platform linux/amd64,linux/arm64 -t <registry>/<repo>:tag --push .
        ```
    - In CI, enable QEMU and buildx (see CI/CD recommendations below).

- GKE pods in ImagePullBackOff / Pending:
    - Check events and pod description:
        ```
        kubectl describe pod <pod-name>
        kubectl get events -n <namespace>
        ```
    - Verify image path, permissions, and that the node architecture matches the image.
    - If images are private, ensure imagePullSecrets or Workload Identity are configured.

- Kind: ingress shows but pods not created
    - Ensure your deployments actually created pods in the kind cluster (`kubectl get pods -A`).
    - If pods are Pending or ImagePullBackOff, fix the image issue first (see above).
    - Install ingress controller on kind (see command above) — Kind does not include an ingress controller by default.

## CI/CD / GitHub Actions tips (docker build failures)
- For multi-arch builds in Actions:
    - Use actions/setup-qemu and docker/setup-buildx-action.
    - Example steps:
        - actions/setup-qemu@v2
        - docker/setup-buildx-action@v2
        - docker/build-push-action@v4 with platforms: linux/amd64,linux/arm64
- Ensure the runner has auth to your registry (use docker/login-action or GCP authentication steps).


