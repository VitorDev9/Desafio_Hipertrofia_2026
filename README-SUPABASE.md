# Supabase · Desafio Hipertrofia 2026

1. Crie um projeto Supabase e execute `supabase-setup.sql` uma vez no SQL Editor. Ele cria `participants`, `weekly_records`, configurações e uma lista privada de membros, com RLS.
2. Em Authentication > Users, crie/convide as quatro contas com e-mail e senha. Autorize cada UUID com o `insert into public.challenge_members` indicado no final do SQL. Desative cadastro público se não precisar dele. Cadastro sozinho não concede acesso ao desafio.
3. Preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY` em `config.js`, usando a URL e a chave pública anon (ou publishable) do projeto. Nunca coloque `service_role`, chave secret ou senha do banco no site/GitHub.
4. Publique os arquivos na raiz do GitHub Pages. Não há etapa de build. O navegador carrega o cliente Supabase pelo jsDelivr; é necessário acesso à internet.
5. Entre no site com uma conta autorizada e clique em Sincronizar. O banco começa vazio. No navegador que contém os dados antigos, use **Enviar backup local ao banco**; ou use **Importar backup** com o JSON exportado. Para iniciar com os dados originais do site, salve uma atualização após entrar no banco vazio. A primeira gravação envia os quatro participantes e as semanas originais.

Todos os membros autorizados podem ler e editar o mesmo desafio, inclusive excluir registros e substituir o conjunto por um backup. Visitantes e contas fora da lista não podem ler nem escrever. As tabelas permitem apenas leitura aos membros; gravação ocorre pela função transacional autorizada. As políticas seguem o modelo de [RLS do Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security).

## Sincronização e backups

O banco configurado é a fonte principal. Salvamentos só são confirmados após resposta do servidor; não existe fila offline. Sem acesso, edição fica bloqueada e os campos podem ser preenchidos novamente após Sincronizar. A cada 15 segundos, a tela consulta o banco quando não está na aba Atualizar. Nessa aba, clique em Sincronizar manualmente (isso recarrega os campos). Uma revisão impede que dois dispositivos sobrescrevam alterações silenciosamente: se houver conflito, sincronize e refaça a edição.

Escolher uma semana apenas navega na tela. Salvar/criar uma semana atualiza a semana compartilhada. Exportar backup gera o mesmo formato JSON anterior. Importar substitui todos os dados de forma atômica após confirmação. Antes de usar o banco, o backup local existente é preservado na chave `desafioHipertrofia2026_v1_antes_supabase`; o botão de envio usa essa cópia. Guarde também um JSON exportado. Desconectar a conta não apaga essa cópia no navegador.

Com os dois campos de configuração vazios, o site continua em modo local. Com configuração incompleta ou banco indisponível, ele avisa e bloqueia gravações; não apresenta uma gravação local como sincronizada. Os dados originais exibidos antes do login são apenas a referência inicial, e a mensagem de conexão indica que os dados compartilhados ainda não foram carregados.

As regras de pontuação permanecem no código original: peso ×4, bônus não cumulativo, braços ×5, antebraços ×3, ombros ×2 e supino com limite de 15 repetições. Pontos são calculados a partir das medições, sem coluna de pontuação editável.

## Verificação após configurar

Entre em dois dispositivos; salve uma medição e sincronize no outro. Tente salvar uma edição antiga para conferir o aviso de conflito. Confira que visitante e conta não autorizada não recebem os registros. Teste exportação/importação com um backup guardado. Sem um projeto e contas configurados, não é possível validar a conexão real nem executar o SQL neste ambiente.
