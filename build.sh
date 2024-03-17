#! /bin/sh -e

export DOCKER_BUILDKIT=1
docker run --rm --cap-add SYS_ADMIN multiarch/qemu-user-static --reset -p yes

ARCHS="amd64 arm64"
DOCKERFILE="Dockerfile"
NAME="pipeline-sandbox"
NAME="${NAME#*/}"
NAME="${NAME#docker-}"
NAMESPACE="martoc"
BUILD_ARGS="--build-arg TAG_VERSION=${TAG_VERSION} --build-arg BUILD_SHA=${GITHUB_SHA}"
LABEL_ARGS=(
  --label "org.label-schema.name=${NAME}"
  --label "org.label-schema.schema-version=1.0"
  --label "org.label-schema.vcs-url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
  --label "org.label-schema.vcs-ref=${GITHUB_SHA}"
  --label "org.label-schema.build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  --label "org.label-schema.version=${TAG_VERSION}"
  --label "org.label-schema.description=$DESCRIPTION"
  --label "org.label-schema.usage=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${TAG_NAME}/docs/index.md"
  --label "org.label-schema.url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
  --label "org.opencontainers.image.ref.name=${NAME}"
  --label "org.opencontainers.image.source=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
  --label "org.opencontainers.image.revision=${GITHUB_SHA}"
  --label "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  --label "org.opencontainers.image.version=${TAG_VERSION}"
  --label "org.opencontainers.image.url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}"
  --label "org.opencontainers.image.title=${NAME}"
  --label "org.opencontainers.image.documentation=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${TAG_NAME}/docs/index.md"
  --label "org.opencontainers.image.description=${DESCRIPTION}"
  --label "org.opencontainers.image.authors=${GITHUB_ACTOR}"
  --label "org.opencontainers.image.licenses=“Copyright (c) $(date -u +'%Y') martoc"
)

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

for ARCH in ${ARCHS}; do
  docker build "${LABEL_ARGS[@]}" ${BUILD_ARGS} --file ${DOCKERFILE} --platform linux/${ARCH} --tag ${NAMESPACE}/${NAME}:latest-${ARCH} --tag ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH} .
done

for ARCH in ${ARCHS}; do
  docker manifest create ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH} ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH}
  docker manifest push ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH}
done
docker push ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH}
docker push ${NAMESPACE}/${NAME}:latest-${ARCH}


for ARCH in ${ARCHS}; do
  echo ${NAMESPACE}/${NAME}:latest-${ARCH}
done | xargs docker manifest create ${NAMESPACE}/${NAME}:latest
docker manifest push ${NAMESPACE}/${NAME}:latest
for ARCH in ${ARCHS}; do
  echo ${NAMESPACE}/${NAME}:${VERSION}-${ARCH}
done | xargs docker manifest create ${NAMESPACE}/${NAME}:${VERSION}
docker manifest push ${NAMESPACE}/${NAME}:${VERSION}