#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import hashlib
import os
import sys
import yaml


def parse_args():
    p = argparse.ArgumentParser(description="GitOps")
    p.add_argument("--username", default="nalbam", help="username")
    p.add_argument("--reponame", default="sample-node", help="reponame")
    p.add_argument("--version", default="v0.0.0", help="version")
    p.add_argument("--phase", default="demo-dev", help="phase")
    return p.parse_args()


def replace_deployment(args, cm_hasg, sec_hash):
    filepath = "{}/{}/deployment.yaml".format(args.reponame, args.phase)
    filehash = ""

    if os.path.exists(filepath):
        doc = []

        with open(filepath, "r") as file:
            doc = yaml.load(file, Loader=yaml.FullLoader)

            image = "{}/{}:{}".format(args.username, args.reponame, args.version)

            doc["spec"]["template"]["metadata"]["labels"]["version"] = args.version

            containers = doc["spec"]["template"]["spec"]["containers"]

            containers[0]["env"]["image"] = image

            for i, env in enumerate(containers[0]["env"]):
                if env["name"] == "CONFIGMAP_HASH":
                    env["value"] = cm_hasg
                if env["name"] == "SECRET_HASH":
                    env["value"] = sec_hash

            # print(doc["spec"]["template"]["metadata"]["labels"]["version"])
            # print(doc["spec"]["template"]["spec"]["containers"][0]["image"])

            # print(doc["spec"]["template"]["spec"]["containers"][0]["env"])
            # print(doc["spec"]["template"]["spec"]["containers"][0]["env"][0]["name"])
            # print(doc["spec"]["template"]["spec"]["containers"][0]["env"][1]["name"])

        if doc != None:
            with open(filepath, "w") as file:
                yaml.dump(doc, file)


def replace_configmap(args):
    filepath = "{}/{}/configmap.yaml".format(args.reponame, args.phase)
    filehash = ""

    if os.path.exists(filepath):
        doc = []

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
        doc = []

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
