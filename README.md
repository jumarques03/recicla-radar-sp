# Recicla Radar SP

Painel de inteligência territorial para fiscais e gestores da limpeza urbana de São Paulo.
O app mostra onde há mais demanda de descarte, onde estão as lixeiras inteligentes
recicladoras, quanto cada uma coletou e quais alertas preditivos pedem atenção
(por exemplo: "lixeira deve encher em 6 h"). Também permite registrar vistorias.

> **O app sugere e a pessoa decide.** Nenhuma ação de alto impacto é automática.

Trabalho da FIAP, Global Solution 2026.2, Territory Predictive Insights.

**Estado atual:** modelo inicial do front-end, com dados simulados (mock). Não há
back-end nem autenticação real.

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
flutter test           # testes (validadores, regra de alerta, contraste, navegação)
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
assets/geojson/           limites reais dos distritos (etapa futura)
```

Os repositórios são interfaces (`lib/data/repositories`). Para trocar o mock por
Firebase, basta passar outras implementações para `ReciclaRadarApp` em `lib/app.dart`;
as telas não mudam.

## Tecnologias

Flutter (Material 3), `go_router`, `provider`, `flutter_map` (tiles do OpenStreetMap, sem
chave de API), `fl_chart`, `shared_preferences`.

## Acessibilidade

- Contraste WCAG AA nos temas claro e escuro (verificado em `test/contrast_test.dart`).
- Respeita o tamanho de fonte do sistema e permite ajustar nas Configurações.
- Alvos de toque de pelo menos 48 dp e barra inferior com rótulos sempre visíveis.
- Status e gravidade sempre com ícone e texto, nunca só cor.
- Gráficos e marcadores do mapa com descrição para leitores de tela e resumo em texto.

## Próximos passos

- Back-end e autenticação com Firebase.
- GeoJSON real dos distritos no mapa de demanda.
- Motor de alertas completo em `lib/domain`.
- Capturas de tela em `assets/screenshots`.

Os mapas usam os servidores públicos de tiles do OpenStreetMap, adequados para
desenvolvimento. Para produção, use um provedor de tiles próprio ou contratado.
