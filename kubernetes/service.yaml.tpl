apiVersion: v1
kind: Service
metadata:
  name: ${PROJECT_PREFIX}-${APP_NAME}
spec:
  type: LoadBalancer
  selector:
    app: ${PROJECT_PREFIX}-${APP_NAME}
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080