replace_host(){
    local host_file=$1
    local folder_helm=$2

    # Ensure the templates directory exists
    if [ ! -d "$folder_helm" ]; then
       mkdir -p "$folder_helm"
    fi

    declare -A valid_files  # Store valid files for cleanup check

    # Loop through production & test branches
    for branch in $(yq '.host | keys | join(" ")' "$host_file"); do
        for host in $(yq -r ".host.$branch[]" "$host_file"); do
            STATUS=$(curl -Is "https://$host" | head -n 1 | awk '{print $2}')
            name=$(echo "$host" | cut -d'.' -f1)
            file_path="$folder_helm/$name.yaml"

            if [[ "$STATUS" == "200" || "$STATUS" == "301" || "$STATUS" == "302" ]]; then
                echo "✅ Website $host exists with status $STATUS"
                valid_files["$file_path"]=1
            else
                echo "❌ Website $host does not exist. Creating YAML..."
                sed -e "s/REPLACE_WITH_YOUR_DOMAIN/$host/g" sample/ingress.yaml > "$file_path"
                sed -i "s/REPLACE_WITH_YOUR_BRANCH/$branch/g" "$file_path"
                sed -i "s/REPLACE_WITH_NAME/$name/g" "$file_path"
                valid_files["$file_path"]=1
            fi
        done   
    done    

    # Cleanup: Remove files that are not in the host file
    echo "🔍 Cleaning up old YAML files..."
    for file in "$folder_helm/"*.yaml; do
        [[ -e "$file" ]] || continue  # Skip if no YAML files exist
        if [[ -z "${valid_files[$file]}" ]]; then
            echo "🗑️ Removing stale file: $file"
            rm "$file"
        fi
    done

    echo "✅ Process completed!"
}
