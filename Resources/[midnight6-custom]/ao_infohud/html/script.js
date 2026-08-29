function formatMoney(n) {
  return '$' + Number(n).toLocaleString('en-US');
}

function updateRealClock() {
  const now = new Date();
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');

  document.getElementById('realtime').textContent = `${hh}:${mm}`;
  document.getElementById('realdate').textContent = `${month}/${day}`;
}

setInterval(updateRealClock, 1000);
updateRealClock();

function applyData(data) {
  document.getElementById('gametime').textContent = data.gameTime;
  document.getElementById('cash').textContent = formatMoney(data.cash);
  document.getElementById('bank').textContent = formatMoney(data.bank);
  document.getElementById('playerId').textContent = data.playerId;
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action !== 'update') return;
  applyData(data);
});

// ブラウザで直接index.htmlを開いて見た目だけ確認する用のフォールバック
// (FiveM内ではclient.luaからのNUIメッセージがすぐ上書きします)
applyData({
  gameTime: '16:22',
  cash: 12500,
  bank: 425000,
  playerId: 243
});
