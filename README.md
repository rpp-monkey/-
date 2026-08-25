#!/bin/bash
set -e
git clone https://github.com/mattermost/docker
cd docker


echo "=== 1. Docker & Docker Compose インストール ==="
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  docker.io docker-compose

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

# SiteURL を http に変更
sed -i 's|^MM_SERVICESETTINGS_SITEURL=.*|MM_SERVICESETTINGS_SITEURL=http://${DOMAIN}|' .env

echo "=== 3. ボリュームディレクトリの作成と権限設定 ==="
mkdir -p ./volumes/app/mattermost/{config,data,logs,plugins,client/plugins,bleve-indexes}
sudo chown -R 2000:2000 ./volumes/app/mattermost

echo "=== 4. Mattermost コンテナの起動 ==="
sudo docker compose -f docker-compose.yml -f docker-compose.without-nginx.yml up -d

echo "=========================================="
echo " 起動が完了しました！"
echo " ブラウザから http://localhost:8065 にアクセスしてください。"
echo "=========================================="
