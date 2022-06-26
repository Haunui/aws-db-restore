# aws-db-restore

Job script :  

    #!/usr/bin/bash  
    if [[ $NEW_ENV == true ]]; then  
	      echo "Trigger deploy pipeline"  
          exit 42  
    else  
	      bash restore.sh "$DATABASE"  
          exit 0  
    fi  
