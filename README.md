# fakedoamin-proxy

特定のドメインを内部のnginxに転送するDockerコンテナです。
公開されている実ドメインでテストサーバを試験する際に便利です。

# Quick Start

	$ docker-compose build
	$ docker-compose up -d

Firefoxなどのhttp, https プロクシとして localhost:8888 を指定します。 https://example/ にアクセスすると、ページが表示されますが、自己署名なので警告がでるので許可して進んで下さい。

コンテナ内のlocalhostではnginx, dnsmasq, tinyproxyが起動しています。localhost:80, localhost:443はnginxへのアクセスになりますので、nginxを調整することでいろいろな利用が可能です。

