// Sintetiza os efeitos sonoros da interface do Wroote.
//
// Regras que separam "premium" de "brinquedo", e que valem para todos:
//
// 1. Curto. Feedback de clique vive entre 30 e 50ms; nada aqui passa de
//    260ms. Som longo deixa de ser resposta e vira evento.
// 2. Corpo grave. A energia mora entre 100 e 600Hz. A faixa de 2-4kHz é
//    onde o ouvido é mais sensível — é lá que o "bip" de brinquedo mora, e
//    é justamente onde os sons antigos estavam centrados.
// 3. Senoide, nunca onda quadrada ou dente de serra. No máximo um segundo
//    harmônico discreto para dar corpo.
// 4. Sem glissando. Nota que escorrega de uma altura para outra é desenho
//    animado. Quando precisa de duas alturas, são duas notas discretas.
// 5. Fade-out obrigatório no fim. Forma de onda cortada no meio do ciclo
//    estala, e o estalo é o que faz um som soar barato.

const fs = require('fs');
const path = require('path');

const RATE = 44100;
const outDir = process.argv[2] || path.join(__dirname, '..', 'assets', 'sounds');

// PRNG determinístico: o mesmo comando gera exatamente os mesmos arquivos.
let seed = 0x2b5c63;
function rnd() {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return (seed / 0xffffffff) * 2 - 1;
}

const ms = (n) => Math.round((n / 1000) * RATE);

/// Envelope: ataque suave, decaimento exponencial. `atk`/`dec` em ms.
function env(i, n, atk, dec) {
  const t = i / RATE;
  const a = atk <= 0 ? 1 : 1 - Math.exp((-t * 1000) / atk);
  const d = Math.exp((-t * 1000) / dec);
  return a * d;
}

/// Passa-baixa. `poles` aplica o filtro em série: um polo só derruba 6dB por
/// oitava, o que deixa passar agudo demais e devolve o "tssk" que a gente
/// está tentando eliminar. Dois polos (12dB/oitava) é o mínimo utilizável.
function lowpass(buf, cutoff, poles = 2) {
  const dt = 1 / RATE;
  const rc = 1 / (2 * Math.PI * cutoff);
  const alpha = dt / (rc + dt);
  for (let p = 0; p < poles; p++) {
    let prev = 0;
    for (let i = 0; i < buf.length; i++) {
      prev += alpha * (buf[i] - prev);
      buf[i] = prev;
    }
  }
}

/// Passa-alta de um polo, para o ruído de "papel" não ficar abafado.
function highpass(buf, cutoff) {
  const dt = 1 / RATE;
  const rc = 1 / (2 * Math.PI * cutoff);
  const alpha = rc / (rc + dt);
  let prevIn = 0, prevOut = 0;
  for (let i = 0; i < buf.length; i++) {
    const x = buf[i];
    prevOut = alpha * (prevOut + x - prevIn);
    prevIn = x;
    buf[i] = prevOut;
  }
}

/// Normaliza para um pico alvo e aplica fade-out no fim.
function finish(buf, peakDb, fadeMs = 8) {
  let peak = 0;
  for (const v of buf) peak = Math.max(peak, Math.abs(v));
  if (peak > 0) {
    const target = Math.pow(10, peakDb / 20);
    const g = target / peak;
    for (let i = 0; i < buf.length; i++) buf[i] *= g;
  }
  const fade = Math.min(ms(fadeMs), buf.length);
  for (let i = 0; i < fade; i++) {
    const k = buf.length - fade + i;
    buf[k] *= Math.pow(1 - i / fade, 2);
  }
  return buf;
}

/// Nota senoidal com um harmônico discreto.
function tone(buf, freq, startMs, durMs, atk, dec, amp, harmonic = 0.0) {
  const s = ms(startMs), n = ms(durMs);
  for (let i = 0; i < n && s + i < buf.length; i++) {
    const t = i / RATE;
    const e = env(i, n, atk, dec);
    buf[s + i] +=
      amp * e * (Math.sin(2 * Math.PI * freq * t) + harmonic * Math.sin(4 * Math.PI * freq * t));
  }
}

/// Transiente: o "toque" do dedo antes do corpo da nota. Curtíssimo.
function transient(buf, startMs, durMs, cutoff, amp) {
  const s = ms(startMs), n = ms(durMs);
  const noise = new Float64Array(n);
  for (let i = 0; i < n; i++) noise[i] = rnd() * Math.exp((-i / RATE) * 1000 / (durMs / 3));
  lowpass(noise, cutoff);
  for (let i = 0; i < n && s + i < buf.length; i++) buf[s + i] += amp * noise[i];
}

function writeWav(name, buf) {
  const n = buf.length;
  const out = Buffer.alloc(44 + n * 2);
  out.write('RIFF', 0, 'ascii');
  out.writeUInt32LE(36 + n * 2, 4);
  out.write('WAVE', 8, 'ascii');
  out.write('fmt ', 12, 'ascii');
  out.writeUInt32LE(16, 16);
  out.writeUInt16LE(1, 20); // PCM
  out.writeUInt16LE(1, 22); // mono
  out.writeUInt32LE(RATE, 24);
  out.writeUInt32LE(RATE * 2, 28);
  out.writeUInt16LE(2, 32);
  out.writeUInt16LE(16, 34);
  out.write('data', 36, 'ascii');
  out.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    let v = Math.max(-1, Math.min(1, buf[i]));
    out.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  fs.writeFileSync(path.join(outDir, name), out);
  console.log(`${name.padEnd(13)} ${((n / RATE) * 1000).toFixed(0).padStart(4)}ms`);
}

// --- hover: quase subliminar. Dispara dezenas de vezes por minuto, então
// não pode ter altura definida — só um sopro de ar, curtíssimo.
{
  const buf = new Float64Array(ms(16));
  transient(buf, 0, 14, 750, 1);
  writeWav('hover.wav', finish(buf, -26, 5));
}

// --- tap: o "thock" de uma tecla boa. Corpo em 190Hz, transiente curto.
{
  const buf = new Float64Array(ms(46));
  transient(buf, 0, 4, 1500, 0.30);
  tone(buf, 190, 0, 44, 1.5, 13, 1.0, 0.12);
  writeWav('tap.wav', finish(buf, -14));
}

// --- toggle: irmão do tap, um pouco mais alto e mais seco. A diferença de
// altura é o que faz "liguei algo" soar diferente de "cliquei em algo".
{
  const buf = new Float64Array(ms(38));
  transient(buf, 0, 3, 1800, 0.28);
  tone(buf, 265, 0, 36, 1.2, 10, 1.0, 0.1);
  writeWav('toggle.wav', finish(buf, -15));
}

// --- page: folha virando. Ruído com passa-alta, sem nenhuma altura
// definida — qualquer nota aqui viraria "bip de troca de tela".
{
  const n = ms(95);
  const buf = new Float64Array(n);
  const noise = new Float64Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    const e = (1 - Math.exp((-t * 1000) / 6)) * Math.exp((-t * 1000) / 26);
    noise[i] = rnd() * e;
  }
  highpass(noise, 700);
  lowpass(noise, 2600);
  for (let i = 0; i < n; i++) buf[i] = noise[i];
  writeWav('page.wav', finish(buf, -18, 12));
}

// --- open: duas notas ascendentes, ré e lá (intervalo de quinta). Notas
// discretas com um cruzamento curto, nunca um glissando.
{
  const buf = new Float64Array(ms(190));
  tone(buf, 294, 0, 120, 8, 55, 0.8, 0.06);
  tone(buf, 440, 55, 130, 10, 60, 0.75, 0.05);
  writeWav('open.wav', finish(buf, -15, 20));
}

// --- close: o mesmo intervalo ao contrário e mais curto. Fechar é um
// gesto menor que abrir, e o som precisa dizer isso.
{
  const buf = new Float64Array(ms(160));
  tone(buf, 440, 0, 95, 7, 42, 0.7, 0.05);
  tone(buf, 294, 45, 110, 9, 48, 0.75, 0.06);
  writeWav('close.wav', finish(buf, -16, 18));
}

// --- success: sol e ré, quinta ascendente. Era 950ms de fanfarra; agora
// cabe em 260ms e continua sendo o som mais "aberto" do conjunto.
{
  const buf = new Float64Array(ms(265));
  tone(buf, 392, 0, 150, 9, 65, 0.75, 0.08);
  tone(buf, 588, 70, 190, 12, 80, 0.7, 0.06);
  writeWav('success.wav', finish(buf, -15, 25));
}

// --- delete: um baque grave e abafado. Sem nota aguda: excluir não é um
// evento alegre, e o som não deve soar como um.
{
  const buf = new Float64Array(ms(140));
  transient(buf, 0, 8, 550, 0.45);
  tone(buf, 98, 0, 135, 2, 34, 1.0, 0.15);
  writeWav('delete.wav', finish(buf, -14, 16));
}

// --- blocked: dois baques curtos na mesma altura. A repetição é que diz
// "não", sem precisar do zumbido de erro que todo mundo detesta.
{
  const buf = new Float64Array(ms(125));
  transient(buf, 0, 5, 800, 0.38);
  tone(buf, 132, 0, 55, 1.5, 16, 0.9, 0.1);
  transient(buf, 58, 5, 800, 0.38);
  tone(buf, 132, 58, 62, 1.5, 18, 0.85, 0.1);
  writeWav('blocked.wav', finish(buf, -15, 14));
}
