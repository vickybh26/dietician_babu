'use strict';
const meals = ['breakfast', 'midMorning', 'lunch', 'eveningSnack', 'dinner'];
function validatePrompt(data) {
  if (!data || typeof data.prompt !== 'string' || data.prompt.trim().length < 20 || data.prompt.length > 20000) {
    throw new Error('A prompt of 20 to 20000 characters is required.');
  }
  return data.prompt.trim();
}
function validatePlan(plan) {
  if (!plan || typeof plan.planTitle !== 'string' || typeof plan.notes !== 'string' ||
      !Array.isArray(plan.days) || plan.days.length !== 7) throw new Error('Invalid plan.');
  for (const day of plan.days) {
    if (!day || typeof day.day !== 'string') throw new Error('Invalid day.');
    for (const meal of meals) {
      if (!Array.isArray(day[meal]) || day[meal].length < 1 || day[meal].length > 10) throw new Error('Invalid meal.');
      for (const item of day[meal]) {
        if (!item || typeof item.name !== 'string' || typeof item.quantity !== 'string' ||
            !['string', 'number'].includes(typeof item.calories) ||
            !Number.isFinite(Number(item.calories)) || Number(item.calories) < 0) throw new Error('Invalid food item.');
      }
    }
  }
  return plan;
}
module.exports = { validatePrompt, validatePlan };
