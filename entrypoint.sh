#!/bin/bash
set -e

# データベースのマイグレーションを実行
echo "Running database migrations..."
bundle exec rails db:migrate

# コンテナのメインプロセス（DockerfileでCMDと設定されているもの）を実行する
exec "$@"
