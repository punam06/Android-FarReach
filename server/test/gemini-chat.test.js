const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateTravelReply, refusal } = require('../gemini-chat');

function reply(value, status = 200) {
  return { ok: status === 200, status, json: async () => ({ candidates: [{ content: { parts: [{ text: JSON.stringify(value) }] } }] }) };
}

test('Gemini receives the scope policy and bounded history, then returns a travel answer', async () => {
  let request;
  const result = await generateTravelReply({
    apiKey: 'test-key',
    message: 'Plan a Cox’s Bazar trip',
    history: [{ role: 'user', message: 'I have three days' }, { role: 'assistant', message: 'What is your budget?' }],
    context: 'Matching catalog destinations: Cox’s Bazar Sea Beach (Cox’s Bazar)',
    fetchImpl: async (url, options) => { request = { url, options }; return reply({ in_scope: true, reply: 'Use Explore and the budget calculator.' }); },
  });
  assert.equal(result.inScope, true);
  assert.match(result.reply, /Explore/);
  assert.equal(request.options.headers['x-goog-api-key'], 'test-key');
  const body = JSON.parse(request.options.body);
  assert.match(body.systemInstruction.parts[0].text, /in_scope: false/);
  assert.match(body.systemInstruction.parts[0].text, /day-by-day outline/);
  assert.match(body.systemInstruction.parts[0].text, /Cox’s Bazar Sea Beach/);
  assert.deepEqual(body.contents.map(item => item.role), ['user', 'model', 'user']);
  assert.equal(body.contents[2].parts[0].text, 'Plan a Cox’s Bazar trip');
});

test('out-of-scope generated text is discarded by the server', async () => {
  const result = await generateTravelReply({
    apiKey: 'test-key', message: 'Explain algebra',
    fetchImpl: async () => reply({ in_scope: false, reply: 'An algebra answer that must not be shown.' }),
  });
  assert.deepEqual(result, { inScope: false, reply: refusal });
});

test('invalid or failed Gemini replies do not become chat answers', async () => {
  await assert.rejects(generateTravelReply({ apiKey: 'test-key', message: 'Trip', fetchImpl: async () => reply({ reply: 'Missing classification' }) }), /invalid reply/);
  await assert.rejects(generateTravelReply({ apiKey: 'test-key', message: 'Trip', fetchImpl: async () => reply({}, 429) }), /429/);
});
