#!/bin/zsh
function list_permissions(){
    parent_folder_id=$1
    indent=$2
    folder_name=$(gcloud resource-manager folders describe $parent_folder_id --format=json |  jq -r --arg indent $indent ' "Folder ID: " + .name + ", Folder Name: " + .displayName' | head -2)

    if [ $? -eq 0 ]; then
        echo "$parent_folder_id"
    else
        return
    fi

    (echo "PROJECT - $folder_name" && paste -d "," <(printf %s "$(for j in $(seq 1 $(gcloud alpha resource-manager folders get-iam-policy $parent_folder_id | yq '.bindings | .[].role' | cut -d "\"" -f2 | wc -l)); do echo $i; done;)") <(printf %s "$(gcloud alpha resource-manager folders get-iam-policy $parent_folder_id  | yq '.bindings | .[].role' | cut -d "\"" -f2)") <(printf %s "$(gcloud alpha resource-manager folders get-iam-policy $parent_folder_id  | yq '.bindings | .[].members | join(",")' | 
cut -d"\"" -f2)")) | cat >> 13_set.csv
}


function list_folders() {
    parent_folder_id=$1
    

    # Execute gcloud command to list all folders under the given parent folder in JSON format
    folders=$(gcloud resource-manager folders list --format=json --folder="$parent_folder_id")

    

    echo "$folders"

}

function crawl_folders() {
    parent_folder_id=$1
    indent=$2
    
    folders=$(list_folders $parent_folder_id)
    folders_id=$(echo "$folders" | jq -r '.[] | .name | split("/") | .[-1]')

    if [ $? -eq 0 ]; then
        echo "$folders_id"
    else
        echo "Failed to list sub-folders for folder ID: $folders_id."
    fi


     if [ -z "$folders_id" ]; then
         return
     fi

    if [ $? -eq 0 ]; then
        echo "$folders" | jq -r --arg indent "$indent" '.[] | "  " * ($indent | tonumber) + "Folder ID: " + .name + ", Folder Name: " + .displayName'
    else
        echo "Failed to list sub-folders for folder ID: $folders."
    fi

    while IFS= read -r folder_id; do
        list_permissions "$folder_id" $((indent+1))
        
    #     # Recursively crawl sub-folders
        crawl_folders "$folder_id" $((indent+1))
    done <<< "$folders_id"
}




main () {
    parent_folder_id="(folder_id)"

    crawl_folders "$parent_folder_id" 1
}
main