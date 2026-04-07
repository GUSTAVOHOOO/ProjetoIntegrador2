# ProjetoIntegrador2

Veja o [Guia de Setup](SETUP.md) para instruções completas de ambiente.

## Proteção de branches

As branches `main` e `develop` são protegidas. Todo código deve entrar via Pull Request:

| Branch    | Aprovações | CI obrigatório | Push direto |
|-----------|-----------|----------------|-------------|
| `main`    | 1         | ✅              | ❌           |
| `develop` | 1         | ✅              | ❌           |

Fluxo de trabalho:
```
feature/x  →  develop  →  main
              (PR + CI)   (PR + CI)
```