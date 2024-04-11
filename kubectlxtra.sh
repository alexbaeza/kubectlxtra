#!/bin/bash

set -o pipefail

# Function to display error message and exit
helper_display_error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to strip HTTP and HTTPS from a URL
helper_strip_http_https() {
    local url="$1"
    # Remove "http://" if present
    url="${url#http://}"
    # Remove "https://" if present
    url="${url#https://}"
    echo "$url"
}

# Function to run kubectl command
kubectl_cmd() {
    # forward all args to kubectl
    kubectl "$@"
}

# Function to run kubectl command silently
kubectl_silent_cmd() {
    kubectl_cmd "$@" >/dev/null 2>&1
}

# Function to query kubectl config
helper_query_kubectl_config() {
    local query="$1"
    kubectl_cmd config view --minify -o jsonpath="$query"
}

# Function to retrieve all namespaces
helper_kubectl_get_namespaces_list() {
    local namespaces
    if namespaces=$(kubectl_cmd get namespace | awk '{print $1}' | tail -n +2); then
        echo "$namespaces"
    fi
}

# Function to display namespaces and currently selected namespaces
helper_display_namespace_list() {

    local namespaces_list="$1"
    local current_namespace
    local current_server

    current_namespace=$(helper_query_kubectl_config '{..namespace}')
    current_server=$(helper_query_kubectl_config '{..cluster.server}')

    # Convert space-separated list to array
    # shellcheck disable=SC2206
    local NAMESPACES_ARRAY=($namespaces_list)
    echo
    echo "You have access to ${#NAMESPACES_ARRAY[@]} namespace(s) on cluster $current_server"

    for ns in "${NAMESPACES_ARRAY[@]}"; do
        if [[ $ns == "$current_namespace" ]]; then
            echo "* $ns"
        else
            echo "  $ns"
        fi
    done

    echo
    echo "Using namespace '$current_namespace' on cluster $current_server"
}


#Function used to check if a user is logged in
helper_check_cluster_info() {
    local error_message
    if ! error_message=$(kubectl_cmd cluster-info 2>&1 >/dev/null); then
        echo "Error: $error_message"
        return 1
    fi
}

# Function to execute kubectlxtra namespaces list command
execute_enhanced_namespace_list() {
    local NAMESPACES_ARRAY

    namespaces=$(helper_kubectl_get_namespaces_list)

    if [[ -n "$namespaces" ]]; then
        helper_display_namespace_list "$namespaces"
    fi
}

# Function to execute kubectlxtra logout command
execute_enhanced_logout() {
    # Check if logged in
    if helper_check_cluster_info; then
        local user
        local context
        local cluster

        # Get current user, context, and cluster
        user=$(helper_query_kubectl_config '{..context.user}')
        context=$(helper_query_kubectl_config '{..current-context}')
        cluster=$(helper_query_kubectl_config '{.clusters[].name}')

        # Clean up credentials
        kubectl_silent_cmd config delete-context "$context"
        kubectl_silent_cmd config delete-cluster "$cluster"
        kubectl_silent_cmd config delete-user "$user"
        kubectl_silent_cmd config unset current-context

        echo "Logout succeeded"
    else
        echo "Not logged in"
    fi
}

# Function to execute kubectlxtra login command
execute_enhanced_login() {
    local server
    local token
    local ca_cert
    local insecure_skip_tls_verify
    local cluster_name

    # Parse options
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        --server=*)
            server="${1#*=}"
            shift
            ;;
        --token=*)
            token="${1#*=}"
            shift
            ;;
        --ca-cert=*)
            ca_cert="${1#*=}"
            shift
            ;;
        --name=*)
            cluster_name="${1#*=}"
            shift
            ;;
        --insecure-skip-tls-verify=*)
            insecure_skip_tls_verify="${1#*=}"
            shift
            ;;
        --help)
            # Display help for the login command
            echo "Help for 'login' command:"
            echo "  --server                    The server URL to connect to (required)"
            echo "  --token                     The token to authenticate with (required)"
            echo "  --ca-cert                   The ca-cert (optional)"
            echo "  --insecure-skip-tls-verify  Skip TLS certificate verification (defaults to false) This will make your HTTPS connections insecure"
            echo "  --name                      The name of the cluster (optional)"
            echo
            echo "Example"
            echo "kubectlxtra login --server=https://192.168.1.254:6443 --token=XXXXXXX"
            echo "kubectlxtra login --server=https://192.168.1.254:6443 --token=XXXXXXX --ca-cert=XXXXXXX"
            echo "kubectlxtra login --server=https://192.168.1.254:6443 --token=XXXXXXX --insecure-skip-tls-verify=true"
            exit 0
            ;;
        *)
            helper_display_error "Unknown option: $1"
            ;;
        esac
    done

    # Validate options
    if [[ -z "$server" || -z "$token" ]]; then
        helper_display_error "--server and --token options are required"
    fi

    # Set default value for insecure_skip_tls_verify
    insecure_skip_tls_verify="${insecure_skip_tls_verify:-false}"
    cluster_name=${cluster_name:-$(helper_strip_http_https "$server")}
    local user_name="kubernetes-service-account"

    # Set Credentials
    if [[ -z "$ca_cert" ]]; then
        kubectl_silent_cmd config set-cluster "$cluster_name" --server="$server" --insecure-skip-tls-verify="$insecure_skip_tls_verify"
    else
        kubectl_silent_cmd config set-cluster "$cluster_name" --server="$server" --certificate-authority-data="$ca_cert"
    fi
    kubectl_silent_cmd config set-credentials "$user_name" --token="$token"
    kubectl_silent_cmd config set-context "$cluster_name" --cluster="$cluster_name" --user="$user_name"

    # Switch to new credentials
    kubectl_silent_cmd config use-context "$cluster_name"

    if helper_check_cluster_info; then
        namespaces=$(helper_kubectl_get_namespaces_list)
        IFS=' ' read -r -a namespaces_array <<<"$namespaces"

        if [[ ${#namespaces_array[@]} -gt 0 ]]; then
            # Select the first namespace
            kubectl_silent_cmd config set-context --current --namespace="${namespaces_array[0]}"
        fi

        helper_display_namespace_list "$namespaces"
        echo "Login Successful"

    else
        # Silent logout
        execute_enhanced_logout
        echo 'Login Failed'
    fi
}

# Function to execute kubectl namespace selector command
execute_enhanced_namespace() {
    local target_namespace=$1
    local current_namespace

    current_namespace=$(helper_query_kubectl_config '{..namespace}')

    if [[ $target_namespace == "$current_namespace" ]]; then
        echo "You are already in namespace '$current_namespace'"
    else
        kubectl_silent_cmd config set-context --current --namespace="$target_namespace"
        echo "Switched to namespace '$target_namespace'"
    fi
}

# Function to display kubectlxtra help
execute_enhanced_help() {
    echo "KubectlXtra"
    echo
    echo "This client enhances kubectl cli tool with extra features for convenience and simplification. It helps manage, deploy, and run applications within a Kubernetes Cluster"
    echo
    echo "Enhanced Commands (Added by kubectlxtra):"
    echo "login          Log in to the given server with the given credentials"
    echo "logout         Log out of the current context and delete credentials"
    echo "namespaces     Display namespaces with the logged-in user has access to"
    echo "namespace      Switch between namespaces"

    echo "Original kubectl help docs"
    echo
    kubectl_cmd help
}

# Main function
main() {
    local command="$1"

    case "$command" in
    login)
        # enhance kubectl with new login function
        shift
        execute_enhanced_login "$@"
        ;;
    logout)
        # enhance kubectl with new logout function
        shift
        execute_enhanced_logout "$@"
        ;;
    namespace)
        # enhance kubectl with new namespace function
        shift
        execute_enhanced_namespace "$@"
        ;;
    namespaces)
        # enhance kubectl with new namespace list function
        shift
        execute_enhanced_namespace_list
        ;;
    help)
        # enhance kubectl with new help function
        shift
        execute_enhanced_help
        ;;
    *)
        kubectl_cmd "$@"
        ;;
    esac
}

# Run main function with arguments
main "$@"
