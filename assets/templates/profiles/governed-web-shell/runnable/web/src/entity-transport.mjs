export function registerAgentRunTransport({ endpoint, fetchImpl = fetch }) {
  return {
    async create(input, signal) {
      const response = await fetchImpl(`${endpoint}/api/v1/agent/runs`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(input),
        signal,
      });
      if (!response.ok) throw new Error(`agent gateway failed: ${response.status}`);
      return response.json();
    },
  };
}
