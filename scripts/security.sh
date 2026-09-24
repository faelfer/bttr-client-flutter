#!/bin/sh
set -eu

# Camada 1 de segurança, no mesmo formato de scripts/quality.sh: um subcomando
# por verificação, executado dentro do serviço "security" do compose.ci.yaml.
#
# Cada ferramenta grava SARIF em test-results/security/ e devolve o próprio
# código de saída. O portão não é reimplementado aqui: quem decide o que é
# achado bloqueante é a ferramenta, com a severidade configurada abaixo.
#
# SECURITY_GATE=report executa tudo e produz os relatórios sem reprovar o
# estágio — é o modo de calibragem das primeiras semanas. SECURITY_GATE=enforce
# (padrão) reprova.

REPORTS='test-results/security'
GATE="${SECURITY_GATE:-enforce}"
case "$GATE" in
    enforce|report) ;;
    *) echo "SECURITY_GATE deve ser enforce ou report, recebido: $GATE" >&2; exit 2 ;;
esac

mkdir -p "$REPORTS"

# Executa a ferramenta preservando o código de saída dela, e converte reprovação
# em aviso quando o portão está em modo de relatório. Falha de execução da
# própria ferramenta (código 2 ou acima, pelo padrão das quatro) continua
# reprovando em qualquer modo: relatório vazio por ferramenta quebrada não pode
# passar por ausência de achado.
run_gated() {
    tool="$1"
    shift
    set +e
    "$@"
    run_status=$?
    set -e
    if [ "$run_status" -eq 0 ]; then
        echo "[$tool] sem achados bloqueantes."
        return 0
    fi
    if [ "$run_status" -eq 1 ] && [ "$GATE" = report ]; then
        echo "[$tool] achados registrados em $REPORTS; portão em modo de relatório."
        return 0
    fi
    if [ "$run_status" -eq 1 ]; then
        echo "[$tool] achados bloqueantes. Relatório em $REPORTS." >&2
    else
        echo "[$tool] falhou ao executar (código $run_status)." >&2
    fi
    return "$run_status"
}

# Resumo legível no console do Jenkins, a partir do SARIF que acabou de sair.
# Achados suprimidos continuam no relatório — a exceção fica registrada e
# visível — mas são contados à parte, para não se confundirem com o que passou.
summarize() {
    report="$REPORTS/$1.sarif"
    [ -f "$report" ] || return 0
    jq -r --arg tool "$1" '
        [.runs[].results[]?] as $all
        | ($all | map(select((.suppressions // []) | length == 0))) as $active
        | ($all | length) - ($active | length) as $suppressed
        | "[\($tool)] \($active | length) achado(s)"
          + (if $suppressed > 0 then " (+\($suppressed) suprimido(s))" else "" end)
          + ( $active
              | group_by(.ruleId // "sem-regra")
              | map("\n  - \(.[0].ruleId // "sem-regra"): \(length)")
              | join("") )
    ' "$report" || true
}

case "${1:-}" in
    secrets)
        # Varredura da árvore de trabalho: é ela que vira APK. O histórico entra
        # no subcomando secrets-history, separado porque cresce com o repositório
        # e não precisa rodar a cada commit.
        status=0
        run_gated gitleaks gitleaks dir . \
            --config security/gitleaks.toml \
            --report-format sarif \
            --report-path "$REPORTS/gitleaks.sarif" \
            --redact \
            --no-banner || status=$?
        summarize gitleaks
        exit "$status"
        ;;
    secrets-history)
        [ -d .git ] || { echo 'Sem .git: histórico indisponível.' >&2; exit 2; }
        status=0
        run_gated gitleaks-history gitleaks git . \
            --config security/gitleaks.toml \
            --report-format sarif \
            --report-path "$REPORTS/gitleaks-history.sarif" \
            --redact \
            --no-banner || status=$?
        summarize gitleaks-history
        exit "$status"
        ;;
    deps)
        # O que chega ao usuário. pubspec.lock é a única lista de dependências
        # que vira código dentro do APK e do IPA, então ela reprova o estágio.
        status=0
        run_gated osv-scanner osv-scanner scan source \
            --lockfile pubspec.lock \
            --config security/osv-scanner.toml \
            --format sarif \
            --output-file "$REPORTS/osv-scanner-app.sarif" || status=$?
        summarize osv-scanner-app
        exit "$status"
        ;;
    deps-toolchain)
        # Appium, WebdriverIO e Mocha nunca entram no artefato: eles executam no
        # container de CI, contra o mock. O risco existe — é a cadeia de
        # suprimento do próprio pipeline — mas não é da mesma natureza do que
        # chega ao aparelho do usuário, e parte das vulnerabilidades dessa árvore
        # não tem correção publicada. O estágio reporta e não reprova; quem lê o
        # relatório no Jenkins decide quando atualizar a árvore.
        #
        # Uma vulnerabilidade aqui que justifique bloquear entra como decisão
        # explícita: mova o pacote para security/osv-scanner.toml ou promova este
        # subcomando a enforce.
        status=0
        GATE=report
        run_gated osv-scanner-toolchain osv-scanner scan source \
            --lockfile package-lock.json \
            --config security/osv-scanner.toml \
            --format sarif \
            --output-file "$REPORTS/osv-scanner-toolchain.sarif" || status=$?
        summarize osv-scanner-toolchain
        exit "$status"
        ;;
    sast)
        # Regras públicas fixadas na imagem mais as regras deste projeto. O
        # --error faz o Semgrep reprovar em achado de severidade ERROR; achados
        # WARNING entram no SARIF e aparecem no Jenkins sem travar o merge.
        status=0
        run_gated semgrep semgrep scan \
            --config /opt/semgrep-rules/kotlin/lang/security \
            --config /opt/semgrep-rules/kotlin/gradle/security \
            --config /opt/semgrep-rules/swift \
            --config /opt/semgrep-rules/javascript/lang/security \
            --config security/semgrep \
            --exclude node_modules \
            --exclude build \
            --exclude .dart_tool \
            --exclude .pub-cache \
            --exclude test-results \
            --exclude coverage \
            --exclude .appium \
            --exclude .ci \
            --metrics off \
            --disable-version-check \
            --error \
            --severity ERROR \
            --sarif-output "$REPORTS/semgrep.sarif" \
            --quiet \
            . || status=$?
        summarize semgrep
        exit "$status"
        ;;
    iac)
        # Duas leituras complementares do mesmo Dockerfile: o Hadolint checa a
        # forma da instrução, o Trivy checa a configuração resultante contra as
        # políticas dele. O bundle de checagens vem embutido na imagem.
        status=0
        run_gated trivy trivy config . \
            --config security/trivy.yaml \
            --ignorefile security/trivy-ignore.yaml \
            --format sarif \
            --output "$REPORTS/trivy-config.sarif" || status=$?
        summarize trivy-config

        # Sem espaços nos caminhos deste repositório, o IFS de linha basta para
        # montar a lista de arquivos sem depender de xargs, que mascararia o
        # código de saída do Hadolint.
        IFS='
'
        set -- $(find . -name 'Dockerfile*' \
            -not -path './node_modules/*' \
            -not -path './build/*' \
            -not -path './.ci/*' | sort)
        unset IFS
        [ "$#" -gt 0 ] || {
            echo 'Nenhum Dockerfile encontrado para o Hadolint.' >&2
            exit 2
        }
        run_gated hadolint hadolint \
            --config security/hadolint.yaml \
            --format sarif \
            --output "$REPORTS/hadolint.sarif" \
            "$@" || status=$?
        summarize hadolint
        exit "$status"
        ;;
    all)
        status=0
        for check in secrets deps deps-toolchain sast iac; do
            echo "=== $check ==="
            "$0" "$check" || status=1
        done
        exit "$status"
        ;;
    *)
        echo "Uso: $0 {secrets|secrets-history|deps|deps-toolchain|sast|iac|all}" >&2
        exit 2
        ;;
esac
