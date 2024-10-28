apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${PROJECT_PREFIX}-${APP_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${PROJECT_PREFIX}-${APP_NAME}
  template:
    metadata:
      labels:
        app: ${PROJECT_PREFIX}-${APP_NAME}
    spec:
      serviceAccountName: ${PROJECT_PREFIX}-${APP_NAME}-serviceaccount
      containers:
      - name: ${PROJECT_PREFIX}-${APP_NAME}
        image: "${APP_IMAGE}"
        tty: true
        env:
        - name: MONGODB_URI
          value: "${MONGODB_URI}"
      imagePullSecrets:
      - name: ecr-registry-secret