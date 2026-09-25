const test = require('node:test');
const assert = require('node:assert/strict');
const { validatePrompt, validatePlan } = require('./validation');
const plan = () => ({ planTitle: 'Plan', notes: '', days: Array.from({length: 7}, (_, i) => ({
  day: `Day ${i + 1}`, ...Object.fromEntries(['breakfast', 'midMorning', 'lunch', 'eveningSnack', 'dinner']
    .map(key => [key, [{name: 'Food', quantity: '1 cup', calories: 100}]])),
})) });
test('accepts a bounded prompt', () => assert.equal(validatePrompt({prompt: 'A'.repeat(20)}), 'A'.repeat(20)));
test('rejects missing or oversized prompts', () => {
  for (const data of [null, {}, {prompt: 12}, {prompt: 'short'}, {prompt: 'A'.repeat(20001)}]) {
    assert.throws(() => validatePrompt(data));
  }
});
test('accepts a complete seven-day plan', () => assert.equal(validatePlan(plan()).days.length, 7));
test('rejects incomplete generated plans', () => { const p = plan(); p.days.pop(); assert.throws(() => validatePlan(p)); });
test('rejects invalid calories', () => { const p = plan(); p.days[0].breakfast[0].calories = 'unknown'; assert.throws(() => validatePlan(p)); });
test('rejects missing meals', () => { const p = plan(); delete p.days[0].dinner; assert.throws(() => validatePlan(p)); });
