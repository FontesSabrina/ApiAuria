namespace AuriaAPI.Application.DTOs;

public record CriarItemEstoqueDto(string Nome, string CodigoInterno, int QuantidadeEstoque, int EstoqueMinimo, decimal CustoUnitario);
public record AtualizarItemEstoqueDto(string Nome, string CodigoInterno, int QuantidadeEstoque, int EstoqueMinimo, decimal CustoUnitario);
public record ItemEstoqueResponseDto(int Id, string Nome, string CodigoInterno, int QuantidadeEstoque, int EstoqueMinimo, decimal CustoUnitario);
