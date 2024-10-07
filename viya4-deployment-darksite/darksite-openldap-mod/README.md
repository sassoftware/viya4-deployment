
## Mod roles/vdm/templates/resources/openldap.yaml

- Only required if using an internal OpenLDAP server.  By default, the cluster will reach out to docker hub to pull this image, and in a darksite this isn't possible.
- Run the darksite-openldap-mod.sh script.
- Build the modded container using the script or manually if you'd like.