# Helper functions for TLS support

# Determine if cert-manager is available

if [ "$(kubectl get crd certificates.cert-manager.io -o name 2>/dev/null)" ]; then
  export TLS_CERT_MANAGER_AVAILABLE="true"
else
  export TLS_CERT_MANAGER_AVAILABLE="false"
fi

function verify_cert_manager {
  if [ "$cert_manager_ok" == "true" ]; then
    return 0
  elif [ "$cert_manager_ok" == "false" ]; then
    return 1
  fi

  cert_manager_ok="true"
  if [ "$TLS_ENABLE" == "true" ]; then
    if [ "$TLS_CERT_MANAGER_ENABLE" == "true" ]; then
      if [ "$TLS_CERT_MANAGER_AVAILABLE" == "true" ]; then
        log_debug "cert-manager needed, enabled, and present"        
      else
        log_error "Use of cert-manager is enabled, but cert-manager is not available"
        cert_manager_ok="false"
      fi
    else
      log_debug "Use of cert-manager is disabled"
    fi
  else
    log_debug "TLS is disabled. Skipping verification of cert-manager."
  fi
  
  if [ "$cert_manager_ok" == "true" ]; then
    return 0
  else
    return 1
  fi
}

function deploy_issuers {
  namespace=$1
  context=$2
  # Create issuers if needed
  # Issuers honor USER_DIR for overrides/customizations
  if [ -z "$(kubectl get issuer -n $namespace selfsigning-issuer -o name 2>/dev/null)" ]; then
    log_info "Creating selfsigning-issuer for the [$namespace] namespace..."
    selfsignIssuer=$context/tls/selfsigning-issuer.yaml
    if [ -f "$USER_DIR/$context/tls/selfsigning-issuer.yaml" ]; then
      selfsignIssuer="$USER_DIR/$context/tls/selfsigning-issuer.yaml"
    fi
    log_debug "Self-sign issuer yaml is [$selfsignIssuer]"
    kubectl apply -n $namespace -f "$selfsignIssuer"
    sleep 5
  else
    log_debug "Using existing $namespace/selfsigning-issuer"
  fi
  if [ -z "$(kubectl get secret -n $namespace ca-certificate-secret -o name 2>/dev/null)" ]; then
    log_info "Creating self-signed CA certificate for the [$namespace] namespace..."
    caCert=$context/tls/ca-certificate.yaml
    if [ -f "$USER_DIR/$context/tls/ca-certificate.yaml" ]; then
      caCert="$USER_DIR/$context/tls/ca-certificate.yaml"
    fi
    log_debug "CA cert yaml file is [$caCert]"
    kubectl apply -n $namespace -f "$caCert"
    sleep 5
  else
    log_debug "Using existing $namespace/ca-certificate-secret"
  fi
  if [ -z "$(kubectl get issuer -n $namespace namespace-issuer -o name 2>/dev/null)" ]; then
    log_info "Creating namespace-issuer for the [$namespace] namespace..."
    namespaceIssuer=$context/tls/namespace-issuer.yaml
    if [ -f "$USER_DIR/$context/tls/namespace-issuer.yaml" ]; then
      namespaceIssuer="$USER_DIR/$context/tls/namespace-issuer.yaml"
    fi
    log_debug "Namespace issuer yaml is [$namespaceIssuer]"
    kubectl apply -n $namespace -f "$namespaceIssuer"
    sleep 5
  else
    log_debug "Using existing $namespace/namespace-issuer"
  fi
}

function deploy_app_cert {
  namespace=$1
  context=$2
  app=$3

  if [ "$TLS_CERT_MANAGER_ENABLE" == "true" ]; then
    # Create the certificate using cert-manager
    certyaml=$context/tls/$app-tls-cert.yaml
    if [ -f "$USER_DIR/$context/tls/$app-tls-cert.yaml" ]; then
      certyaml="$USER_DIR/$context/tls/$app-tls-cert.yaml"
    fi
    log_debug "Creating cert-manager certificate custom resource for [$app] using [$certyaml]"
    kubectl apply -n $namespace -f "$certyaml"
  fi
}

function create_tls_certs {
  namespace=$1
  context=$2
  shift 2
  apps=("$@")

  # Optional TLS Support
  if [ "$TLS_CERT_MANAGER_ENABLE" == "true" ]; then
    deploy_issuers $namespace $context
  fi
  
  # Certs honor USER_DIR for overrides/customizations
  for app in "${apps[@]}"; do
    # Only create the secrets if they do not exist
    TLS_SECRET_NAME=$app-tls-secret
    if [ -z "$(kubectl get secret -n $namespace $TLS_SECRET_NAME -o name 2>/dev/null)" ]; then
        deploy_app_cert "$namespace" "$context" "$app"
    else
      log_debug "Using existing $TLS_SECRET_NAME for [$app]"
    fi
  done
}

export -f verify_cert_manager deploy_issuers deploy_app_cert create_tls_certs
