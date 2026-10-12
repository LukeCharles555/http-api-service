import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyStructuredResultV2,
} from "aws-lambda";

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyStructuredResultV2> => {
  const { method, path } = event.requestContext.http;

  if (method === "GET") {
    switch(path) {
        case "/health": {
            return {
              statusCode: 200,
              headers: { "content-type": "application/json" },
              body: JSON.stringify({ status: "ok" }),
            };
        }
        case "/mockData": {
            return {
                statusCode: 200,
                headers: { "content-type": "application/json" },
                body: JSON.stringify({data: ["This is a test", "I am mock data", "Mock data am i"]})
            }
        }
        default: {
            return {
                statusCode: 404,
                headers: { "content-type": "application/json" },
                body: JSON.stringify({ error: "Oh no! Path not found"})
            }
        }
    }
  }

  return {
    statusCode: 404,
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ message: "Not found" }),
  };
};