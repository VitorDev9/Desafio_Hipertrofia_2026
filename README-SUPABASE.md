# Banco compartilhado sem contas

O site salva e carrega os dados do Supabase automaticamente, sem cadastro, login ou senha. O visual e as regras de pontuação foram preservados.

## Ativar

1. Crie um projeto Supabase e execute `supabase-setup.sql` no SQL Editor **uma vez**.
2. Preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY` em `config.js` com a URL e a chave pública anon (ou publishable) do projeto. Nunca use `service_role`, chave secret ou senha do banco.
3. Abra o site publicado no GitHub Pages. Ele se conecta e, se o banco estiver vazio, grava os dados originais do desafio automaticamente.

**Se já executou o SQL antigo com contas:** execute apenas `supabase-sem-login.sql` para atualizar as permissões e funções, preservando os dados. Não precisa criar usuários nem autorizar membros. A tabela antiga de membros pode ficar; não será utilizada.

Para trazer dados mais recentes do navegador antigo, use **Enviar backup local ao banco** ou importe o JSON exportado. A substituição dos dados compartilhados exige confirmação na tela. O backup local anterior fica separado para não ser perdido ao carregar o banco.

## Acesso e sincronização

Este é um painel aberto: **qualquer visitante pode ler, alterar e excluir os registros**. A chave pública aparece no navegador e não funciona como senha. RLS permanece ativa, com leitura pública; gravações passam por uma função transacional com validação de campos e controle de revisão. Não há escrita direta nas tabelas. Isso limita o formato dos dados, mas não identifica nem restringe quem faz alterações. Consulte a [documentação de RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

O Supabase configurado é a fonte principal. Um salvamento só é confirmado após resposta do banco. Conflitos entre dispositivos são recusados: clique em **Sincronizar** e refaça a edição. O site consulta alterações a cada 15 segundos fora da aba Atualizar; nessa aba, use o botão manualmente para não interromper o preenchimento. Conexões interrompidas são tentadas novamente automaticamente.

Com a configuração vazia, o site continua local. Com configuração incompleta ou conexão indisponível, ele avisa e não confirma alterações como sincronizadas. Não existe fila offline. Exportar/importar continua usando o formato JSON anterior. O cliente Supabase é carregado do jsDelivr e requer internet. Nenhuma compilação é necessária.

Após configurar, confira em dois dispositivos: salve em um e sincronize no outro; teste também o aviso de conflito com uma edição antiga. A conexão real e a execução do SQL dependem do projeto Supabase configurado.
