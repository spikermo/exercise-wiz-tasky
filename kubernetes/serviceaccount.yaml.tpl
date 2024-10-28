apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${PROJECT_PREFIX}-${APP_NAME}-serviceaccount
  namespace: default

--- 

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${PROJECT_PREFIX}-${APP_NAME}-cluster-admin
subjects:
- kind: ServiceAccount
  name: ${PROJECT_PREFIX}-${APP_NAME}-serviceaccount
  namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---

# Permissive RBAC Permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: permissive-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: kubelet
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts