#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import hashlib
import os
import sys
import yaml


REPONAME = "nalbam-docs"
PHASE = "demo-dev"

IMAGENAME = "nalbam/docs"
VERSION = "v0.0.0"


def parse_args():
    p = argparse.ArgumentParser(description="GitOps")
    p.add_argument("--reponame", default=REPONAME, help="reponame")
    p.add_argument("--phase", default=PHASE, help="phase")
    p.add_argument("--imagename", default=IMAGENAME, help="imagename")
    p.add_argument("--version", default=VERSION, help="version")
    return p.parse_args()


def replace_deployment(args, cm_hasg, sec_hash):
    filepath = "{}/{}/deployment.yaml".format(args.reponame, args.phase)
    filehash = ""

    if os.path.exists(filepath):
        doc = None

        with open(filepath, "r") as file:
            doc = yaml.load(file, Loader=yaml.FullLoader)

            doc["spec"]["template"]["metadata"]["labels"]["version"] = args.version

            containers = doc["spec"]["template"]["spec"]["containers"]

            containers[0]["image"] = "{}:{}".format(args.imagename, args.version)

            if "env" in containers[0]:
                for i, env in enumerate(containers[0]["env"]):
                    if env["name"] == "CONFIGMAP_HASH":
                        env["value"] = cm_hasg
                    if env["name"] == "SECRET_HASH":
                        env["value"] = sec_hash

        if doc != None:
            with open(filepath, "w") as file:
                yaml.dump(doc, file)


def replace_configmap(args):
    filepath = "{}/{}/configmap.yaml".format(args.reponame, args.phase)
    filehash = ""

    if os.path.exists(filepath):
        doc = None

        with open(filepath, "r") as file:
            doc = yaml.load(file, Loader=yaml.FullLoader)

            print(doc["data"]["VERSION"])

            doc["data"]["VERSION"] = args.version

            print(doc["data"]["VERSION"])

        if doc != None:
            with open(filepath, "w") as file:
                yaml.dump(doc, file)

            with open(filepath, "rb") as file:
                filehash = hashlib.md5(file.read()).hexdigest()

    return filehash


def replace_secret(args):
    filepath = "{}/{}/secret.yaml".format(args.reponame, args.phase)
    filehash = ""

    if os.path.exists(filepath):
        doc = None

        with open(filepath, "r") as file:
            doc = yaml.load(file, Loader=yaml.FullLoader)

        if doc != None:
            with open(filepath, "w") as file:
                yaml.dump(doc, file)

            with open(filepath, "rb") as file:
                filehash = hashlib.md5(file.read()).hexdigest()

    return filehash


def run():
    args = parse_args()

    chash = replace_configmap(args)
    shash = replace_secret(args)

    replace_deployment(args, chash, shash)


if __name__ == "__main__":
    run()
