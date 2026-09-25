'use strict';
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { validatePrompt, validatePlan } = require('./validation');
initializeApp();
const apiKey = defineSecret('GEMINI_API_KEY');
// Set to a supported model in the deployment environment, rather than embedding
// a model that will silently become obsolete in shipped clients.
const model = defineString('GEMINI_MODEL');
exports.generateDietPlan = onCall({
  region: 'us-central1', secrets: [apiKey], timeoutSeconds: 120,
  maxInstances: 2, concurrency: 10,
}, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth.token.admin !== true) throw new HttpsError('permission-denied', 'Administrator access required.');
  let prompt;
  try { prompt = validatePrompt(request.data); }
  catch (error) { throw new HttpsError('invalid-argument', error.message); }
  const db = getFirestore('dieticianbabu');
  const rateRef = db.collection('_generationLimits').doc(request.auth.uid);
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(rateRef);
    const previous = snapshot.data() || {};
    const now = Date.now();
    const sameWindow = now - (previous.startedAt || 0) < 3600000;
    const count = sameWindow ? previous.count || 0 : 0;
    if (count >= 10) throw new HttpsError('resource-exhausted', 'Hourly generation limit reached.');
    tx.set(rateRef, { startedAt: sameWindow ? previous.startedAt : now, count: count + 1 });
  });
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model.value())}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey.value() },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', maxOutputTokens: 16000 } }),
      signal: AbortSignal.timeout(100000),
    });
    if (!response.ok) throw new Error('Generation provider failed');
    const result = await response.json();
    const candidate = result.candidates?.[0];
    if (candidate?.finishReason !== 'STOP') throw new Error('Incomplete generation');
    const text = candidate.content?.parts?.filter(part => !part.thought).map(part => part.text || '').join('');
    return validatePlan(JSON.parse(text));
  } catch (_) {
    // Do not log patient prompts, responses, provider bodies, or API credentials.
    throw new HttpsError('unavailable', 'Could not generate a complete plan. Please try again.');
  }
});
