// Service worker das notificações do Funances.
//
// O Firebase Cloud Messaging entrega a notificação como uma mensagem de push
// comum; aqui ela é só mostrada. Não carrega o SDK do Firebase de propósito:
// assim o mesmo arquivo serve ao projeto de testes e ao de produção, sem
// configuração embutida.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (evento) => evento.waitUntil(self.clients.claim()));

self.addEventListener('push', (evento) => {
  let mensagem = {};
  try {
    mensagem = evento.data ? evento.data.json() : {};
  } catch (_) {
    mensagem = {};
  }
  const aviso = mensagem.notification || {};
  const link = (mensagem.fcmOptions && mensagem.fcmOptions.link) || (mensagem.data && mensagem.data.link) || '/';
  evento.waitUntil(
    self.registration.showNotification(aviso.title || 'Funances', {
      body: aviso.body || '',
      icon: aviso.icon || '/icons/Icon-192.png',
      badge: aviso.badge || '/icons/aviso.png',
      tag: aviso.tag,
      data: { link },
    }),
  );
});

self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();
  const link = (evento.notification.data && evento.notification.data.link) || '/';
  evento.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((janelas) => {
      for (const janela of janelas) {
        if ('focus' in janela) return janela.focus();
      }
      return self.clients.openWindow(link);
    }),
  );
});
