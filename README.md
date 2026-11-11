# Recicla Radar SP

Painel de inteligência territorial para fiscais e gestores da limpeza urbana de São Paulo.
O app mostra onde há mais demanda de descarte, onde estão as lixeiras inteligentes
recicladoras, quanto cada uma coletou e quais alertas preditivos pedem atenção
(por exemplo: "lixeira deve encher em 6 h"). Também permite registrar vistorias.

> **O app sugere e a pessoa decide.** Nenhuma ação de alto impacto é automática.

Trabalho da FIAP, Global Solution 2026.2, Territory Predictive Insights.

**Estado atual:** front-end completo para Android, com dados simulados (mock) e tudo salvo no
aparelho. Não há back-end nem autenticação real.

## Como executar

O foco do app é o **Android**, que é a plataforma testada. O projeto também tem as pastas
de iOS, web, Windows, Linux e macOS, mas elas não foram testadas. Requisitos:
[Flutter](https://docs.flutter.dev/get-started/install) 3.x, Android SDK e um emulador ou
celular Android.

```bash
flutter pub get
flutter devices          # mostra os dispositivos disponíveis
flutter run -d <id>      # roda no dispositivo escolhido
```

Para testar o login, use a conta de demonstração:

- e-mail: `fiscal@reciclaradar.sp`
- senha: `senha123`

Outros comandos úteis:

```bash
flutter analyze        # análise estática
flutter test           # testes (validadores, alertas, contraste, navegação, mapas)
flutter build apk --debug
```

## Telas

| Rota | Tela |
| --- | --- |
| `/login` | Login |
| `/cadastro` | Cadastro |
| `/recuperar-senha` | Recuperar senha |
| `/home` | Visão geral e impacto |
| `/demanda` | Mapa de demanda por distrito |
| `/lixeiras` | Mapa e lista de lixeiras |
| `/lixeiras/:id` | Detalhe da lixeira |
| `/alertas` | Lista de alertas |
| `/alertas/:id` | Detalhe do alerta |
| `/vistoria?binId=` | Formulário de vistoria |
| `/configuracoes` | Configurações |

## Estrutura

```
lib/
  main.dart, app.dart     ponto de entrada, temas e injeção de dependências
  core/
    theme/                cores, tipografia, espaçamentos, tema claro e escuro
    router/               rotas nomeadas (go_router)
    widgets/              componentes reutilizáveis (cards, gráficos, estados)
    utils/                validadores e formatadores
  data/
    models/               Bin, District, Alert, Inspection, Reading...
    repositories/         interfaces abstratas + implementações mock
    mock/                 dados simulados de São Paulo
  domain/                 esqueleto do motor de alertas (uma regra de exemplo)
  state/                  providers (ChangeNotifier)
  features/               auth, overview, demand_map, bins_map, alerts, inspection, settings
test/
assets/screenshots/       capturas de tela (a preencher)
assets/geojson/           (vazia: os limites vêm do OpenStreetMap em tempo real)
tool/                     script que gera os pontos de descarte dos distritos
```

Os repositórios são interfaces (`lib/data/repositories`). Para trocar o mock por
Firebase, basta passar outras implementações para `ReciclaRadarApp` em `lib/app.dart`;
as telas não mudam.

## Tecnologias

Flutter (Material 3), `go_router`, `provider`, `flutter_map` (tiles do OpenStreetMap, sem
chave de API), `fl_chart`, `shared_preferences`, `path_provider`, `http`.

## Mapas e dados do OpenStreetMap

- **Contorno de São Paulo e limites dos 96 distritos:** o app busca no serviço Nominatim do
  OpenStreetMap na primeira vez que o app abre com internet (`lib/data/osm`), já simplificados.
  Nada é baixado para dentro do projeto. O resultado é guardado num arquivo no aparelho
  (`boundaries.v1.json`), então nas próximas vezes o contorno aparece na hora e sem internet.
  Se o app nunca abriu com internet, o mapa mostra um aviso e o botão "Tentar de novo".
- **Fundo do mapa (tiles):** ficam guardados no aparelho por 30 dias (até 200 MB). Sem
  internet aparecem as regiões que a pessoa já viu; o resto fica em branco, mas os distritos,
  as lixeiras e as listas continuam funcionando.
- **Pontos de descarte e lixeiras:** são dados criados para o projeto
  (`lib/data/mock/district_seeds.dart`). Esse arquivo é gerado por
  `python tool/gerar_distritos.py`, que consulta o OpenStreetMap uma vez para sortear os
  pontos dentro de cada distrito.
- Os dados do mapa são © colaboradores do OpenStreetMap, licença ODbL.

## Alertas

Os alertas são calculados a partir dos dados das lixeiras (`lib/domain/alert_engine.dart`) e
só sugerem: a decisão (em análise, resolvido ou descartado) é de uma pessoa e fica salva no
aparelho (`shared_preferences`), então não se perde ao fechar o app.

| Alerta | Dispara quando | Gravidade |
| --- | --- | --- |
| Previsão de enchimento | Enchimento acima do limiar das Configurações (padrão 80%) ou lotação prevista em até 24 h | Crítica até 4 h, alta até 12 h, média até 24 h |
| Sem sinal | Nenhuma leitura há mais de 12 h | Alta; crítica acima de 48 h |
| Leitura fora do padrão | Um material passa de 2 vezes a média de 30 dias, por 2 dias seguidos ou mais | Média; alta a partir de 3 vezes |
| Coleta abaixo do esperado | Volume do distrito em 7 dias cai mais de 15% contra a média das 4 semanas anteriores | Média; alta acima de 30% |
| Demanda alta com pouca cobertura | Índice de demanda 85 ou mais e no máximo 2 lixeiras funcionando | Média; alta sem nenhuma |
| Vistoria de campo | Vistoria dos últimos 7 dias com gravidade alta, ou que aponta lixeira danificada ou vandalizada | Crítica (alta + pedido de coleta), alta ou média |

- O ritmo de enchimento vem das leituras desde a última coleta. Com menos de 4 leituras o app
  não prevê o tempo e avisa que não há dados suficientes.
- A confiança depende dos dados: quantidade de leituras e regularidade do ritmo (enchimento),
  dias seguidos (leitura fora do padrão) e quantas lixeiras do distrito tiveram queda (coleta).
- Cada alerta mostra a evidência, a regra aplicada, o motivo da confiança e as limitações.
- Mudar o limiar de enchimento nas Configurações recalcula os alertas.
- **Alertas lidos:** o selo da aba Alertas conta só os alertas ativos que a pessoa ainda não
  leu. Abrir um alerta o marca como lido; cada card tem um botão para marcar como lido ou
  não lido; e o botão de duplo visto na lista marca todos (com "Desfazer"). Tudo fica salvo
  no aparelho, assim como o status (Em análise, Resolvido, Descartado) de cada alerta.

## Vistorias e privacidade

- As vistorias ficam salvas no aparelho (`shared_preferences`), sem servidor. Elas aparecem no
  detalhe da lixeira e, quando graves, geram um alerta.
- Com o consentimento ligado (Configurações ou checkbox do cadastro), a vistoria leva o nome de
  quem registrou. Sem consentimento, ela é anônima. O formulário avisa qual dos dois vale.
- O app guarda só o mínimo de dado pessoal: o nome, e só com consentimento.

## Telas ligadas entre si

Alerta, lixeira e distrito se levam uns aos outros: o alerta tem "Ver a lixeira", "Ver no mapa" e
"Ver o distrito"; o painel do distrito leva às lixeiras e aos alertas dele; o detalhe da lixeira
mostra os alertas e as vistorias dela; os cartões da visão geral abrem as listas. As rotas aceitam
filtros (`/lixeiras?distrito=`, `/lixeiras?lixeira=`, `/alertas?distrito=`, `/demanda?distrito=`).

## Layout responsivo

Em telas a partir de 720 dp a barra de baixo vira um menu lateral (com nomes a partir de 1100 dp).
Listas, detalhes e formulários ficam centralizados com largura máxima, e na visão geral os
gráficos ficam lado a lado. Com letra muito grande, a faixa de aviso dos alertas rola junto com a
lista. O teste `test/responsive_test.dart` percorre o app em 9 tamanhos, de 320x640 a 1366x768.

## Acessibilidade

- Contraste WCAG AA nos temas claro e escuro (verificado em `test/contrast_test.dart`).
- Tema de **alto contraste** (Configurações), com contraste mínimo 7:1 (AAA), bordas grossas, e que
  também acompanha o ajuste de alto contraste do aparelho.
- Respeita o tamanho de fonte do sistema e permite ajustar nas Configurações (90% a 150%, onde
  100% já é um tamanho compacto: 85% da fonte padrão do Material).
- Alvos de toque de pelo menos 48 dp e barra inferior com rótulos sempre visíveis.
- Status e gravidade sempre com ícone e texto, nunca só cor.
- Gráficos e marcadores do mapa com descrição para leitores de tela e resumo em texto.

## Próximos passos

- Back-end e autenticação com Firebase.
- Motor de alertas completo em `lib/domain`.
- Capturas de tela em `assets/screenshots`.

Os mapas usam os servidores públicos de tiles do OpenStreetMap, adequados para
desenvolvimento. Para produção, use um provedor de tiles próprio ou contratado.
