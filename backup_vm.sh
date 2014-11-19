#!/bin/sh

export PATH=/bin:/sbin

echo "" > /vmfs/volumes/bacula-vmdk/`hostname`.lock
cat /vmfs/volumes/bacula-vmdk/`hostname`.conf | while read vma ; do
    date
 
    if [ ! -d "/vmfs/volumes/bacula-vmdk/`hostname`/old" ] 
        then 
            echo "creation dossier old" 
            mkdir /vmfs/volumes/bacula-vmdk/`hostname`/old
    fi
  
    echo "deplacement des anciens snapshot dans le dossier old"
    mv /vmfs/volumes/bacula-vmdk/`hostname`/$vma* /vmfs/volumes/bacula-vmdk/`hostname`/old/ 
    
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
    vmkfstools -i $vmdk /vmfs/volumes/bacula-vmdk/`hostname`/$vma-$dateheure.vmdk
    echo "fin du clone du vmdk"

    echo "remove all snapshot"
    vim-cmd vmsvc/snapshot.removeall $vmid
    echo "les snapashots de la VM $vma ont ete supprime"
    
 
    vmdksnapshot="/vmfs/volumes/bacula-vmdk/`hostname`/$vma-$dateheure-flat.vmdk"
    vmdkSize=$( du -k "$vmdksnapshot" | sed 's/[[:blank:]].*$//'  )
    if [ $vmdkSize -gt 8589934592 ]
       then
          echo "suppression du dernier snapshot" 
          rm /vmfs/volumes/bacula-vmdk/`hostname`/old/$vma*
    fi
 
    date
    
  
done

rm  /vmfs/volumes/bacula-vmdk/`hostname`.lock
