import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";

// Reuse the client across invocations in this execution environment.
const client = new SecretsManagerClient({ maxAttempts: 2 });

const CACHE_TTL_MS = 60_000;

let cached: { apiKey: string; expiresAt: number } | undefined;

export async function getDownstreamApiKey(): Promise<string> {
  if (cached && Date.now() < cached.expiresAt) {
    return cached.apiKey;
  }

  const secretArn = process.env.API_SECRET_ARN;

  if (!secretArn) {
    throw new Error("Missing API_SECRET_ARN configuration");
  }

  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: secretArn,
    }),
    {
      abortSignal: AbortSignal.timeout(2_000),
    },
  );

  if (!response.SecretString) {
    throw new Error("Expected a string secret");
  }

  const value: unknown = JSON.parse(response.SecretString);

  if (
    typeof value !== "object" ||
    value === null ||
    !("apiKey" in value) ||
    typeof value.apiKey !== "string" ||
    value.apiKey.trim().length === 0
  ) {
    throw new Error("Secret must contain a non-empty apiKey");
  }

  cached = {
    apiKey: value.apiKey,
    expiresAt: Date.now() + CACHE_TTL_MS,
  };

  return cached.apiKey;
}