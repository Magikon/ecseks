Helm chart for ZeroConnect API
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zeroconnect)](https://artifacthub.io/packages/search?repo=zeroconnect)
```
helm repo add zeroconnect https://charts.zerosystems.sbs
helm install my-zeroconnectapi zeroconnect/zeroconnectapi --version 1.9.0 --set secretsName={SECRET_NAME} --set ingress.certificateARN='{CERT_ARN}' --set image.tag={IMAGE_TAG}
```
