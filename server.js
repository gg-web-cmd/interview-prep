/* 생기부 면접 준비기 — 로컬 실행용 최소 웹서버 (Node 기본 기능만 사용)
   127.0.0.1 에만 붙으므로 같은 공유기를 쓰는 다른 기기에서는 접속할 수 없습니다. */
const http = require('http');
const fs   = require('fs');
const path = require('path');
const { exec } = require('child_process');

const ROOT = __dirname;
const PORTS = [8731, 8732, 8733, 8734, 8735];

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.png':  'image/png',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
  '.txt':  'text/plain; charset=utf-8',
  '.css':  'text/css; charset=utf-8'
};

const server = http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split('?')[0]);
  if (rel === '/' ) rel = '/index.html';

  const file = path.join(ROOT, path.normalize(rel));
  if (!file.startsWith(ROOT)) { res.writeHead(403); return res.end('forbidden'); }

  fs.readFile(file, (err, buf) => {
    if (err) { res.writeHead(404, {'content-type':'text/plain; charset=utf-8'}); return res.end('찾을 수 없습니다: ' + rel); }
    const headers = { 'content-type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream' };
    // 서비스 워커는 항상 최신본을 받아야 갱신이 됩니다
    if (path.basename(file) === 'sw.js') headers['cache-control'] = 'no-cache';
    res.writeHead(200, headers);
    res.end(buf);
  });
});

function listen(i) {
  if (i >= PORTS.length) {
    console.error('사용 가능한 포트를 찾지 못했습니다. 실행 중인 다른 창을 닫고 다시 시도해 주세요.');
    process.exit(1);
  }
  server.once('error', e => (e.code === 'EADDRINUSE') ? listen(i + 1) : (console.error(e.message), process.exit(1)));
  server.listen(PORTS[i], '127.0.0.1', () => {
    const url = 'http://127.0.0.1:' + PORTS[i] + '/';
    console.log('');
    console.log('  생기부 면접 준비기가 실행되었습니다.');
    console.log('  주소: ' + url);
    console.log('');
    console.log('  * 브라우저 주소창 오른쪽의 설치 아이콘(⊕) 또는 화면 위쪽');
    console.log('    [앱 설치] 버튼을 누르면 독립 앱으로 설치됩니다.');
    console.log('  * 이 검은 창을 닫으면 앱이 멈춥니다. 설치 후에는 닫아도 됩니다.');
    console.log('');
    if (process.platform === 'win32') exec('start "" "' + url + '"');
    else if (process.platform === 'darwin') exec('open "' + url + '"');
  });
}
listen(0);
