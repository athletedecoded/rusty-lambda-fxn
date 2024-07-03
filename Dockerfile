####################################
#   STAGE 0: Build rusty-lambda-fxn
####################################
FROM rust:1-bullseye as builder

WORKDIR /usr/src/app
COPY .. .

RUN cargo build --release

####################################
#   STAGE 1: Build Amazon 2023 Base OS Image
####################################
FROM public.ecr.aws/lambda/provided:al2023

## Install dependencies
RUN dnf update -y && \
      dnf install -y clang

# Copy lambda fxn binary to image
# NB: Update to match your fxn name
COPY --from=builder /usr/src/app/target/release/rusty-lambda-fxn /usr/local/bin/rusty-lambda-fxn

# Define entrypoint
# NB: Update to match your fxn name
ENTRYPOINT ["/usr/local/bin/rusty-lambda-fxn"]