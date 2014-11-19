#!/bin/sh
source backup_vm.conf

export PATH=/bin:/sbin

echo "" > $lock_file
cat $config_file | while read vma ; do
    date
 
    if [ ! -d $temp_dir ] 
        then 
            echo "creation dossier old" 
            mkdir $temp_dir
    fi
  
    echo "deplacement des anciens snapshot dans le dossier old"
    mv $snapshot_dir/$vma* $temp_dir 
    
    #cherche l'id de la VM
    vmid=$(vim-cmd vmsvc/getallvms | grep $vma | awk '{print $1'})
    echo "la vm $vma a pour vmID $vmid"
	
    #cherche le path complet vers le vmdk
    vmdk=$(vim-cmd vmsvc/getallvms | grep $vma | awk {'print "/vmfs/volumes/"$3"/"$4'} | sed -e "s/\[// ; s/\]// ; s/vmx/vmdk/")
    echo "la vm $vma a pour vmdk $vmdk"

    dateheure=$(date '+%Y%m%d-%H%M')

    echo "remove all snapshot"
    vim-cmd vmsvc/snapshot.removeall $vmid

    echo "creation du snapshot $dateheure "
    vim-cmd vmsvc/snapshot.create $vmid $dateheure
    echo "le snapshot a ete cree"

    echo "debut clone du vmdk"
    vmkfstools -i $vmdk $snapshot_dir/$vma-$dateheure.vmdk
    echo "fin du clone du vmdk"

    echo "remove all snapshot"
    vim-cmd vmsvc/snapshot.removeall $vmid
    echo "les snapashots de la VM $vma ont ete supprime"
    
 
    vmdksnapshot="$snapshot_dir/$vma-$dateheure-flat.vmdk"
    vmdkSize=$( du -m "$vmdksnapshot" | sed 's/[[:blank:]].*$//'  )
    if [ $vmdkSize -gt 1024 ]
       then
          echo "suppression du dernier snapshot" 
          rm $temp_dir/$vma*
    fi
 
    date
    
  
done

rm  /vmfs/volumes/bacula-vmdk/`hostname`.lock
