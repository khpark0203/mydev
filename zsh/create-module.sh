#!/bin/sh

MODULE_NAME="$1"

# MODULE_NAME에 .이 있으면 /로 변환
MODULE_PATH=$(echo "$MODULE_NAME" | sed 's/\./\//g')

if [ -z "$MODULE_NAME" ]; then
  SCRIPT_NAME=$(basename "$0")
  echo "Usage: $SCRIPT_NAME <module-name>"
  echo "Example: $SCRIPT_NAME com.example.demo"
  exit 1
fi

# Create module directory

mkdir -p "$PWD/src/main/java/$MODULE_PATH"
mkdir -p "$PWD/src/main/resources"
mkdir -p "$PWD/src/test/java/$MODULE_PATH"
touch "$PWD/build.gradle.kts"