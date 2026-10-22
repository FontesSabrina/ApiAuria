# AuriaAPI

API REST em ASP.NET Core do sistema Auria. A documentação completa (como configurar e executar,
JWT, cache, ResultWrapper, endpoints e exemplos) está no [README da raiz do repositório](../README.md).
As decisões de arquitetura estão em [docs/DOCUMENTACAO_TECNICA.md](../docs/DOCUMENTACAO_TECNICA.md).

Resumo para rodar:

```bash
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=aura_db;User=root;Password=SUA_SENHA;"
dotnet user-secrets set "Jwt:SecretKey" "uma-chave-aleatoria-com-pelo-menos-32-caracteres"
dotnet user-secrets set "AdminInicial:Nome" "Administrador"
dotnet user-secrets set "AdminInicial:Email" "admin@auria.com"
dotnet user-secrets set "AdminInicial:Senha" "Admin@123"
dotnet ef database update
dotnet run          # http://localhost:5131/swagger
```
