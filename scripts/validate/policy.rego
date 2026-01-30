package kubernetes.admission

# Deny ClusterIssuer without acme.email
deny contains msg if {
    input.kind == "ClusterIssuer"
    input.spec.acme
    not input.spec.acme.email
    msg := "ClusterIssuer must have spec.acme.email"
}

# Deny ExternalSecret without secretStoreRef.name
deny contains msg if {
    input.kind == "ExternalSecret"
    not input.spec.secretStoreRef.name
    msg := "ExternalSecret must have spec.secretStoreRef.name"
}

# Deny ClusterSecretStore without provider
deny contains msg if {
    input.kind == "ClusterSecretStore"
    not input.spec.provider
    msg := "ClusterSecretStore must have spec.provider"
}

# Deny Certificate without issuerRef.name
deny contains msg if {
    input.kind == "Certificate"
    not input.spec.issuerRef.name
    msg := "Certificate must have spec.issuerRef.name"
}

# Deny IngressRoute without routes
deny contains msg if {
    input.kind == "IngressRoute"
    not input.spec.routes
    msg := "IngressRoute must have spec.routes"
}

# Deny Middleware without spec
deny contains msg if {
    input.kind == "Middleware"
    not input.spec
    msg := "Middleware must have spec"
}

# Deny TLSOption without spec
deny contains msg if {
    input.kind == "TLSOption"
    not input.spec
    msg := "TLSOption must have spec"
}

