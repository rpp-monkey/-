#!/bin/bash
set -e

# リポジトリのクローン（既存の場合はスキップ）
if [ ! -d "docker" ]; then
    git clone https://github.com/mattermost/docker
fi
cd docker

echo "=== 1. Docker & Docker Compose インストール ==="
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  docker.io docker-compose openssl

# Docker サービスの起動 & 自動起動有効化
sudo systemctl enable --now docker

echo "=== 2. .env ファイルの作成と設定変更 ==="
if [ ! -f "env.example" ]; then
    echo "エラー: $(pwd) に env.example が見つかりません。"
    exit 1
fi

# env.example をコピーして .env を作成
cp env.example .env

# ドメインを localhost に変更
sed -i 's/^DOMAIN=.*/DOMAIN=localhost/' .env

# タイムゾーンを Asia/Tokyo に変更
sed -i 's/^TZ=.*/TZ=Asia\/Tokyo/' .env

# Edition を mattermost-team-edition に変更
sed -i 's/^MATTERMOST_IMAGE=.*/MATTERMOST_IMAGE=mattermost-team-edition/' .env

# SiteURL を https に変更（デフォルトが https のためそのままでも可ですが明示的に指定）
sed -i 's|^MM_SERVICESETTINGS_SITEURL=.*|MM_SERVICESETTINGS_SITEURL=https://${DOMAIN}|' .env

echo "=== 3. ボリューム・SSL証明書の作成と権限設定 ==="
# アプリ用ディレクトリ作成
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

# NGINX用の自己署名SSL証明書を自動作成
mkdir -p ./volumes/web/cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./volumes/web/cert/key.pem \
  -out ./volumes/web/cert/cert.pem \
  -subj "/CN=localhost"

echo "=== 4. Mattermost コンテナの起動（NGINX込み） ==="
# 付属の NGINX を利用するデフォルト構成で起動（ポート 443 を利用）
sudo docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d

echo "=========================================="
echo " 起動が完了しました！"
echo " ブラウザから https://localhost にアクセスしてください。"
echo " （※自己署名証明書のため警告が出ますが、「詳細」→「アクセスを続ける」で進んでください）"
echo "=========================================="