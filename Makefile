include .env

format:
	cargo fmt --quiet

lint:
	cargo clippy --quiet

install-lambda:
	curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
	cargo binstall cargo-lambda
	chmod +x zig-installer.sh && ./zig-installer.sh

install-emulator:
	# https://github.com/aws/aws-lambda-runtime-interface-emulator
	mkdir -p ~/.aws-lambda-rie && \
    curl -Lo ~/.aws-lambda-rie/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x ~/.aws-lambda-rie/aws-lambda-rie

build-container:
	docker build --platform linux/amd64 -t ${LAMBDA_FXN} .

local-container:
	docker run --env-file .env -d -p 9000:8080 --entrypoint /usr/local/bin/aws-lambda-rie ${LAMBDA_FXN}:latest ${LAMBDA_FXN}

ecr-login:
	aws ecr get-login-password --profile rusty-lambda-dev --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

ecr-repo:
	aws ecr --profile rusty-lambda-dev --region ${AWS_DEFAULT_REGION} create-repository --repository-name ${LAMBDA_FXN} > /dev/null

deploy-container:
	docker tag ${LAMBDA_FXN}:latest ${AWS_ACCT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${LAMBDA_FXN}:latest
	docker push ${AWS_ACCT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${LAMBDA_FXN}:latest

deploy-lambda:
	aws lambda create-function \
		--profile rusty-lambda-dev \
		--region ${AWS_DEFAULT_REGION} \
		--function-name ${LAMBDA_FXN} \
		--package-type Image \
		--code ImageUri=${AWS_ACCT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${LAMBDA_FXN}:latest \
		--role arn:aws:iam::${AWS_ACCT_ID}:role/${LAMBDA_FXN}-role \
		> /dev/null

invoke:
	cargo lambda invoke --remote --profile rusty-lambda-dev --region ${AWS_DEFAULT_REGION} --data-ascii '{ "name": "World"}' --output-format json ${LAMBDA_FXN}

update-lambda:
	aws lambda update-function-code \
		--profile rusty-lambda-dev \
		--region ${AWS_DEFAULT_REGION} \
		--function-name ${LAMBDA_FXN} \
		--image-uri ${AWS_ACCT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${LAMBDA_FXN}:latest \
		> /dev/null

deploy-zip:
	cargo lambda build --release
	cargo lambda deploy --profile rusty-lambda-dev --region ${AWS_DEFAULT_REGION} --iam-role arn:aws:iam::${AWS_ACCT_ID}:role/${LAMBDA_FXN}-role