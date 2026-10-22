using AuriaAPI.Api.Extensions;
using AuriaAPI.Api.Middleware;
using AuriaAPI.Infra.Seed;

var builder = WebApplication.CreateBuilder(args);

// Composition root: cada camada registra as próprias dependências (ver Api/Extensions).
builder.Services
    .AddAplicacao()
    .AddInfraestrutura(builder.Configuration)
    .AddAutenticacaoJwt(builder.Configuration)
    .AddControllersComResultWrapper()
    .AddSwaggerComJwt()
    .AddCorsPadrao(builder.Configuration, builder.Environment);

var app = builder.Build();

await CriarPrimeiroAdminAsync(app);

// Primeiro middleware do pipeline: qualquer exceção vira uma resposta no formato do ResultWrapper.
app.UseMiddleware<ExceptionHandlingMiddleware>();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Auria API v1");
    c.RoutePrefix = "swagger";
});

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseCors("Default");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

static async Task CriarPrimeiroAdminAsync(WebApplication app)
{
    using var scope = app.Services.CreateScope();
    try
    {
        await scope.ServiceProvider.GetRequiredService<AdminSeeder>().ExecutarAsync();
        // Só em Development e com "DadosDemonstracao:Ativar": true — cria apenas o que ainda não existe.
        await scope.ServiceProvider.GetRequiredService<DadosDemonstracaoSeeder>().ExecutarAsync();
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Não foi possível verificar/criar o administrador inicial ou os dados de demonstração. O banco já foi criado com 'dotnet ef database update'?");
    }
}
