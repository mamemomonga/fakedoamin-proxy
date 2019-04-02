# fakedoamin-proxy

特定のドメインを内部のnginxに転送するDockerコンテナです。
公開されている実ドメインでテストサーバを試験する際に便利です。

自己署名証明書生成機能つき(Alternative Name)

# 必要なもの

* Docker
* docker-compose
* make

# 使い方

	$ cp config.example config
	$ vim config
	$ make
	ログが表示されたらCTRL+C

