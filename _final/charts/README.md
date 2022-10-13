# zerosystems/zeroconnectapi
Helm chart for zeroconnect api
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/zerosystemsapi)](https://artifacthub.io/packages/search?repo=zerosystemsapi)
```
helm repo add zerosystemsapi http://charts.zerosystems.sbs/
helm install my-zeroconnectapi zerosystemsapi/zeroconnectapi --version 1.9.0 --set secretsName={SECRET_NAME} --set ingress.certificateARN='{CERT_ARN}' --set image.tag={IMAGE_TAG}
```
