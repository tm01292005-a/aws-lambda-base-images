## Usage

```
docker build -t nodejs22.x:local -f Dockerfile.nodejs22.x \
  --build-arg AWS_CLI_ARCH=x86_64 \
  --build-arg SAM_CLI_VERSION=1.139.0 \
  --build-arg IMAGE_ARCH=x86_64 .
```
