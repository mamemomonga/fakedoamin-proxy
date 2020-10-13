# fakedoamin-proxy

特定のドメインを内部のnginxに転送するDockerコンテナです。
公開されている実ドメインでテストサーバを試験する際に便利です。

# Quick Start

	$ docker-compose build
	$ docker-compose up -d

Firefoxなどのhttpプロクシとして localhost:8888 を指定します。 https://example/ にアクセスすると、ページが表示されます。証明書は自己署名なので警告がでるので許可して進んで下さい。

証明書には複数のドメインを設定することが可能です。

コンテナ内のlocalhostではnginx, dnsmasq, tinyproxyが起動しています。localhost:80, localhost:443はnginxへのアクセスになりますので、nginxを調整することでいろいろな利用が可能です。

