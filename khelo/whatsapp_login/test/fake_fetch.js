// Preloaded in tests: WhatsApp sends are printed as JSON lines instead of sent.
globalThis.fetch = async (url, options) => {
  const body = JSON.parse(options.body);
  process.stdout.write(`SENT ${JSON.stringify({ url, to: body.to, text: body.text.body })}\n`);
  return { ok: true, status: 200, text: async () => '{}' };
};
