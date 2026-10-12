import assert from "node:assert/strict";
import test from "node:test";
import type { APIGatewayProxyEventV2 } from "aws-lambda";
import { handler } from "./handler.js";

function createEvent(
  path: string,
  method = "GET",
): APIGatewayProxyEventV2 {
  return {
    version: "2.0",
    routeKey: "$default",
    rawPath: path,
    rawQueryString: "",
    headers: {},
    requestContext: {
      accountId: "123456789012",
      apiId: "test-api",
      domainName: "example.execute-api.eu-west-1.amazonaws.com",
      domainPrefix: "example",
      http: {
        method,
        path,
        protocol: "HTTP/1.1",
        sourceIp: "127.0.0.1",
        userAgent: "node-test",
      },
      requestId: "test-request",
      routeKey: "$default",
      stage: "$default",
      time: "12/Oct/2026:18:00:00 +0000",
      timeEpoch: 1791828000000,
    },
    isBase64Encoded: false,
  };
}

test("GET /health returns a healthy JSON response", async () => {
  const response = await handler(createEvent("/health"));

  assert.equal(response.statusCode, 200);
  assert.equal(
    response.headers?.["content-type"],
    "application/json",
  );
  assert.deepEqual(JSON.parse(response.body ?? ""), {
    status: "ok",
  });
});

test("GET /mockData returns the mock dataset", async () => {
  const response = await handler(createEvent("/mockData"));

  assert.equal(response.statusCode, 200);
  assert.equal(
    response.headers?.["content-type"],
    "application/json",
  );
  assert.deepEqual(JSON.parse(response.body ?? ""), {
    data: [
      "This is a test",
      "I am mock data",
      "Mock data am i",
    ],
  });
});

test("an unknown path returns 404", async () => {
  const response = await handler(createEvent("/missing"));

  assert.equal(response.statusCode, 404);
});

test("POST /health does not execute the GET endpoint", async () => {
  const response = await handler(createEvent("/health", "POST"));

  assert.equal(response.statusCode, 404);
});