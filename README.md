# Kubernetes Self-Hosted Azure DevOps Agents with KEDA Autoscaling

Azure DevOps pipeline'larinizi Kubernetes uzerinde calistirmak icin KEDA tabanli otomatik olceklenen self-hosted agent altyapisi.

## Mimari

```
Azure DevOps Pipeline Queue
        |
        v
  KEDA ScaledObject ──── Pipeline kuyruk derinligini izler (15sn aralikla)
        |
        v
  Deployment (0-10 replica)
        |
        v
  Agent Pod ──────────── Azure DevOps'a otomatik kayit
        |
        v
  Pipeline Job calistirilir ── Bittikten sonra KEDA scale-down (5dk cooldown)
```

## Proje Yapisi

```
Kubernetes_as_Azure_Agent/
├── images/
│   ├── base/
│   │   ├── Dockerfile                # Minimal base image (sadece agent gereksinimleri)
│   │   └── agent_installation.sh     # Agent bootstrap & Azure DevOps kayit
│   ├── go/
│   │   └── Dockerfile                # Go + Node + Python + Azure CLI (multi-stage)
│   └── node/
│       └── Dockerfile                # Node + Python + Azure CLI (multi-stage)
├── k8s/
│   ├── base/
│   │   ├── namespace.yml             # Namespace tanimlamasi
│   │   └── secret.yml                # PAT Secret & KEDA TriggerAuthentication
│   ├── go/
│   │   └── deployment.yml            # Go agent Deployment + KEDA ScaledObject
│   └── node/
│       └── deployment.yml            # Node agent Deployment + KEDA ScaledObject
├── charts/
│   └── azure-devops-agent/           # Helm chart
│       ├── Chart.yaml
│       ├── values.yaml               # Default degerler
│       ├── values-dev.yaml           # Dev ortami overrides
│       ├── values-prod.yaml          # Prod ortami overrides
│       └── templates/
│           ├── _helpers.tpl
│           ├── secret.yaml
│           ├── deployment.yaml
│           └── scaledobject.yaml
├── pipelines/
│   ├── build-agent.yml               # Agent image build & deploy pipeline
│   └── test-pipeline.yml             # Ornek test pipeline
└── README.md
```

## Onkosuller

- Azure Kubernetes Service (AKS) cluster
- KEDA cluster'a kurulu:
  ```bash
  helm repo add kedacore https://kedacore.github.io/charts
  helm install keda kedacore/keda --namespace keda --create-namespace
  ```
- Azure Container Registry (ACR) ve AKS'e bagli `acr-secret` ImagePullSecret
- Azure DevOps organizasyonu ve **Agent Pool (Read & Manage)** yetkili PAT
- Lokal: Docker, kubectl, Azure CLI

## Hizli Baslangic

### 1. Repo'yu klonla

```bash
git clone https://github.com/Cenkay1/Kubernetes_as_Azure_Agent.git
cd Kubernetes_as_Azure_Agent
```

### 2. Docker image build & push

```bash
# Ortak script'i image klasorune kopyala
cp images/base/agent_installation.sh images/go/

# Go agent
docker build -t myacr.azurecr.io/gokubeagent:v1.0.0 images/go/
docker push myacr.azurecr.io/gokubeagent:v1.0.0

# Node agent
cp images/base/agent_installation.sh images/node/
docker build -t myacr.azurecr.io/nodekubeagent:v1.0.0 images/node/
docker push myacr.azurecr.io/nodekubeagent:v1.0.0
```

### 3. Helm ile deploy et (Onerilen)

```bash
# Dev ortami
helm install azure-agents charts/azure-devops-agent \
  -f charts/azure-devops-agent/values-dev.yaml \
  -n azure-agents --create-namespace

# Prod ortami
helm install azure-agents charts/azure-devops-agent \
  -f charts/azure-devops-agent/values-prod.yaml \
  -n azure-agents --create-namespace

# Veya inline degerlerle
helm install azure-agents charts/azure-devops-agent \
  -n azure-agents --create-namespace \
  --set azureDevOps.url="https://dev.azure.com/myorg" \
  --set azureDevOps.pat="your-pat" \
  --set azureDevOps.poolName="MyKubePool" \
  --set image.registry="myacr.azurecr.io"
```

#### Guncelleme & kaldirma

```bash
# Degerleri guncelledikten sonra
helm upgrade azure-agents charts/azure-devops-agent \
  -f charts/azure-devops-agent/values-prod.yaml \
  -n azure-agents

# Tamamen kaldirma
helm uninstall azure-agents -n azure-agents
```

### Alternatif: kubectl ile manuel deploy

<details>
<summary>Helm kullanmak istemiyorsaniz</summary>

`k8s/` klasorundeki YAML'lardaki placeholder'lari doldurun:

| Placeholder | Aciklama | Ornek |
|---|---|---|
| `<CONTAINER_REGISTRY>` | ACR URL | `myacr.azurecr.io` |
| `<IMAGE_TAG>` | Image tag | `v1.0.0` |
| `<AGENT_POOL_NAME>` | Azure DevOps pool adi | `MyKubePool` |
| `<AZURE_DEVOPS_ORG_URL>` | Organizasyon URL | `https://dev.azure.com/myorg` |
| `<BASE64_ENCODED_PAT>` | base64 PAT | `echo -n "pat" \| base64` |

```bash
kubectl apply -f k8s/base/
kubectl apply -f k8s/go/deployment.yml
kubectl apply -f k8s/node/deployment.yml
```

</details>

### 4. Dogrulama

```bash
# Pod'larin calistigini kontrol et
kubectl get pods -n azure-agents

# KEDA ScaledObject durumunu kontrol et
kubectl get scaledobject -n azure-agents

# Agent loglarini izle
kubectl logs -f -l agent-type=go -n azure-agents

# Helm release durumu
helm status azure-agents -n azure-agents
```

## Ozellikler

### KEDA Autoscaling
- **Min replica:** 0 (is yokken kaynak tuketmez)
- **Max replica:** 10
- **Polling interval:** 15 saniye (kuyruk kontrol sikligi)
- **Cooldown:** 300 saniye (scale-down oncesi bekleme)
- Kuyrukta bekleyen job varsa otomatik pod olusturulur

### Agent Etiketleme (Tagging)
Ayni pool icinde farkli runtime'lara sahip agent'lari etiketleyerek, pipeline'larda belirli agent'lara yonlendirebilirsiniz:

```yaml
pool:
  name: MyKubePool
  demands:
    - TAG_VALUE -equals goonly
```

### Guvenlik
- PAT degeri Kubernetes Secret'ta saklanir, Deployment'a `secretKeyRef` ile inject edilir
- Liveness/Readiness probe'lari agent sagligini izler
- Resource requests/limits tanimli (kaynak tuketimi kontrol altinda)

## Yeni Agent Tipi Ekleme

1. `images/<yeni-tip>/Dockerfile` olusturun (gerekli runtime'i ekleyin)
2. `values.yaml`'a yeni agent tanimlayin:
   ```yaml
   agents:
     python:
       enabled: true
       image: pythonkubeagent
       tag: v1.0.0
       tagValue: "pythononly"
       resources:
         requests:
           cpu: "500m"
           memory: "512Mi"
         limits:
           cpu: "2"
           memory: "2Gi"
   ```
3. Image'i build & push edin
4. `helm upgrade` ile deploy edin - Helm otomatik olarak yeni Deployment ve ScaledObject olusturur
