using AuriaAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AuriaAPI.Infra.EF;

public class AuriaDbContext : DbContext
{
    public AuriaDbContext(DbContextOptions<AuriaDbContext> options) : base(options) { }

    public DbSet<Usuario> Usuarios { get; set; }
    public DbSet<Ambiente> Ambientes { get; set; }
    public DbSet<Ativo> Ativos { get; set; }
    public DbSet<Chamado> Chamados { get; set; }
    public DbSet<OrdemServico> OrdensServico { get; set; }
    public DbSet<ItemEstoque> ItensEstoque { get; set; }
    public DbSet<Notificacao> Notificacoes { get; set; }
    public DbSet<OrdemServicoItemEstoque> OrdensServicoItens { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.ToTable("usuario");
            entity.HasIndex(u => u.Email).IsUnique();
        });
        modelBuilder.Entity<Ambiente>().ToTable("ambiente");
        modelBuilder.Entity<Ativo>().ToTable("ativo");
        modelBuilder.Entity<Chamado>().ToTable("chamado");
        modelBuilder.Entity<ItemEstoque>(entity =>
        {
            entity.ToTable("item_estoque");
            entity.Property(e => e.CustoUnitario).HasPrecision(10, 2);
        });
        modelBuilder.Entity<Notificacao>().ToTable("notificacao");

        modelBuilder.Entity<OrdemServicoItemEstoque>(entity =>
        {
            entity.ToTable("ordem_servico_item_estoque");
            entity.HasKey(e => new { e.OrdemServicoId, e.ItemEstoqueId });
        });

        modelBuilder.Entity<Ativo>()
            .HasOne(a => a.Ambiente)
            .WithMany(a => a.Ativos)
            .HasForeignKey(a => a.AmbienteId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Chamado>()
            .HasOne(c => c.Ativo)
            .WithMany(a => a.Chamados)
            .HasForeignKey(c => c.AtivoId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<OrdemServico>(entity =>
        {
            entity.ToTable("ordem_servico");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ChamadoId).HasColumnName("chamado_id");
            entity.Property(e => e.TecnicoId).HasColumnName("tecnico_id");
            entity.Property(e => e.TempoGastoMinutos).HasColumnName("tempo_gasto_minutos");
            entity.Property(e => e.ParecerTecnico).HasColumnName("parecer_tecnico");
            entity.Property(e => e.CustoMaoObra).HasColumnName("custo_mao_obra").HasPrecision(10, 2);
            entity.Property(e => e.DataInicio).HasColumnName("data_inicio");
            entity.Property(e => e.DataConclusao).HasColumnName("data_conclusao");
        });
    }
}