import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp, validateItems, validDay } from './server.mjs';
const token = 'test-local-token-with-more-than-24-chars';
const item = {kind: 'expense', title: 'Hospedagem', area: 'Empresa', date: '2026-10-05', priority: 1, amountCents: 8900};
const mockPayload = value => ({ok: true, json: async () => ({status: 'completed', output: [{type: 'message', content: [{type: 'output_text', text: JSON.stringify(value)}]}]})});
async function withServer(fn, options = {}) {
  const app = createApp({env: {LOCAL_API_TOKEN: token, OPENAI_API_KEY: 'fake-key-for-tests', ...options.env}, fetchImpl: options.fetchImpl ?? (async () => mockPayload({items: [item]}))});
  await new Promise(resolve => app.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${app.address().port}`;
  try { await fn(base); } finally { await new Promise(resolve => app.close(resolve)); }
}
function post(base, body = {text: 'Paguei 89 reais de hospedagem', today: '2026-10-05'}, headers = {}) {
  return fetch(`${base}/api/capture`, {method: 'POST', headers: {'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...headers}, body: JSON.stringify(body)});
}
test('validação rejeita valores negativos, datas inválidas e registros incompletos', () => {
  assert.equal(validDay('2026-02-30'), false);
  assert.equal(validDay('2024-02-29'), true);
  assert.throws(() => validateItems({items: [{...item, amountCents: -1}]}));
  assert.throws(() => validateItems({items: [{...item, date: '2026-02-30'}]}));
  assert.throws(() => validateItems({items: [{...item, kind: 'task'}]}));
  assert.deepEqual(validateItems({items: [item]}), {items: [item]});
});
test('saúde e captura autorizada funcionam', async () => withServer(async base => {
  assert.equal((await fetch(`${base}/health`)).status, 200);
  const result = await post(base); assert.equal(result.status, 200); assert.deepEqual(await result.json(), {items: [item]});
}));
test('credencial incorreta bloqueia chamada upstream', async () => withServer(async base => {
  const result = await post(base, undefined, {Authorization: 'Bearer wrong'}); assert.equal(result.status, 401);
}, {fetchImpl: () => { throw new Error('Não deve chamar upstream'); }}));
test('entrada inválida e excesso de tamanho são rejeitados', async () => withServer(async base => {
  assert.equal((await post(base, {text: '', today: '2026-10-05'})).status, 400);
  assert.equal((await post(base, {text: 'A'.repeat(3001), today: '2026-10-05'})).status, 400);
  assert.equal((await post(base, {text: 'A'.repeat(20000), today: '2026-10-05'})).status, 400);
}));
test('CORS aceita origem local e bloqueia origem externa', async () => withServer(async base => {
  const local = await post(base, undefined, {Origin: 'http://localhost:5173'});
  assert.equal(local.headers.get('access-control-allow-origin'), 'http://localhost:5173');
  assert.equal((await post(base, undefined, {Origin: 'https://malicious.example'})).status, 403);
}));
test('falha da OpenAI não expõe chave nem detalhes internos', async () => withServer(async base => {
  const response = await post(base); assert.equal(response.status, 502); assert.equal((await response.text()).includes('fake-key'), false);
}, {fetchImpl: async () => ({ok: false, status: 401})}));
test('JSON inválido do modelo é tratado', async () => withServer(async base => {
  assert.equal((await post(base)).status, 502);
}, {fetchImpl: async () => mockPayload({items: [{...item, amountCents: 1.5}]})}));
test('envia modelo configurado, data e store=false; não envia histórico', async () => {
  let request;
  await withServer(async base => { assert.equal((await post(base)).status, 200); }, {env: {OPENAI_MODEL: 'gpt-6-luna'}, fetchImpl: async (url, options) => { assert.equal(url, 'https://api.openai.com/v1/responses'); request = JSON.parse(options.body); return mockPayload({items: [item]}); }});
  assert.equal(request.model, 'gpt-6-luna'); assert.equal(request.store, false); assert.ok(request.instructions.includes('2026-10-05')); assert.equal(typeof request.input, 'string'); assert.equal(request.text.format.strict, true);
});
test('limite protege contra excesso de solicitações', async () => withServer(async base => {
  for (let i = 0; i < 12; i++) assert.equal((await post(base)).status, 200);
  assert.equal((await post(base)).status, 429);
}));
test('servidor sem configuração retorna erro orientativo', async () => withServer(async base => {
  const response = await post(base); assert.equal(response.status, 503); assert.match((await response.json()).error, /OPENAI_API_KEY/);
}, {env: {OPENAI_API_KEY: ''}}));
