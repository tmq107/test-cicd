replace_host(){
    local host_file=$1
    local folder_helm=$2

    if [ ! -d "$folder_helm/templates" ]; then
       mkdir -p $folder_helm/templates
    fi
    
    for host in $(yq -r '.host[]' $host_file)
    do
        ingress=$host
        name=$(echo $host | cut -d'.' -f1)
        STATUS=$(curl -Is https://$ingress | head -n 1 | awk '{print $2}')
        if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
            echo "Website $ingress exists with status $STATUS"
        else
            sed -e 's/REPLACE_WITH_YOUR_DOMAIN/'"$ingress"'/g' sample/ingress.yaml > $folder_helm/templates/$name.yaml
            sed -i 's/REPLACE_WITH_NAME/'"$name"'/g' $folder_helm/templates/$name.yaml
            svc=$(yq -r '.backend.name' $host_file)
            port=$(yq -r '.backend.port' $host_file)
            sed -i 's/REPLACE_WITH_YOUR_BACKEND/'"$svc"'/g' $folder_helm/templates/$name.yaml
            sed -i 's/REPLACE_WITH_YOUR_PORT/'"$port"'/g' $folder_helm/templates/$name.yaml
        fi
    done    
}
