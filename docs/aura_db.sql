-- =====================================================================
-- Banco de dados do sistema AURIA (aura_db) - MySQL 8 / MariaDB
-- Estrutura idêntica à criada pela migration InitialCreate da AuriaAPI
-- (AuriaAPI/Migrations/20260916123652_InitialCreate.cs).
--
-- Como usar (XAMPP / MySQL Workbench):
--   1. Abra este arquivo no Workbench (File > Open SQL Script) e execute (raio ⚡),
--      ou no terminal:  mysql -u root < aura_db.sql
--   2. Rode a API (dotnet run). Ela cria o administrador inicial e, em
--      desenvolvimento, os usuários de teste e alguns chamados de exemplo.
--
-- Este script já registra a migration na tabela __EFMigrationsHistory,
-- então o comando "dotnet ef database update" não tenta recriar as tabelas.
-- =====================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `aura_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE `aura_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- Controle de migrations do Entity Framework
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
  `MigrationId`    varchar(150) NOT NULL,
  `ProductVersion` varchar(32)  NOT NULL,
  PRIMARY KEY (`MigrationId`)
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Ambientes: locais físicos onde os ativos ficam (salas, blocos, andares)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ambiente` (
  `Id`            int      NOT NULL AUTO_INCREMENT,
  `Identificacao` longtext NOT NULL,
  `PredioBloco`   longtext NULL,
  `Andar`         longtext NULL,
  `Observacoes`   longtext NULL,
  CONSTRAINT `PK_ambiente` PRIMARY KEY (`Id`)
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Itens de estoque: peças e materiais usados nas ordens de serviço
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `item_estoque` (
  `Id`                int           NOT NULL AUTO_INCREMENT,
  `Nome`              longtext      NOT NULL,
  `CodigoInterno`     longtext      NOT NULL,
  `QuantidadeEstoque` int           NOT NULL,
  `EstoqueMinimo`     int           NOT NULL,
  `CustoUnitario`     decimal(10,2) NOT NULL,
  CONSTRAINT `PK_item_estoque` PRIMARY KEY (`Id`)
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Usuários: Solicitante, Tecnico ou Admin (senha guardada com hash BCrypt)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `usuario` (
  `Id`     int          NOT NULL AUTO_INCREMENT,
  `Nome`   longtext     NOT NULL,
  `Email`  varchar(255) NOT NULL,
  `Senha`  longtext     NOT NULL,
  `Perfil` longtext     NOT NULL,
  CONSTRAINT `PK_usuario` PRIMARY KEY (`Id`),
  UNIQUE INDEX `IX_usuario_Email` (`Email`)
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Ativos: equipamentos e bens patrimoniais, vinculados a um ambiente
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ativo` (
  `Id`                   int         NOT NULL AUTO_INCREMENT,
  `Patrimonio`           longtext    NOT NULL,
  `Nome`                 longtext    NOT NULL,
  `EstadoConservacao`    longtext    NOT NULL,
  `DataAquisicao`        datetime(6) NULL,
  `PrazoGarantia`        datetime(6) NULL,
  `VidaUtilEstimadaAnos` int         NULL,
  `AmbienteId`           int         NOT NULL,
  CONSTRAINT `PK_ativo` PRIMARY KEY (`Id`),
  INDEX `IX_ativo_AmbienteId` (`AmbienteId`),
  CONSTRAINT `FK_ativo_ambiente_AmbienteId` FOREIGN KEY (`AmbienteId`)
    REFERENCES `ambiente` (`Id`) ON DELETE RESTRICT
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Notificações: avisos gerados pela API para cada usuário
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notificacao` (
  `Id`          int         NOT NULL AUTO_INCREMENT,
  `Titulo`      longtext    NOT NULL,
  `Mensagem`    longtext    NOT NULL,
  `DataCriacao` datetime(6) NOT NULL,
  `Lida`        tinyint(1)  NOT NULL,
  `UsuarioId`   int         NOT NULL,
  CONSTRAINT `PK_notificacao` PRIMARY KEY (`Id`),
  INDEX `IX_notificacao_UsuarioId` (`UsuarioId`),
  CONSTRAINT `FK_notificacao_usuario_UsuarioId` FOREIGN KEY (`UsuarioId`)
    REFERENCES `usuario` (`Id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Chamados: solicitações de manutenção abertas por um usuário
-- Status: Aberto, Em Execucao, Concluido ou Cancelado
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chamado` (
  `Id`                   int         NOT NULL AUTO_INCREMENT,
  `Descricao`            longtext    NOT NULL,
  `LocalizacaoDetalhada` longtext    NULL,
  `TipoManutencao`       longtext    NOT NULL,
  `Prioridade`           longtext    NOT NULL,
  `Status`               longtext    NOT NULL,
  `DataAbertura`         datetime(6) NOT NULL,
  `DataFechamento`       datetime(6) NULL,
  `SolicitanteId`        int         NOT NULL,
  `AtivoId`              int         NOT NULL,
  CONSTRAINT `PK_chamado` PRIMARY KEY (`Id`),
  INDEX `IX_chamado_AtivoId` (`AtivoId`),
  INDEX `IX_chamado_SolicitanteId` (`SolicitanteId`),
  CONSTRAINT `FK_chamado_ativo_AtivoId` FOREIGN KEY (`AtivoId`)
    REFERENCES `ativo` (`Id`) ON DELETE RESTRICT,
  CONSTRAINT `FK_chamado_usuario_SolicitanteId` FOREIGN KEY (`SolicitanteId`)
    REFERENCES `usuario` (`Id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Ordens de serviço: execução de um chamado por um técnico
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ordem_servico` (
  `id`                  int           NOT NULL AUTO_INCREMENT,
  `chamado_id`          int           NOT NULL,
  `tecnico_id`          int           NOT NULL,
  `tempo_gasto_minutos` int           NOT NULL,
  `parecer_tecnico`     longtext      NULL,
  `custo_mao_obra`      decimal(10,2) NOT NULL,
  `data_inicio`         datetime(6)   NOT NULL,
  `data_conclusao`      datetime(6)   NULL,
  CONSTRAINT `PK_ordem_servico` PRIMARY KEY (`id`),
  INDEX `IX_ordem_servico_chamado_id` (`chamado_id`),
  INDEX `IX_ordem_servico_tecnico_id` (`tecnico_id`),
  CONSTRAINT `FK_ordem_servico_chamado_chamado_id` FOREIGN KEY (`chamado_id`)
    REFERENCES `chamado` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `FK_ordem_servico_usuario_tecnico_id` FOREIGN KEY (`tecnico_id`)
    REFERENCES `usuario` (`Id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4;

-- ---------------------------------------------------------------------
-- Peças consumidas em cada ordem de serviço (tabela de ligação N:N)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ordem_servico_item_estoque` (
  `OrdemServicoId`      int NOT NULL,
  `ItemEstoqueId`       int NOT NULL,
  `QuantidadeUtilizada` int NOT NULL,
  CONSTRAINT `PK_ordem_servico_item_estoque` PRIMARY KEY (`OrdemServicoId`, `ItemEstoqueId`),
  INDEX `IX_ordem_servico_item_estoque_ItemEstoqueId` (`ItemEstoqueId`),
  CONSTRAINT `FK_ordem_servico_item_estoque_item_estoque_ItemEstoqueId` FOREIGN KEY (`ItemEstoqueId`)
    REFERENCES `item_estoque` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `FK_ordem_servico_item_estoque_ordem_servico_OrdemServicoId` FOREIGN KEY (`OrdemServicoId`)
    REFERENCES `ordem_servico` (`id`) ON DELETE CASCADE
) CHARACTER SET utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- Registra a migration como já aplicada
INSERT IGNORE INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20260916123652_InitialCreate', '9.0.0');

-- =====================================================================
-- Dados de exemplo (ambientes, ativos e estoque)
-- Usuários e chamados de teste são criados pela própria API ao iniciar,
-- porque as senhas precisam ser gravadas com hash BCrypt.
-- Os INSERTs só rodam se a tabela ainda estiver vazia.
-- =====================================================================

INSERT INTO `ambiente` (`Identificacao`, `PredioBloco`, `Andar`, `Observacoes`)
SELECT * FROM (
  SELECT 'Recepção' AS i, 'Bloco A' AS b, 'Térreo' AS a, 'Entrada principal do prédio' AS o UNION ALL
  SELECT 'Sala 3', 'Bloco A', '1º andar', NULL UNION ALL
  SELECT 'Sala de Reuniões 1', 'Bloco A', '1º andar', 'Capacidade para 12 pessoas' UNION ALL
  SELECT 'Copa', 'Bloco A', 'Térreo', NULL UNION ALL
  SELECT 'Laboratório de Informática', 'Bloco B', '2º andar', '30 computadores' UNION ALL
  SELECT 'Auditório', 'Bloco B', 'Térreo', 'Capacidade para 120 pessoas' UNION ALL
  SELECT 'Almoxarifado', 'Bloco C', 'Subsolo', 'Acesso restrito à manutenção'
) AS dados
WHERE NOT EXISTS (SELECT 1 FROM `ambiente`);

INSERT INTO `ativo` (`Patrimonio`, `Nome`, `EstadoConservacao`, `DataAquisicao`, `PrazoGarantia`, `VidaUtilEstimadaAnos`, `AmbienteId`)
SELECT d.p, d.n, d.e, d.aq, d.g, d.v, amb.Id
FROM (
  SELECT 'PAT-0001' AS p, 'Ar-condicionado split 12.000 BTUs' AS n, 'Bom' AS e, '2023-03-10 12:00:00' AS aq, '2026-03-10 12:00:00' AS g, 10 AS v, 'Sala 3' AS amb UNION ALL
  SELECT 'PAT-0002', 'Ar-condicionado split 18.000 BTUs', 'Regular', '2021-02-01 12:00:00', '2024-02-01 12:00:00', 10, 'Auditório' UNION ALL
  SELECT 'PAT-0003', 'Projetor multimídia', 'Bom', '2024-05-20 12:00:00', '2027-05-20 12:00:00', 6, 'Sala de Reuniões 1' UNION ALL
  SELECT 'PAT-0004', 'Computador desktop', 'Bom', '2023-08-15 12:00:00', '2026-08-15 12:00:00', 5, 'Laboratório de Informática' UNION ALL
  SELECT 'PAT-0005', 'Bebedouro industrial', 'Ruim', '2019-06-01 12:00:00', '2020-06-01 12:00:00', 8, 'Copa' UNION ALL
  SELECT 'PAT-0006', 'Impressora multifuncional', 'Regular', '2022-01-12 12:00:00', '2023-01-12 12:00:00', 5, 'Recepção' UNION ALL
  SELECT 'PAT-0007', 'Quadro de distribuição elétrica', 'Bom', '2018-04-01 12:00:00', NULL, 25, 'Almoxarifado' UNION ALL
  SELECT 'PAT-0008', 'Porta automática de vidro', 'Novo', '2026-01-15 12:00:00', '2028-01-15 12:00:00', 15, 'Recepção'
) AS d
JOIN `ambiente` amb ON amb.Identificacao = d.amb
WHERE NOT EXISTS (SELECT 1 FROM `ativo`);

INSERT INTO `item_estoque` (`Nome`, `CodigoInterno`, `QuantidadeEstoque`, `EstoqueMinimo`, `CustoUnitario`)
SELECT * FROM (
  SELECT 'Lâmpada LED tubular 18W' AS n, 'EST-001' AS c, 40 AS q, 15 AS m, 12.90 AS u UNION ALL
  SELECT 'Filtro de ar-condicionado', 'EST-002', 6, 8, 45.00 UNION ALL
  SELECT 'Gás refrigerante R-410A (kg)', 'EST-003', 12, 5, 89.90 UNION ALL
  SELECT 'Disjuntor bipolar 32A', 'EST-004', 10, 4, 38.50 UNION ALL
  SELECT 'Tomada 2P+T 10A', 'EST-005', 25, 10, 9.80 UNION ALL
  SELECT 'Fita isolante 20 m', 'EST-006', 3, 10, 6.50 UNION ALL
  SELECT 'Cabo flexível 2,5 mm (rolo 100 m)', 'EST-007', 4, 2, 219.90 UNION ALL
  SELECT 'Toner para impressora', 'EST-008', 2, 3, 159.00 UNION ALL
  SELECT 'Torneira para bebedouro', 'EST-009', 5, 2, 27.00 UNION ALL
  SELECT 'Parafuso com bucha 8 mm (cento)', 'EST-010', 18, 5, 14.90
) AS dados
WHERE NOT EXISTS (SELECT 1 FROM `item_estoque`);
