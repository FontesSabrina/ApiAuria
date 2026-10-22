/// Endereço base da AuriaAPI.
///
/// - Rodando o app como Windows Desktop (`flutter run -d windows`) na mesma
///   máquina que a API: `http://localhost:5131/api` (valor atual).
/// - Rodando num emulador Android: troque para `http://10.0.2.2:5131/api`
///   (o emulador não enxerga `localhost` como a máquina host).
/// - Rodando num dispositivo físico: use o IP da máquina na rede local,
///   ex. `http://192.168.0.10:5131/api`.
const String apiBaseUrl = 'http://localhost:5131/api';
