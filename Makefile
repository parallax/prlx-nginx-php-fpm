all:
	
linux:
	docker build -t prlx-nginx-php-fpm:earth-7.1 -f Dockerfile-7.1 .
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.1 --config test/test-7.1.yaml
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.1 --config test/test-all.yaml
	docker build -t prlx-nginx-php-fpm:earth-7.2 -f Dockerfile-7.2 .
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.2 --config test/test-7.2.yaml
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.2 --config test/test-all.yaml
	docker build -t prlx-nginx-php-fpm:earth-7.3 -f Dockerfile-7.3 .
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.3 --config test/test-7.3.yaml
	./container-structure-test-linux-amd64 test --image prlx-nginx-php-fpm:earth-7.3 --config test/test-all.yaml

darwin:
	docker build -t prlx-nginx-php-fpm:earth-7.1 -f Dockerfile-7.1 .
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.1 --config test/test-7.1.yaml
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.1 --config test/test-all.yaml
	docker build -t prlx-nginx-php-fpm:earth-7.2 -f Dockerfile-7.2 .
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.2 --config test/test-7.2.yaml
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.2 --config test/test-all.yaml
	docker build -t prlx-nginx-php-fpm:earth-7.3 -f Dockerfile-7.3 .
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.3 --config test/test-7.3.yaml
	./container-structure-test-darwin-amd64 test --image prlx-nginx-php-fpm:earth-7.3 --config test/test-all.yaml