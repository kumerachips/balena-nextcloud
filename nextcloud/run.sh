#!/usr/bin/env bash

# update trusted_domains in config.php
if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS:-}" ]
then
    domain_idx=0
    for domain in ${NEXTCLOUD_TRUSTED_DOMAINS}
    do
        domain=$(echo "${domain}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        sudo -E -u www-data php /var/www/html/occ config:system:set trusted_domains ${domain_idx} --value="${domain}"
        domain_idx=$((domain_idx+1))
    done
fi

# automount USB device partitions at /media/{UUID}
for uuid in $(blkid -sUUID -ovalue -t LABEL=NEXTCLOUD)
do
    {
        mkdir -pv /media/"${uuid}"
        
        # Try mounting with explicit www-data (uid 33, gid 33) ownership for FAT/NTFS/exFAT
        mount -v -o uid=33,gid=33,umask=002 UUID="${uuid}" /media/"${uuid}" \
        || mount -v UUID="${uuid}" /media/"${uuid}" # Fallback for ext4
        
        # Ensure ownership for Linux-native filesystems (ext4)
        chown -R www-data:www-data /media/"${uuid}"
        chmod -R 775 /media/"${uuid}"
    } || continue
done

exec php-fpm
