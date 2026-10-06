# Verificação da entrega

## Executado

`npm test`: **15 testes passaram**.

- Cálculo proporcional da tabela nutricional (100 g → 35 g).
- Calorias desconhecidas bloqueiam a gravação; macros desconhecidos são permitidos e identificados.
- Semana de segunda a domingo na mudança de ano e datas do calendário local.
- Quatro sessões de treino com equipamentos/volume inicial compatíveis.
- Restrições suspendem o gerador; grupos excluídos não aparecem.
- Eliminação por tombstones e recusa de backup duplicado.
- Renderização dos cinco ecrãs com um ambiente DOM mínimo simulado, com e sem dados.
- Escape de nomes fornecidos pelo utilizador.
- Handler do servidor com Auth e API simulados: origem, token, quota, payload inválido, resposta estruturada, kcal em falta, rótulo ambíguo e imagem ilegível.

`node --check`: app.js, core.js, sw.js sem erros de sintaxe.

Verificados os recursos locais referenciados pelo HTML e manifest: presentes, ícones válidos, início e âmbito relativos para uma subpasta do GitHub Pages.

## Limites da verificação

- O navegador de teste não estava instalado no ambiente. Não foi concluída uma inspeção visual em navegador nem os testes de toque, overflow e reload offline reais. Os testes de renderização são de geração de HTML, não de layout.
- O handler TypeScript foi testado como JavaScript após remover as suas anotações de tipos conhecidas. Não foi executado `deno check` no ambiente.
- Os pedidos de Auth e OpenAI dos testes são simulados. Não foi enviada uma fotografia real à API, não foi utilizada uma chave secreta e não se verificou saldo/custo do utilizador.
- O SQL/RLS não foi executado num projeto Supabase nesta entrega. É necessário aplicar e verificar a configuração real.
- O repositório ainda não foi criado/publicado. O URL indicado no README é o esperado após a instalação; não é confirmação de um site online.

## Após instalar

1. Abrir a página no telemóvel e computador; preencher o perfil atual.
2. Gravar uma refeição manual; conferir soma diária e semana; editar a quantidade.
3. Gerar treino, abrir um guia e registar uma sessão.
4. Fechar/reabrir; confirmar que os registos persistem e que o app abre offline depois da primeira visita completa.
5. Aplicar o SQL, criar/usar uma conta, sincronizar e conferir num segundo dispositivo.
6. Configurar os segredos da Edge Function e autorizar o email para IA.
7. Testar uma tabela nutricional legível e comparar com o rótulo; testar uma foto de prato e corrigir a quantidade estimada.
