## Introduction

Complete set of requirements for this proposed change is given under [fencing.md](https://github.hpe.com/container-provider/design-guide/blob/master/doc/fencing.md)
This document only talks about the changes needed to be implemented for HPE 3PAR Docker Volume Plugin to work with orchestrator like 
Kubernetes.

## etcd changes
### etcd record for a volume (used by 3par docker plugin)

```

{
	"status": "",
	"display_name": "testvol20",
	"name": "8a2818b7-11e8-4bed-a8f9-b099979be4f9",
	"volume_attachment": null,
	"availability_zone": "",
	"attach_status": "",
	"volume_type": null,
	"provisioning": "thin",
	"host": "",
	"provider_location": null,
	"volume_id": "",
	"flash_cache": null,
	"size": 50,
	"id": "8a2818b7-11e8-4bed-a8f9-b099979be4f9",
	"path_info": {
		"connection_info": {
			"driver_volume_type": "iscsi",
			"data": {
				"target_luns": [5, 5],
				"target_iqns": ["iqn.2000-05.com.3pardata:22210002ac0124b7", "iqn.2000-05.com.3pardata:23210002ac0124b7"],
				"target_discovered": true,
				"encrypted": false,
				"target_portals": ["10.213.88.6:3260", "10.213.88.134:3260"],
				"auth_password": "KJwDxdeLaVAts6Vs",
				"auth_username": "lablcactus07.uhclab.lab",
				"auth_method": "CHAP"
			}
		},
		"path": "/dev/dm-24",
		"device_info": {
			"path": "/dev/disk/by-id/dm-uuid-mpath-360002ac00000000000004b68000124b7",
			"scsi_wwn": "360002ac00000000000004b68000124b7",
			"type": "block",
			"multipath_id": "360002ac00000000000004b68000124b7"
		},
		"name": "testvol20",
		"mount_dir": "/opt/hpe/data/hpedocker-dm-uuid-mpath-360002ac00000000000004b68000124b7"
	}
}
```

### Proposed new change to the etcd record for volume
```
{
	"path_info": {
		"worker1": {
			"connection_info": {
				"driver_volume_type": "iscsi",
				"data": {
					"target_luns": [5, 5],
					"target_iqns": ["iqn.2000-05.com.3pardata:22210002ac0124b7", "iqn.2000-05.com.3pardata:23210002ac0124b7"],
					"target_discovered": true,
					"encrypted": false,
					"target_portals": ["10.213.88.6:3260", "10.213.88.134:3260"],
					"auth_password": "KJwDxdeLaVAts6Vs",
					"auth_username": "lablcactus07.uhclab.lab",
					"auth_method": "CHAP"
				}
			},
			"path": "/dev/dm-24",
			"device_info": {
				"path": "/dev/disk/by-id/dm-uuid-mpath-360002ac00000000000004b68000124b7",
				"scsi_wwn": "360002ac00000000000004b68000124b7",
				"type": "block",
				"multipath_id": "360002ac00000000000004b68000124b7"
			},
			"name": "testvol20",
			"mount_dir": "/opt/hpe/data/hpedocker-dm-uuid-mpath-360002ac00000000000004b68000124b7"
		},
		"worker2": {
			"connection_info": {
				"driver_volume_type": "iscsi",
				"data": {
					"target_luns": [5, 5],
					"target_iqns": ["iqn.2000-05.com.3pardata:22210002ac0124b7", "iqn.2000-05.com.3pardata:23210002ac0124b7"],
					"target_discovered": true,
					"encrypted": false,
					"target_portals": ["10.213.88.6:3260", "10.213.88.134:3260"],
					"auth_password": "KJwDxdeLaVAts6Vs",
					"auth_username": "lablcactus07.uhclab.lab",
					"auth_method": "CHAP"
				}
			},
			"path": "/dev/dm-24",
			"device_info": {
				"path": "/dev/disk/by-id/dm-uuid-mpath-360002ac00000000000004b68000124b7",
				"scsi_wwn": "360002ac00000000000004b68000124b7",
				"type": "block",
				"multipath_id": "360002ac00000000000004b68000124b7"
			},
			"name": "testvol20",
			"mount_dir": "/opt/hpe/data/hpedocker-dm-uuid-mpath-360002ac00000000000004b68000124b7"
		}
	}
}
```

## Change in 

### In [hpe_storage_api](https://github.com/hpe-storage/python-hpedockerplugin/blob/plugin_v2/hpedockerplugin/hpe_storage_api.py#L692)/VolumeDriver.Mount

```
# Psuedo code for this function to detect various cases in Mount
# For handling cases in : https://github.hpe.com/container-provider/design-guide/blob/master/doc/fencing.md#mount-request

node_id = get_docker_node_id()  # Still need to figure out a way to do this on what returns this

mount_id = ... // got as part of REST call made to /VolumeDriver.Mount endpoint

// Case 3: 
if node_id in  vol[volume_id]['path_info']:
     path_info = {}
     path_info_host = {}
     path_info_host['name'] = volname
     path_info_host['path'] = 
     path_info_host['device_info'] =
     path_info_host['mount_dir'] = 
     path_info_host['mount_ids'].append(mount_id)
     

if node_id not in vol[volume_id]['path_info']:
   number_of_node_entries = len(vol[volume_id]['path_info'].keys())
   # this means some other node_id is present as part of metadata
   # for the volume, so we need to cleanup the mount on that node
   # before we mount the volume on the new node.
   if  number_of_node_entries == 1:
   // Case 1:
      // Give some time for the node_id which has this volume mounted
      // to recover (or) cleanup
      time.sleep(mountConflictDelay)
      // clean the LUN entries on 3PAR Array forcefully for node_id
      // which already has this volume mounted
      # Please note: there is no direct way to forcefully remove the
      # LUN from the 3PAR Array via REST. We might need to use 
      # CLI call : removevlun -f <volume> <nsp> <lun_id> kind of 
      #            operation via SSH.
      
      .
      .
      .
      // Remove the key for the old node which was consuming the volume from the
      // vol[volume_id]['path_info']
      
      // PROCEED WITH THE NORMAL MOUNT
       path_info = {}
       path_info_host = {}
       path_info_host['name'] = volname
       path_info_host['path'] = 
       path_info_host['device_info'] =
       path_info_host['mount_dir'] = 
       path_info_host['mount_ids'].append(mount_id)
       
       path_info[host_name] = path_info_host
       
       self._etcd.update_vol(volid, 'path_info', json.dumps(path_info))
       
   else:
   // Case 2
      if number_of_node_entries == 0:
         // NORMAL MOUNT FLOW
         path_info = {}
         path_info_host = {}
         path_info_host['name'] = volname
         path_info_host['path'] = 
         path_info_host['device_info'] =
         path_info_host['mount_dir'] = 
         path_info_host['mount_ids'].append(mount_id)

         path_info[host_name] = path_info_host
         self._etcd.update_vol(volid, 'path_info', json.dumps(path_info))

```

### Changes in [hpe_storage_api](https://github.com/hpe-storage/python-hpedockerplugin/blob/plugin_v2/hpedockerplugin/hpe_storage_api.py#L290)

## for /VolumeDriver.Unmount
```

if node_id in vol[volume_id]['path_info']:
   path_info_host['mount_ids'][node_id].remove(mount_id)
   
   # Meaning we are done with the all references to this volume by all container(s)
   if len(path_info_host['mount_ids'][node_id]) == 0:
        // PROCEED WITH NORMAL UNMOUNT
   else:
      // Don't proceed with Normal unmount flow, 
      // since some references to this volume is available
      // by other containers on the same node.
      pass
else:
  // PROCEED WITH NORMAL UNMOUNT


```


### Questions

1) How do we derive the node_id of a docker host ?
2) Under what circumstances does the case 5) as mentioned in [fencing.md](https://github.hpe.com/container-provider/design-guide/blob/master/doc/fencing.md#plugin-requirements) 
   will arise ?
3) Will the "mountConflictDelay" parameter be supplied as part of each docker volume creation like
` docker volume create -d hpe --name <vol> -o size=2 -o mountConflictDelay=40` or should be a configuration in /etc/hpedockerplugin/hpe.conf ?

4) Not sure about this. But good to capture this question here. Does the use of replicatedset functionality in k8s , will cause the same volume to be 
used across different minion nodes?

