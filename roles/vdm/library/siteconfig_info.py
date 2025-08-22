#
# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

from ansible.module_utils.basic import *
import glob
import yaml
import os
import shutil
from enum import Enum

class Overlay(Enum):
    COMPONENT = "components"
    CONFIGURATION = "configurations"
    GENERATOR = "generators"
    RESOURCE = "resources"
    TRANSFORMER = "transformers"

class siteConfig(object):
    def __init__(self, basedir):
        self._overlays = dict()
        self._basedir = os.path.join(basedir, '')

    def add_overlays(self, overlay_type: Overlay, config: str):
        if overlay_type.value in self._overlays:
            self._overlays[overlay_type.value].append(self.remove_basedir(config))
        else:
            self._overlays[overlay_type.value] = [self.remove_basedir(config)]

    def get_overlays(self) -> dict:
        return self._overlays

    def remove_basedir(self, configpath):
        if configpath.startswith(self._basedir):
            return configpath[len(self._basedir):]
        return configpath

    def addResource(self, yamlfile):
        with open(yamlfile) as file:
            yamlblocks = list(yaml.load_all(file, Loader=yaml.SafeLoader))

            if "apiVersion" in yamlblocks[0]:
                if yamlblocks[0]['apiVersion'] == "builtin":
                    if "kind" in yamlblocks[0]:
                        if yamlblocks[0]['kind'].endswith("Transformer"):
                            self.add_overlays(Overlay.TRANSFORMER, yamlfile)
                        elif yamlblocks[0]['kind'].endswith("Generator"):
                            self.add_overlays(Overlay.GENERATOR, yamlfile)
                else:
                    self.add_overlays(Overlay.RESOURCE, yamlfile)
            elif "nameReference" in yamlblocks[0]:
                self.add_overlays(Overlay.CONFIGURATION, yamlfile)

    def processSasBasesOverlays(self, folder):
        sasBasesOverlaysPath = os.path.join(folder, "inject-sas-bases-overlays.yaml")
        if os.path.exists(sasBasesOverlaysPath):
            with open(sasBasesOverlaysPath) as file:
                try:
                    yamlblock = yaml.safe_load(file)
                    for blockName, entries in yamlblock.items():
                        if isinstance(entries, list):
                            try:
                                overlay = Overlay(blockName)
                            except ValueError:
                                continue
                            requiredPrefix = "sas-bases/"
                            for entry in entries:
                                if entry.startswith(requiredPrefix):
                                    self.add_overlays(overlay, entry)
                                else:
                                    raise ValueError(f"Invalid {blockName} entry in {sasBasesOverlaysPath}: '{entry}'. Valid entries must start with '{requiredPrefix}'")
                except yaml.YAMLError as exc:
                    raise RuntimeError(f"Error parsing {sasBasesOverlaysPath} as yaml") from exc

    def traverse(self, folder):
        self.processSasBasesOverlays(folder)

        kustomizefile = None
        if os.path.exists(os.path.join(folder, "kustomization.yaml")):
            kustomizefile = "kustomization.yaml"
        elif os.path.exists(os.path.join(folder, "kustomization.yml")):
            kustomizefile = "kustomization.yml"

        if kustomizefile:
            kustomizefilefullpath = os.path.join(folder, kustomizefile)
            with open(kustomizefilefullpath) as file:
                try:
                    yamlblock = yaml.safe_load(file)
                    if "kind" in yamlblock and yamlblock['kind'] == "Component":
                        self.add_overlays(Overlay.COMPONENT, folder)
                    else:
                        self.add_overlays(Overlay.RESOURCE, folder)
                        search = []
                        for k, v in yamlblock.items():
                            if isinstance(v, list):
                                search.extend(v)

                        yamlfiles = glob.glob(os.path.join(folder, "*.yaml"))
                        yamlfiles.extend(glob.glob(os.path.join(folder, "*.yml")))

                        for yamlfile in yamlfiles:
                            if os.path.relpath(yamlfile, folder) not in search:
                                self.addResource(yamlfile)

                except yaml.YAMLError as exc:
                    raise RuntimeError(f"Error parsing {kustomizefilefullpath} as yaml") from exc
            return

        for f in next(os.walk(folder))[1]:
            self.traverse(os.path.join(folder, f))

        yamlfiles = glob.glob(os.path.join(folder, "*.yaml"))
        yamlfiles.extend(glob.glob(os.path.join(folder, "*.yml")))

        for yamlfile in yamlfiles:
            self.addResource(yamlfile)

    def setup_certificates(self):
        cert_src = os.path.join(self._basedir, "sas-bases/examples/sas-decisions-runtime-builder/buildkit/cert")
        cert_dst = os.path.join(self._basedir, "site-config/sas-decisions-runtime-builder/buildkit/certs")
        os.makedirs(cert_dst, exist_ok=True)

        for file in glob.glob(os.path.join(cert_src, "*.pem")):
            shutil.copy(file, cert_dst)

        cert_files = [os.path.basename(f) for f in glob.glob(os.path.join(cert_dst, "*.pem"))]

        kustomize_path = os.path.join(cert_dst, "kustomization.yaml")
        kustomize_data = {
            "resources": [],
            "secretGenerator": [
                {
                    "name": "sas-buildkit-registry-secrets",
                    "files": cert_files
                }
            ]
        }

        with open(kustomize_path, "w") as f:
            yaml.dump(kustomize_data, f)

    def update_base_kustomization(self):
        base_kustomize_path = os.path.join(self._basedir, "kustomization.yaml")
        if not os.path.exists(base_kustomize_path):
            return

        with open(base_kustomize_path) as f:
            data = yaml.safe_load(f)

        data.setdefault("resources", [])
        data.setdefault("transformers", [])

        new_resources = [
            "site-config/sas-decisions-runtime-builder/buildkit/config",
            "site-config/sas-decisions-runtime-builder/buildkit/certs"
        ]
        for res in new_resources:
            if res not in data["resources"]:
                data["resources"].append(res)

        cert_transformer = "sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-certificate-transformer.yaml"
        if cert_transformer not in data["transformers"]:
            try:
                idx = data["transformers"].index("sas-bases/overlays/sas-decisions-runtime-builder/buildkit/buildkit-transformer.yaml")
                data["transformers"].insert(idx + 1, cert_transformer)
            except ValueError:
                data["transformers"].append(cert_transformer)

        with open(base_kustomize_path, "w") as f:
            yaml.dump(data, f)

def main():
    fields = {
        "path": {"required": True, "type": "str"},
        "exclude": {"default": [], "type": list},
    }
    module = AnsibleModule(argument_spec=fields)
    try:
        sc = siteConfig(module.params['path'])
        sc.setup_certificates()
        sc.update_base_kustomization()

        scFolder = os.path.join(module.params['path'], 'site-config')
        _, folders, _ = next(os.walk(scFolder))
        for folder in folders:
            if folder not in module.params['exclude']:
                sc.traverse(os.path.join(scFolder, folder))

        module.exit_json(changed=True, overlays=sc.get_overlays())
    except StopIteration:
        pass
    except Exception as e:
        module.fail_json(error=e, msg="Error parsing site-config path")
        raise

if __name__ == '__main__':
    main()