use lambda_runtime::{run, service_fn, tracing, Error, LambdaEvent};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Request {
    name: String,
}
#[derive(Serialize)]
struct Response {
    message: String,
}

#[tracing::instrument(skip(event), fields(req_id = %event.context.request_id))]
async fn function_handler(event: LambdaEvent<Request>) -> Result<Response, Error> {
    // Extract request payload
    let name = event.payload.name;
    // Log the request payload
    tracing::info!("Received payload: {name}");
    // Prepare the response
    let resp = Response {
        message: format!("Hello, {}!", name),
    };
    // Log & return response
    tracing::info!(resp.message);
    Ok(resp)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .json()
        .with_max_level(tracing::Level::INFO)
        .with_current_span(false)
        .without_time()
        .with_target(false)
        .init();

    run(service_fn(function_handler)).await
}
