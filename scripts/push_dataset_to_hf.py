#!/usr/bin/env python3
"""
Push a local dataset folder to the Hugging Face Hub as a dataset repository.

Example:
  export HF_TOKEN=your_token_here
  python scripts/push_dataset_to_hf.py \
      --path ~/ws/lerobot/so101-custom-training/witsense-ai/so101_pick_and_place_ring_20260613_182839 \
      --repo-id witsense-ai/so101_pick_and_place_ring \
      --private

This script uses `huggingface_hub.upload_folder` and will create the dataset
repo if it does not exist. It expects `huggingface_hub` to be installed.
"""

from __future__ import annotations

import argparse
import logging
import os
import sys

try:
    from huggingface_hub import HfApi, upload_folder
except Exception:  # pragma: no cover - helpful error for users
    print(
        "huggingface_hub is required. Install with: pip install huggingface_hub",
        file=sys.stderr,
    )
    raise


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Push a local dataset folder to HF Hub")
    p.add_argument("--path", required=True, help="Local dataset folder to upload")
    p.add_argument("--repo-id", required=True, help="HF repo id (user_or_org/repo_name)")
    p.add_argument("--token", default=None, help="HF token (or set HF_TOKEN env var)")
    p.add_argument("--private", action="store_true", help="Create dataset as private")
    p.add_argument("--message", default="Add dataset files", help="Commit message for upload")
    p.add_argument(
        "--path-in-repo",
        default="",
        help="Optional subpath inside the dataset repo to upload into",
    )
    p.add_argument(
        "--ignore",
        nargs="*",
        default=None,
        help="Ignore patterns (glob) to pass to upload_folder",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    token = args.token or os.environ.get("HF_TOKEN") or os.environ.get("HF_HUB_TOKEN")
    if not token:
        print("Please set HF_TOKEN environment variable or pass --token", file=sys.stderr)
        return 2

    folder = os.path.abspath(args.path)
    if not os.path.isdir(folder):
        print(f"Path does not exist or is not a directory: {folder}", file=sys.stderr)
        return 3

    api = HfApi()
    try:
        api.create_repo(
            repo_id=args.repo_id,
            repo_type="dataset",
            private=bool(args.private),
            token=token,
            exist_ok=True,
        )
    except Exception as exc:  # pragma: no cover - surfacing errors is useful
        logging.warning("create_repo returned error (continuing if repo exists): %s", exc)

    print(f"Uploading folder {folder} to datasets/{args.repo_id} ...")

    upload_folder(
        folder_path=folder,
        path_in_repo=args.path_in_repo or "",
        repo_id=args.repo_id,
        repo_type="dataset",
        token=token,
        commit_message=args.message,
        ignore_patterns=args.ignore,
    )

    print(f"Upload complete: https://huggingface.co/datasets/{args.repo_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
