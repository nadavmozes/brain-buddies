// Math Adventure — browser demo.
// Mirrors the Flutter app's logic: same 3 tiers, problem generation,
// streak scoring (10 base + 5 per streak), and 3-star thresholds.

const QUESTIONS_PER_ROUND = 10;

const DIFFICULTIES = {
  easy: {
    label: 'Easy',
    emoji: '🌱',
    sub: 'Grade 1 - Adding & taking away small numbers',
    color: '#4CAF50',
  },
  intermediate: {
    label: 'Intermediate',
    emoji: '⭐',
    sub: 'Grade 2 - Bigger sums and simple times tables',
    color: '#FF9800',
  },
  expert: {
    label: 'Expert',
    emoji: '🔥',
    sub: 'Grade 3 - Multiplication, division & mixed quests',
    color: '#E53935',
  },
};

// ---------- persistence ----------
const STORE_KEY = 'mathAdventureStars';
function loadStars() {
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || {}; }
  catch (e) { return {}; }
}
function bestStars(diff) { return loadStars()[diff] || 0; }
function totalStars() {
  const s = loadStars();
  return Object.keys(DIFFICULTIES).reduce((sum, k) => sum + (s[k] || 0), 0);
}
function recordStars(diff, stars) {
  const s = loadStars();
  if (stars > (s[diff] || 0)) { s[diff] = stars; localStorage.setItem(STORE_KEY, JSON.stringify(s)); }
}
function resetProgress() {
  if (confirm('Reset all progress? This erases every star.')) {
    localStorage.removeItem(STORE_KEY);
    refreshHome();
    renderDiffList();
  }
}

// ---------- problem generation (mirror of Dart) ----------
const rnd = (n) => Math.floor(Math.random() * n); // 0..n-1

function makeChoices(answer) {
  const opts = new Set([answer]);
  let guard = 0;
  while (opts.size < 4 && guard < 50) {
    guard++;
    const spread = Math.max(2, Math.round(answer * 0.3));
    let delta = rnd(spread * 2 + 1) - spread;
    if (delta === 0) delta = Math.random() < 0.5 ? 1 : -1;
    const cand = answer + delta;
    if (cand >= 0) opts.add(cand);
  }
  let filler = answer + 1;
  while (opts.size < 4) { if (filler >= 0) opts.add(filler); filler++; }
  const arr = [...opts];
  for (let i = arr.length - 1; i > 0; i--) { const j = rnd(i + 1); [arr[i], arr[j]] = [arr[j], arr[i]]; }
  return arr;
}
const prob = (q, a, label) => ({ question: q, answer: a, choices: makeChoices(a), op: label });

function easyProblem() {
  if (Math.random() < 0.5) {
    const a = rnd(10) + 1, b = rnd(10) + 1;
    return prob(`${a} + ${b}`, a + b, 'Addition');
  }
  const a = rnd(15) + 5, b = rnd(a) + 1;
  return prob(`${a} - ${b}`, a - b, 'Subtraction');
}
function intermediateProblem() {
  const pick = rnd(3);
  if (pick === 0) { const a = rnd(50) + 10, b = rnd(40) + 1; return prob(`${a} + ${b}`, a + b, 'Addition'); }
  if (pick === 1) { const a = rnd(60) + 20, b = rnd(a - 1) + 1; return prob(`${a} - ${b}`, a - b, 'Subtraction'); }
  const a = rnd(5) + 1, b = rnd(5) + 1; return prob(`${a} × ${b}`, a * b, 'Multiplication');
}
function expertProblem() {
  const pick = rnd(4);
  if (pick === 0) { const a = rnd(9) + 2, b = rnd(9) + 2; return prob(`${a} × ${b}`, a * b, 'Multiplication'); }
  if (pick === 1) { const d = rnd(9) + 2, q = rnd(9) + 2; return prob(`${d * q} ÷ ${d}`, q, 'Division'); }
  if (pick === 2) { const a = rnd(400) + 100, b = rnd(300) + 50; return prob(`${a} + ${b}`, a + b, 'Addition'); }
  const a = rnd(400) + 100, b = rnd(a - 1) + 1; return prob(`${a} - ${b}`, a - b, 'Subtraction');
}
function generateOne(diff) {
  if (diff === 'easy') return easyProblem();
  if (diff === 'intermediate') return intermediateProblem();
  return expertProblem();
}
function generateRound(diff) {
  return Array.from({ length: QUESTIONS_PER_ROUND }, () => generateOne(diff));
}

// ---------- stars / messages ----------
function starsForPercent(p) { return p >= 90 ? 3 : p >= 70 ? 2 : p >= 50 ? 1 : 0; }
function messageForStars(s) {
  return s === 3 ? 'SUPER HERO! You mastered this quest!'
    : s === 2 ? 'GREAT JOB! You are getting stronger!'
    : s === 1 ? 'NICE TRY! Keep training, hero!'
    : 'ADVENTURE AWAITS! Try again, you can do it!';
}

// ---------- navigation ----------
function go(id) {
  document.querySelectorAll('.screen').forEach((s) => s.classList.remove('active'));
  document.getElementById(id).classList.add('active');
  if (id === 'home') refreshHome();
  if (id === 'diff') renderDiffList();
}
function howTo() {
  alert('How to Play\n\n1. Pick a difficulty.\n2. Each quest has 10 questions.\n3. Tap the correct answer.\n4. Chain correct answers for streak bonuses and earn up to 3 stars!');
}

// ---------- home & difficulty ----------
function refreshHome() { document.getElementById('homeStars').textContent = totalStars(); }
function starIcons(n) {
  let html = '';
  for (let i = 0; i < 3; i++) html += `<span class="star ${i < n ? 'filled' : 'empty'}">${i < n ? '★' : '☆'}</span>`;
  return html;
}
function renderDiffList() {
  const list = document.getElementById('diffList');
  list.innerHTML = '';
  for (const key of Object.keys(DIFFICULTIES)) {
    const d = DIFFICULTIES[key];
    const card = document.createElement('div');
    card.className = 'panel diff-card';
    card.style.background = d.color;
    card.onclick = () => startGame(key);
    card.innerHTML = `
      <div class="emoji">${d.emoji}</div>
      <div>
        <div class="label">${d.label}</div>
        <div class="sub">${d.sub}</div>
        <div style="margin-top:6px">${starIcons(bestStars(key))}</div>
      </div>
      <div class="chev">›</div>`;
    list.appendChild(card);
  }
}

// ---------- gameplay ----------
let currentDiff = 'easy';
let round = [];
let idx = 0, correct = 0, score = 0, streak = 0, answered = false;

function startGame(diff) {
  currentDiff = diff;
  round = generateRound(diff);
  idx = 0; correct = 0; score = 0; streak = 0; answered = false;
  const d = DIFFICULTIES[diff];
  document.getElementById('gTier').textContent = `${d.emoji} ${d.label}`;
  document.getElementById('gFill').style.background = d.color;
  go('game');
  renderQuestion();
}

function setBuddy(mood) {
  const b = document.getElementById('buddy');
  b.className = 'buddy' + (mood ? ' ' + mood : '');
  b.textContent = mood === 'happy' ? '😄' : mood === 'sad' ? '😲' : '🦸';
}

function renderQuestion() {
  answered = false;
  const p = round[idx];
  document.getElementById('gCount').textContent = idx + 1;
  document.getElementById('gScore').textContent = score;
  document.getElementById('gFill').style.width = `${((idx + 1) / round.length) * 100}%`;
  document.getElementById('qOp').textContent = p.op.toUpperCase();
  document.getElementById('qText').textContent = p.question;
  document.getElementById('gain').classList.remove('show');
  setBuddy('idle');

  const box = document.getElementById('choices');
  box.innerHTML = '';
  p.choices.forEach((val) => {
    const b = document.createElement('button');
    b.className = 'btn choice plain';
    b.textContent = val;
    b.onclick = () => answer(val, b);
    box.appendChild(b);
  });
}

function answer(val, btn) {
  if (answered) return;
  answered = true;
  const p = round[idx];
  const buttons = [...document.querySelectorAll('#choices .choice')];
  buttons.forEach((b) => (b.disabled = true));

  if (val === p.answer) {
    correct++; streak++;
    const gain = 10 + (streak - 1) * 5;
    score += gain;
    btn.classList.remove('plain'); btn.classList.add('correct');
    setBuddy('happy');
    const g = document.getElementById('gain');
    g.textContent = streak > 1 ? `+${gain}  🔥 x${streak} streak!` : `+${gain}`;
    g.classList.add('show');
    document.getElementById('gScore').textContent = score;
  } else {
    streak = 0;
    btn.classList.remove('plain'); btn.classList.add('wrong');
    buttons.forEach((b) => { if (+b.textContent === p.answer) { b.classList.remove('plain'); b.classList.add('correct'); } });
    setBuddy('sad');
    const card = document.getElementById('qCard');
    card.classList.add('shake');
    setTimeout(() => card.classList.remove('shake'), 400);
  }

  setTimeout(advance, 950);
}

function advance() {
  if (idx + 1 < round.length) { idx++; renderQuestion(); }
  else finishRound();
}

function finishRound() {
  const percent = Math.round((correct / round.length) * 100);
  const stars = starsForPercent(percent);
  recordStars(currentDiff, stars);

  document.getElementById('rTitle').textContent = stars === 3 ? 'QUEST COMPLETE!' : 'QUEST OVER!';
  document.getElementById('rStars').innerHTML = starIcons(stars);
  document.getElementById('rScore').textContent = `${correct} / ${round.length} correct`;
  document.getElementById('rPct').textContent = `${percent}%`;
  document.getElementById('rPoints').textContent = score;
  document.getElementById('rMsg').textContent = messageForStars(stars);
  go('result');
}

// init
refreshHome();
