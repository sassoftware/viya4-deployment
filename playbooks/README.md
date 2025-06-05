### Viya4 DaC playbook overview
1. **Create Global Temporary Directory**
    
    - Task: `Global tmp dir`
    - Action: Creates a temporary directory for use during the playbook run.
    - Tags: `install`, `uninstall`, `update`, `onboard`, `cas-onboard`, `offboard`
    - **Networking Considerations:** No anticipated network impact.
2. **Run Task Validations from Common Role**
    
    - Task: `Common role - task validations`
    - Action: Includes `common` role’s `task-validations` tasks.
    - Tags: `always` (runs every time)
    - **Networking Considerations:** No anticipated network impact.
3. **Include Main Tasks from Common Role**
    
    - Task: `Common role`
    - Action: Includes the main tasks from the `common` role, making its variables public.
    - Tags: `install`, `uninstall`, `update`, `onboard`, `cas-onboard`, `offboard`
    - **Networking Considerations:** No anticipated network impact.
4. **Optionally Include Jump-Server Role**
    
    - Task: `jump-server role`
    - Action: Includes the `jump-server` role.
    - Condition: Runs only if all of these are defined: `JUMP_SVR_HOST`, `JUMP_SVR_USER`, `JUMP_SVR_PRIVATE_KEY`, `V4_CFG_MANAGE_STORAGE` and if `V4_CFG_MANAGE_STORAGE` is `true`.
    - Tags: `viya`
    - **Networking Considerations:** May require SSH access to the jump server and NFS server. See [networking-considerations.md](../docs/networking-considerations.md)
5. **Optionally Include Baseline Role for Install**
    
    - Task: `baseline role install`
    - Action: Includes the `baseline` role for install actions.
    - Condition: Runs only if both `'baseline'` and `'install'` are in `ansible_run_tags`.
    - Tags: `baseline`
    - **Networking Considerations:** Deploys core components (ingress-nginx, cert-manager, metrics-server, csi-driver-nfs, ebs-csi-driver, etc.) that impact cluster networking, ingress, and storage. See [networking-considerations.md](../docs/networking-considerations.md)
6. **Optionally Include Multi-Tenancy Role**
    
    - Task: `Multi-tenancy role`
    - Action: Includes the `multi-tenancy` role.
    - Condition: Runs only if `V4MT_ENABLE` is defined.
    - Tags: `multi-tenancy`
    - **Networking Considerations:** May create namespaces and network policies. See [networking-considerations.md](../docs/networking-considerations.md)
7. **Include VDM Role**
    
    - Task: `vdm role`
    - Action: Includes the `vdm` role.
    - Tags: `viya`, `multi-tenancy`
    - **Networking Considerations:** May create services and resources that affect networking within the cluster.
8. **Optionally Include Baseline Role for Uninstall**
    
    - Task: `baseline role uninstall`
    - Action: Includes the `baseline` role for uninstall actions.
    - Condition: Runs only if both `'baseline'` and `'uninstall'` are in `ansible_run_tags`.
    - Tags: `baseline`
    - **Networking Considerations:** Removes core components and may affect networking and storage resources. See [networking-considerations.md](../docs/networking-considerations.md)
9. **Delete Temporary Directory**
    
    - Task: `Delete tmpdir`
    - Action: Removes the temporary directory created at the start.
    - Tags: `install`, `uninstall`, `update`
    - **Networking Considerations:** No anticipated network impact.
**Summary:**
- Tasks are executed in the order listed above.
- Some tasks/roles are conditionally included based on variables or tags.
- The playbook is designed to be flexible for different deployment scenarios by using tags and conditions.
- For a detailed summary of networking considerations, see [networking-considerations.md](../docs/networking-impact.md)
