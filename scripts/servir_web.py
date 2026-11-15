#!/usr/bin/env python3
"""Serve build/web como o Hosting serve: caminho que não é arquivo cai no index.html.

Uso: python3 scripts/servir_web.py [porta]
Sem isso, recarregar o app local num endereço como /lancamentos daria 404.
"""
import http.server
import os
import sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")


class Servidor(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=RAIZ, **kwargs)

    def do_GET(self):
        caminho = self.translate_path(self.path.split("?", 1)[0])
        if not os.path.isfile(caminho):
            self.path = "/index.html"
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    porta = int(sys.argv[1]) if len(sys.argv) > 1 else 8123
    http.server.ThreadingHTTPServer(("127.0.0.1", porta), Servidor).serve_forever()
