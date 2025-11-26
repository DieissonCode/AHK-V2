# Instruções do GitHub Copilot

## Idioma

-   Escreva todas as mensagens de commit em português brasileiro (pt-BR) em linguagem técnica clara e objetiva. 
-   Mantenha apenas os prefixos (feat, fix, refactor, perf, chore) em inglês.

## Diretrizes para Mensagens de Commit

-   Escreva mensagens de commit curtas e claras. 
-   Comece com um verbo no imperativo (ex.: "Add", "Fix", "Update"). 
-   Insira uma linha em branco entre o assunto e o corpo. 
-   Explique o quê e por quê, nunca como.
-   Referencie números de issues quando relevante (ex.: "Fixes #123"). 

## Regras Específicas para AHK

-   Extraia a versão do arquivo da terceira linha do arquivo. 
-   A versão aparece após " = " em linhas como:
        ;@Ahk2Exe-Let U_FileVersion = 0.0.2. 4
-   Sempre inclua a versão detectada no corpo do commit como:
        "File version: X.X.X. X"

-   Destaque alterações em hotkeys, timers, handlers, condições e fluxos.
-   Mencione impactos em outros módulos ou scripts.
-   Diferencie refactor de fix. 
-   Anote atualizações relevantes para performance. 
-   Avise quando funções, classes, prototypes ou globais forem renomeadas/movidas. 

## Prefixos

-   feat: nova funcionalidade
-   fix: correção de bug
-   refactor: alterações internas
-   perf: melhoria de performance
-   chore: pequena limpeza/manutenção

## Evite

-   Mensagens vagas como "ajustes", "teste", "atualização".