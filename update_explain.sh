#!/bin/sh

set -e

zigmod explain --format tree > __snapshots__/explain.tree.txt
zigmod explain --format mermaid > __snapshots__/explain.mermaid.txt
zigmod explain --format dot > __snapshots__/explain.dot.txt
