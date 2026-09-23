# Bttr Client Flutter

Aplicativo **exclusivamente mobile, para Android e iOS**, para acompanhar habilidades e tempo de prática. Interface em português, adaptada a celulares e tablets, com a paleta verde, os textos e os fluxos do `bttr-client-angular`.


## Executar

Ambiente utilizado: **Flutter 3.41.9 / Dart 3.11.5**. Android requer SDK/JDK configurados; iOS requer macOS, Xcode e CocoaPods. Verifique `flutter doctor` e `flutter devices`.

```bash
cd bttr-client-flutter
flutter pub get

# iOS Simulator: API no localhost do Mac
flutter run -d <id-do-simulador-ios> --dart-define=FLUTTER_ENV=dev

# Android Emulator: 10.0.2.2 aponta para a máquina host
flutter run -d <id-do-emulador-android> \
  --dart-define=FLUTTER_ENV=dev \
  --dart-define=API_URL=http://10.0.2.2:8000
```

Inicie o backend conforme `../bttr-server/README.md`. O aplicativo acessa diretamente a API na porta 8000: **não utiliza o proxy `/api` do Angular**. Para aparelho físico, configure uma URL HTTPS acessível pelo dispositivo, ou um endereço local durante o desenvolvimento. HTTP no Android está habilitado somente em debug. No iOS, há permissão de rede local e exceção ATS de rede local, sem liberação global de HTTP.

`.vscode/launch.json` inclui DEV para cada simulador, QA e PROD. Selecione um dispositivo Android/iOS antes de executar. Não há plataforma web.

## Ambientes

| `FLUTTER_ENV` | Arquivo | Comportamento |
| --- | --- | --- |
| `dev`, `development` | `env/.env.dev` | API local e faixa DEV |
| `qa`, `staging`, `homolog` | `env/.env.qa` | HTTPS e faixa QA |
| `prod`, `production` ou omitido | `env/.env` | HTTPS, sem faixa |

`--dart-define=API_URL=...` prevalece sobre o arquivo do ambiente. As URLs de QA e produção estão vazias: os projetos de referência não informam os servidores. Configure uma URL real antes de executar nesses ambientes. Sem configuração válida, o aplicativo exibe uma mensagem de inicialização.

```bash
flutter run --dart-define=FLUTTER_ENV=qa \
  --dart-define=API_URL=https://sua-api-qa.exemplo.com
```

Os `.env` são assets públicos incluídos no aplicativo. Não coloque segredos, senhas ou tokens neles.

## Arquitetura

```text
lib/
├── main.dart                       # Inicialização
└── src/
    ├── app.dart                    # Composição do aplicativo
    ├── core/
    │   ├── config/                 # Ambientes e injeção de dependências
    │   ├── enums/                  # Environment
    │   └── utils/                  # Erros e formatação
    ├── data/
    │   ├── datasources/            # HTTP e armazenamento seguro
    │   ├── models/                 # Conversão de JSON
    │   └── repositories/           # Implementações dos contratos
    ├── domain/
    │   ├── entities/               # Usuário, habilidade, tempo, estatísticas
    │   ├── repositories/           # Interfaces dos repositórios
    │   └── usecases/               # Validações, operações e cálculos
    └── presentation/
        ├── core/
        │   ├── bloc/              # Eventos, estados e processamento
        │   ├── design/            # Tema e cores BTTR
        │   └── routes/            # Rotas protegidas
        ├── pages/
        │   ├── auth/bloc/         # BLoC de sessão
        │   ├── skills/            # Lista, formulário e estatísticas
        │   ├── times/             # Histórico e formulário
        │   └── profile/           # Perfil e senha
        └── widgets/               # Navegação e componentes compartilhados
env/                               # .env, .env.dev e .env.qa
android/
ios/
test/
```

O domínio usa Dart puro e não depende de Flutter, HTTP ou armazenamento. Os repositórios convertem respostas da API para entidades; os casos de uso validam os dados e aplicam as regras. `Dependencies` é a raiz de composição e permite substituir implementações nos testes.

O `OperationBloc<T>` separa eventos (`LoadRequested`, `MutationRequested`), estados e ciclo assíncrono compartilhado. Bloqueia envios duplicados, mantém dados do formulário após erro e permite repetir leituras. `SessionBloc` acompanha entrada/saída e atualiza as guardas. As páginas não calculam metas nem montam payloads HTTP.

Dependências: `flutter_bloc`, `flutter_dotenv`, `flutter_secure_storage`, `http`, `go_router`, `intl` e localização oficial do Flutter. Fontes e ícones nativos evitam downloads em execução. Shared Preferences não é necessário: o único dado persistido é o token, no armazenamento seguro.

## Funcionalidades

| Fluxo | Rotas internas | Comportamento |
| --- | --- | --- |
| Autenticação | `/`, `/sign-up`, `/forgot-password` | Login, cadastro e link de recuperação |
| Habilidades | `/home`, `/skills/create`, `/skills/:id/update` | Lista paginada e CRUD |
| Estatísticas | `/skills/:id/statistic` | Meta mensal, acumulado, atraso, percentual e sugestão |
| Tempos | `/times`, `/times/create`, `/times/:id/update` | Histórico paginado e CRUD |
| Conta | `/profile`, `/redefine-password` | Consulta, edição, exclusão e troca de senha |

Navegação inferior, botão voltar do Android e links de retorno; cards adaptados ao toque e a tablets; campos rotulados, visibilidade de senha, autofill e texto ampliado. Exclusões exigem confirmação com descrição dos dados afetados. Mensagens de sucesso, erro, carregamento e estados vazios.

## Regras preservadas

- Meta diária e duração: inteiros de **1 a 1440**, enviados como números.
- Nome de usuário: 2–100 caracteres; habilidade: 2–120; e-mail: até 254.
- Senhas novas: 4–128 caracteres, com maiúscula, minúscula, número e símbolo. Login não impõe composição nova à senha existente. Troca de senha exige confirmação coincidente.
- Listas: cinco itens por página, índices a partir de 1. URLs `next`/`previous` não são seguidas; consultas continuam na API configurada.
- Estatísticas: mês atual no fuso local, do primeiro instante ao último milissegundo, convertido para UTC/ISO-8601 na consulta.
- Dias úteis: segunda a sexta, sem feriados. Sugestão inclui hoje quando útil, arredonda para cima e evita divisão por zero e valores negativos.
- Percentuais podem superar 100%; a barra visual para em 100%.
- A data do registro vem do servidor e não é enviada nas mutações.
- Registrar tempo nas estatísticas pré-seleciona a habilidade, validada contra a lista disponível.
- Criações, edições e exclusões retornam à lista recarregada. Erros de mutação preservam o formulário.

## Contrato HTTP

| Método | Endpoint | Payload / parâmetros |
| --- | --- | --- |
| POST | `/users/sign_in` | `{email,password}` → `{token,user,message}` |
| POST | `/users/sign_up` | `{username,email,password}` |
| POST | `/users/forgot_password` | `{email}` |
| GET / PATCH / DELETE | `/users/profile` | GET → `{user}`; PATCH `{username,email}` |
| POST | `/users/redefine_password` | `{password,new_password}` |
| GET | `/skills/skills_from_user` | `{skills}` |
| GET | `/skills/skills_by_page` | `page` |
| GET | `/skills/skill_by_id/:id` | `{skill}` |
| POST | `/skills/create_skill` | `{name,daily}` |
| PUT | `/skills/update_skill_by_id/:id` | `{name,daily}` |
| DELETE | `/skills/delete_skill_by_id/:id` | Sem corpo |
| GET | `/times/times_by_page` | `page` |
| GET | `/times/times_by_date` | `skill_id`, `date_initial`, `date_final` → `{times}` |
| GET | `/times/time_by_id/:id` | `{time}` |
| POST | `/times/create_time` | `{skill_id,minutes}` |
| PUT | `/times/update_time_by_id/:id` | `{skill_id,minutes}` |
| DELETE | `/times/delete_time_by_id/:id` | Sem corpo |

Mutações retornam `{message}`; listas usam `{count,next,previous,results}`. A recuperação depende do serviço de e-mail do backend. A redefinição pelo link segue o fluxo do servidor, como no Angular.

## Sessão

Token na chave `bttr.token`, via Keychain no iOS e armazenamento criptografado no Android. Restauração antes da primeira tela; se o armazenamento estiver indisponível, a sessão funciona em memória. Backups Android estão desabilitados para evitar restauração de tokens sem a chave original.

`Authorization: Token <token>` é enviado apenas nas chamadas privadas à API configurada. Login, cadastro e recuperação nunca o recebem. Redirecionamentos HTTP estão desabilitados. Um 401 privado encerra a sessão e preserva o destino interno válido para o login; um 401 atrasado de outra sessão não apaga um token novo. Não há renovação de token no contrato.

## Verificação

```bash
./scripts/quality.sh dependencies
./scripts/quality.sh dart-format-check
./scripts/quality.sh dart-lint
./scripts/quality.sh kotlin-check
./scripts/quality.sh swift-format-check
./scripts/quality.sh swift-lint
./scripts/quality.sh test
./scripts/quality.sh test-ci
```

O projeto usa `flutter_lints` com `flutter analyze`, `dart format` (largura de 80
colunas), ktlint para Kotlin e scripts Gradle, `swift-format` e SwiftLint para
Swift. Para aplicar a formatação, execute `./scripts/quality.sh dart-format`,
`./scripts/quality.sh kotlin-format` ou `./scripts/quality.sh swift-format`.
O ktlint é resolvido pelo Gradle; para as verificações Swift locais são
necessários `swift format` (Swift 6+) e `swiftlint` no `PATH`.

O [Jenkinsfile](Jenkinsfile) segue o padrão do cliente Angular: checkout
explícito, gatilhos e status de commit no GitLab, verificações separadas e
artefato de cobertura. O agente precisa de Docker CLI, Compose v2 e acesso ao
daemon; o Jenkins precisa dos plugins GitLab e JUnit usados pelo cliente
Angular, além do Coverage para publicar LCOV. O
[Compose de CI](compose.ci.yaml) executa Flutter 3.41.9,
Swift 6.3.3 e SwiftLint 0.65.0 em contêineres. Se o agente Jenkins também
estiver em um contêiner, configure `CI_HOST_JENKINS_HOME` com o caminho de
`JENKINS_HOME` no host, como no cliente Angular. Para reproduzir uma etapa
localmente, execute, por exemplo:

```bash
./scripts/jenkins-compose.sh flutter ./scripts/quality.sh dart-lint
```

`flutter_test` executa os testes unitários e de widgets. `bloc_test` verifica as
transições de estado dos BLoCs, e `mocktail` isola o repositório de autenticação
nos testes da sessão. A etapa `test-ci` produz cobertura em
`coverage/lcov.info` e converte a saída `--machine` com `junitify` para
`test-results/TEST-flutter.xml`; o Jenkins publica ambos os relatórios. A etapa
preserva a falha de `flutter test` mesmo quando o relatório é gerado. A etapa
`Coverage` exige no mínimo 90% de cobertura de linhas (a suíte atual mede
aproximadamente 94,7%).

Testes cobrem métodos, caminhos e payloads de todos os endpoints; sessão/401;
validações; estatísticas; concorrência no BLoC; fluxos das telas e layouts de
celular/tablet. Mocks existem apenas em `test/`. Esses testes **não executam o
backend real nem o envio de e-mail**.

### Testes E2E mobile com Appium

O projeto usa **Appium 3.7.0**, **UiAutomator2 8.7.0** para Android e
**XCUITest 12.13.2** para iOS. Os testes em `e2e/` dirigem os aplicativos
Flutter compilados pelos controles nativos de acessibilidade. Cobrem login,
logout e criação de habilidade contra o WireMock do `bttr-server`, com
verificação do payload recebido pelo backend mock. O relatório JUnit, logs do
Appium e capturas de falha ficam em `test-results/`.

Para executar localmente, instale Node.js 24+, Flutter 3.41.9, Docker com
Compose v2 e mantenha `../bttr-server/mock-api` disponível. Android requer
SDK/JDK e um emulador já iniciado; iOS requer macOS, Xcode, CocoaPods e um
simulador já iniciado. O script instala as dependências com `npm ci`, instala
o driver Appium da plataforma, sobe o mock, compila o app com a URL correta,
executa os testes e encerra os processos. A porta local do mock é 18080;
configure `BTTR_MOCK_API_PORT` se estiver ocupada. Para selecionar um
dispositivo específico, defina `E2E_ANDROID_UDID` ou `E2E_IOS_UDID`.

O emulador Android precisa de uma imagem **`google_apis`** (build `userdebug`).
Imagens `google_apis_playstore` são builds `user` e não registram a activity
de lançamento de apps instalados por `adb`: o Appium falha ao iniciar o helper
`io.appium.settings` com o erro enganoso `Activity class does not exist`. O
script verifica `ro.build.type` e aborta com essa orientação. Para criar o AVD:

```bash
sdkmanager 'system-images;android-36;google_apis;arm64-v8a'
avdmanager create avd -n e2e-api36 \
  -k 'system-images;android-36;google_apis;arm64-v8a' -d pixel_7
```

```bash
./scripts/appium-e2e-ci.sh android
# Somente local; o CI não executa E2E em iOS
./scripts/appium-e2e-ci.sh ios
```

O Jenkins executa E2E apenas no Android, na etapa **Appium Android E2E**, com
status GitLab próprio e publicação JUnit. A execução em iOS fica disponível
somente localmente. Configure um agente com label `android-e2e` (Linux ou
macOS, Android SDK e emulador iniciado), com Node.js 24+, Flutter 3.41.9 e
acesso ao daemon Docker. A etapa faz checkout de `bttr-server` na branch
definida pelos parâmetros `BTTR_SERVER_REPOSITORY` e `BTTR_SERVER_BRANCH`,
como no pipeline Angular. Ela exige um agente com dispositivo disponível; a
instalação de pacotes npm e drivers Appium também requer acesso ao registro
npm no agente.

## Builds mobile

```bash
# Android de desenvolvimento
flutter build apk --debug --dart-define=FLUTTER_ENV=dev \
  --dart-define=API_URL=http://10.0.2.2:8000

# iOS Simulator, sem assinatura de distribuição
flutter build ios --simulator --debug --dart-define=FLUTTER_ENV=dev

# Produção: configure assinatura e URL antes de distribuir
flutter build appbundle --release --dart-define=FLUTTER_ENV=prod \
  --dart-define=API_URL=https://sua-api.exemplo.com
flutter build ipa --release --dart-define=FLUTTER_ENV=prod \
  --dart-define=API_URL=https://sua-api.exemplo.com
```

Identificadores: Android `com.bttr.bttr_client_flutter`; iOS `com.bttr.bttrClientFlutter`. Confirme-os antes de publicar. Configure a assinatura Android e equipe/provisionamento Apple; a configuração inicial Android usa a chave de debug do template Flutter e **não serve para distribuição**. Nenhum certificado pessoal ou credencial dos projetos de referência foi incorporado. Deploy em lojas e Fastlane não foram configurados, pois exigem dados das contas de distribuição.
