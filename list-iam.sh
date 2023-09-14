#!/bin/zsh

FILE_NAME="(FILE_NAME)"
echo "PROJECT_ID,ROLES,MEMBERS" | cat >> $FILE_NAME.csv
for i in $(gcloud projects list |  sed 1d | cut -f1 -d$' '); do
    echo "Getting IAM policies for project:" $i;
    echo "..........";
    (echo "PROJECT - $i" && paste -d "," <(printf %s "$(for j in $(seq 1 $(gcloud projects get-iam-policy $i | yq '.bindings | .[].role' | cut -d "\"" -f2 | wc -l)); do echo $i; done;)") <(printf %s "$(gcloud projects get-iam-policy $i | yq '.bindings | .[].role' | cut -d "\"" -f2)") <(printf %s "$(gcloud projects get-iam-policy $i | yq '.bindings | .[].members | join(",")' | 
cut -d"\"" -f2)")) | cat >> $FILE_NAME.csv
 
    echo "Done. Logs created at file" $FILE_NAME.csv;
    echo "--------------------------------"
done;
