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
	"node_mount_info": {
	                        "worker1" : ["adfadsf2323eae","234asfasdf4r"],
				"worker2" : ["34sdfasdfasdf2","234asdfa35s"]
			},
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

## Change in code
- [hpe_storage_api]()
- [utils.py]()



### Questions

1) How do we derive the node_id of a docker host ? (or) can we use the plain host name on which the docker engine is running ?
2) Under what circumstances does the case 5) as mentioned in [fencing.md](https://github.hpe.com/container-provider/design-guide/blob/master/doc/fencing.md#plugin-requirements) 
   will arise ?
3) Will the "mountConflictDelay" parameter be supplied as part of each docker volume creation like
` docker volume create -d hpe --name <vol> -o size=2 -o mountConflictDelay=40` or should be a configuration in /etc/hpedockerplugin/hpe.conf ?

4) Not sure about this. But good to capture this question here. Does the use of replicatedset functionality in k8s , will cause the same volume to be 
used across different minion nodes?

