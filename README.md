# RG Fit — Nutrição e treino

PWA em português para telemóvel e computador. Nome provisório, editável no HTML e no manifest.

## O que já funciona

- Diário de refeições: registo manual, edição de alimentos e quantidades, soma de kcal, proteínas, hidratos e gorduras.
- Resumo diário e histórico semanal, com dias sem registo identificados. A média semanal inclui apenas dias registados.
- Fotografia do prato: análise pela IA, seguida de revisão dos alimentos/quantidades pelo utilizador.
- Fotografia de tabela nutricional: leitura de uma referência (100 g, 100 ml ou porção) e cálculo proporcional para a quantidade consumida.
- Perfil atual, equipamentos, experiência, tempo disponível e restrições.
- Gerador por regras para quatro dias de academia (superiores / inferiores); guias de equipamento e execução; registo de cargas, repetições, séries e duração.
- Evolução de peso, exportação/importação de backup, funcionamento local sem internet após a primeira visita completa.
- Sincronização opcional com conta Supabase, registos separados por utilizador e revisão de conflitos entre dispositivos.

A leitura de fotos só funciona depois de configurar o servidor, uma conta autorizada e a API da OpenAI. O app não simula uma análise nem inventa resultados quando a ligação está em falta. O treino é gerado localmente por regras: não necessita de IA.

## 1. Colocar no GitHub

1. Crie um repositório chamado `rg-fit` na conta `rafaelgiacometti-beep`.
2. Extraia o ZIP. Envie **o conteúdo da pasta rg-fit**, não a pasta exterior inteira, para a raiz do repositório. `index.html` deve ficar na raiz.
3. Em **Settings → Pages**, selecione **Deploy from a branch**, branch `main`, pasta `/(root)` e grave.
4. Aguarde a publicação. O endereço esperado, depois de publicar, é `https://rafaelgiacometti-beep.github.io/rg-fit/`.
5. Abra o endereço, preencha o peso atual e os equipamentos no Perfil, e selecione **Guardar e gerar treino**.

Não é necessário instalar Node nem executar compilação para publicar. O ZIP pode incluir a pasta `supabase/` e os testes; não contém segredos.

### Instalar no telemóvel

- iPhone: abra no Safari → Partilhar → Adicionar ao ecrã principal.
- Android: abra no Chrome e use Instalar app / Adicionar ao ecrã principal.
- Computador: use o botão de instalação do navegador, quando disponível.

## 2. Ativar conta e sincronização

Pode reutilizar o projeto Supabase dos outros sistemas. As tabelas começam por `rgfit_` e não alteram o RG3D ou Medical R.G.

1. No Supabase, abra **SQL Editor**, cole o conteúdo de `supabase/schema.sql` e execute. O SQL é repetível; não apaga tabelas de outros sistemas.
2. Em **Authentication → Users**, use a conta existente ou crie um utilizador com email e palavra-passe. Não ative registo público só para usar este app.
3. Copie o **Project URL** e a **Publishable key** (ou a antiga **anon public**) nas definições do projeto.
4. No RG Fit, abra a engrenagem e preencha **Project URL** e **chave publicável / anon public**. Guarde e entre com o email e a palavra-passe.
5. Se começou a usar o diário antes de entrar, escolha **Copiar dados deste dispositivo para a conta**. A cópia é uma escolha explícita; os dados locais e da conta ficam separados.
6. Use **Sincronizar agora** antes de trocar de dispositivo e depois de voltar a abrir a conta.

A sessão fica neste separador / sessão do navegador. Ao reabrir o app pode ser necessário entrar de novo. Os dados já descarregados continuam disponíveis no dispositivo, sem depender da sessão. Em dispositivos partilhados, não deixe os seus dados guardados no navegador.

## 3. Ativar análise de fotografias

A OpenAI API é um serviço separado e pode ter custos. Uma assinatura do ChatGPT não configura automaticamente a API deste sistema. Não envie a chave secreta por chat e não a coloque no GitHub, no HTML ou no campo de chave pública do app.

### Pelo painel Supabase

1. Em **Edge Functions**, crie uma função chamada exatamente `rgfit-analyze`.
2. Substitua o código pelo conteúdo de `supabase/functions/rgfit-analyze/index.ts` e publique.
3. Para esta função, desative a opção de verificação JWT do gateway (Verify JWT / Enforce JWT verification). O código valida o JWT da sessão com o Supabase Auth antes de permitir a análise. Não remova essa validação do handler. Esta configuração é indicada também em `supabase/config.toml`.
4. Em **Edge Functions → Secrets**, adicione:
   - `OPENAI_API_KEY`: chave secreta da sua conta da API.
   - `OPENAI_MODEL`: `gpt-4.1-mini`, ou outro modelo da sua conta com visão, Responses API e Structured Outputs compatíveis.
   - `ALLOWED_ORIGIN`: `https://rafaelgiacometti-beep.github.io` (sem `/rg-fit/`). Para testes, pode adicionar outra origem exata separada por vírgula; não use `*`.
5. `SUPABASE_URL` e `SUPABASE_ANON_KEY` são segredos padrão das Edge Functions. O código utiliza a chave anon padrão no servidor e valida o token do utilizador.
6. Autorize o seu email no **SQL Editor** (substitua `SEU_EMAIL`):

```sql
insert into public.rgfit_ai_members(user_id)
select id from auth.users where lower(email)=lower('SEU_EMAIL')
on conflict do nothing;
```

7. Abra o app, entre na conta, selecione uma foto e clique em **Analisar foto**. Confira os valores antes de guardar.

### Alternativa com CLI

```bash
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase functions deploy rgfit-analyze --no-verify-jwt
```

Configure os segredos pelo painel; não grave a chave num comando que possa ficar no histórico.

### Limites e privacidade

- Apenas utilizadores explicitamente autorizados podem consumir a API.
- Limite de 30 tentativas de análise por conta por dia, medido no horário de Lisboa. Uma falha após consumir a quota também conta como tentativa.
- Imagem redimensionada no navegador; a função impõe limite de tamanho, valida a sessão e aceita apenas origens configuradas.
- A chave da IA permanece no servidor. O pedido usa `store: false` na OpenAI; isso não constitui promessa de retenção zero pelo fornecedor.
- O diário guarda dados nutricionais, não fotografias. A foto é enviada à IA apenas quando o utilizador pede a análise.
- Sem configuração, internet, sessão ou saldo, use o preenchimento manual. Não há reconhecimento de imagem offline.

## Uso diário

1. Na página Hoje, escolha a data e adicione a refeição por foto ou manualmente.
2. Para um rótulo, indique o consumo na **mesma unidade da referência**. 35 g de um produto com 380 kcal/100 g correspondem a 133 kcal.
3. Corrija ingredientes, óleo, molhos e quantidade. Ao mudar a quantidade, os nutrientes são recalculados proporcionalmente.
4. Os macros desconhecidos ficam vazios. A soma mostra apenas valores preenchidos; os registos incompletos são identificados.
5. Na Semana, escolha um dia para ver/adicionar refeições. Dias sem registo mostram um traço, não um consumo de zero.
6. No Treino, use o guia **Como fazer**, registe cargas e as séries realmente feitas. Não se atribui carga automaticamente a partir do peso corporal.
7. Guarde um backup e sincronize, quando usar conta.

## Treinos e metas

A primeira configuração pede o peso atual. 35 anos e 181 cm são dados iniciais editáveis; não foi presumido que o peso anterior continua correto. O plano considera os equipamentos e o tempo. Uma restrição escrita suspende a geração automática. Ao alterar o perfil, o plano anterior é invalidado e precisa de ser gerado novamente.

O objetivo é apoiar alimentação, força e regularidade. O sistema não garante perda de peso nem ganho muscular. A meta calórica é opcional e indicada pelo utilizador ou pelo seu profissional; o app não prescreve uma dieta automaticamente. Os ícones de equipamento são esquemáticos e não substituem uma demonstração pelo instrutor.

Orientação geral: combinar treino de força com atividade aeróbica gradual e recuperação. A referência do NHS recomenda trabalhar os grandes grupos musculares pelo menos duas vezes por semana e acumular atividade aeróbica conforme a capacidade. O exemplo de divisão e as séries do RG Fit são uma implementação inicial, não uma recomendação individual publicada pelo NHS.

## Verificação e manutenção

```bash
npm test
npm run serve
```

Abra `http://localhost:8080`. Em alterações ao app, atualize a versão `CACHE` de `sw.js` para invalidar a cache antiga. O service worker usa caminhos relativos, incluindo a publicação numa subpasta do GitHub Pages.

A gravação local depende do armazenamento do navegador; limpar os dados do site elimina a cópia local. Use backups/sincronização. Conflitos de sincronização não descartam silenciosamente uma versão: aparecem na engrenagem para escolher manter os dados locais ou da conta. Faça backup antes de resolver divergências grandes.

### Estado da entrega

Os ficheiros foram preparados para instalação. A publicação real, o SQL/RLS num projeto Supabase e a leitura de imagens com uma chave da API necessitam de configuração nas suas contas e não estão certificados só pelos testes locais. Consulte `VERIFICACAO.md` para os testes efetivamente executados.

## Referências técnicas e de atividade física

- https://developers.openai.com/api/docs/guides/images-vision
- https://developers.openai.com/api/docs/guides/structured-outputs
- https://supabase.com/docs/guides/functions/auth-legacy-jwt
- https://supabase.com/docs/reference/javascript/auth-getuser
- https://www.nhs.uk/live-well/exercise/physical-activity-guidelines-for-adults-aged-19-to-64/
- https://www.nhs.uk/live-well/exercise/how-to-improve-strength-flexibility/
