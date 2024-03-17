#! /bin/sh -e

NAME="pipeline-sandbox"
NAME="${NAME#*/}"
NAME="${NAME#docker-}"
ARCHS="amd64 arm64"
DOCKERFILE="Dockerfile"
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

DOCKER_IMAGE_TAGS=""
for ARCH in ${ARCHS}; do
  echo "Building ${ARCH}..."
  docker buildx build "${LABEL_ARGS[@]}" ${BUILD_ARGS} --build-arg ARCH=${ARCH} --no-cache --progress plain --file ${DOCKERFILE} --platform linux/${ARCH} --tag ${NAMESPACE}/${NAME}:latest-${ARCH} --tag ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH} .
  DOCKER_IMAGE_TAGS="${DOCKER_IMAGE_TAGS} ${NAMESPACE}/${NAME}:latest-${ARCH} ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH}"
done

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}

for IMAGE_TAG in ${DOCKER_IMAGE_TAGS}; do
  echo "Pushing ${IMAGE_TAG}..."
  docker push ${IMAGE_TAG}
done

for ARCH in ${ARCHS}; do
  echo ${NAMESPACE}/${NAME}:latest-${ARCH}
done | xargs docker manifest create ${NAMESPACE}/${NAME}:latest
docker manifest push ${NAMESPACE}/${NAME}:latest
for ARCH in ${ARCHS}; do
  echo ${NAMESPACE}/${NAME}:${TAG_VERSION}-${ARCH}
done | xargs docker manifest create ${NAMESPACE}/${NAME}:${TAG_VERSION}
docker manifest push ${NAMESPACE}/${NAME}:${TAG_VERSION}