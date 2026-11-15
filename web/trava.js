// Trava de abertura do Funances: pede a biometria do aparelho pelo navegador
// (WebAuthn) antes de mostrar o app.
//
// É uma trava de privacidade neste aparelho, não uma verificação no
// servidor: a credencial só prova, aqui, que quem abriu é quem cadastrou.
(function () {
  function paraTexto(buffer) {
    var bytes = new Uint8Array(buffer), s = '';
    for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }
  function paraBytes(texto) {
    var s = atob(texto.replace(/-/g, '+').replace(/_/g, '/'));
    var bytes = new Uint8Array(s.length);
    for (var i = 0; i < s.length; i++) bytes[i] = s.charCodeAt(i);
    return bytes;
  }
  function sorteio(n) {
    return crypto.getRandomValues(new Uint8Array(n));
  }

  window.funancesTrava = {
    // Há leitor de digital, rosto ou equivalente neste aparelho?
    disponivel: async function () {
      try {
        return !!(window.PublicKeyCredential &&
          (await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()));
      } catch (_) {
        return false;
      }
    },

    // Cadastra este aparelho. Devolve a identificação da credencial, ou ''.
    cadastrar: async function (nome) {
      try {
        var credencial = await navigator.credentials.create({
          publicKey: {
            challenge: sorteio(32),
            rp: { name: 'Funances', id: location.hostname },
            user: { id: sorteio(16), name: nome, displayName: nome },
            pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'required',
              residentKey: 'discouraged',
            },
            timeout: 60000,
            attestation: 'none',
          },
        });
        return credencial ? paraTexto(credencial.rawId) : '';
      } catch (_) {
        return '';
      }
    },

    // Pede a biometria para a credencial deste aparelho.
    verificar: async function (id) {
      try {
        var resposta = await navigator.credentials.get({
          publicKey: {
            challenge: sorteio(32),
            rpId: location.hostname,
            allowCredentials: [{ type: 'public-key', id: paraBytes(id), transports: ['internal'] }],
            userVerification: 'required',
            timeout: 60000,
          },
        });
        return !!resposta;
      } catch (_) {
        return false;
      }
    },
  };
})();
