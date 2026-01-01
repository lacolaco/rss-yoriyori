.PHONY: up down logs test deploy init plan apply

PROJECT_ID := rss-yoriyori
TAG := $(shell git rev-parse --short HEAD)

# ローカル開発
up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f

test:
	docker compose run --rm --build test

# 本番デプロイ（GitHub Actions amd64環境で実行）
deploy:
	TAG=$(TAG) docker buildx bake --push
	cd terraform && terraform apply -var="project_id=$(PROJECT_ID)" -var="image_tag=$(TAG)" -auto-approve

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan -var="project_id=$(PROJECT_ID)" -var="image_tag=$(TAG)"
