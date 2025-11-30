## 📱 Implementação Mobile Offline-First (25 Pontos)

### 📝 Especificação

Os alunos devem evoluir o aplicativo "Task Manager" (ou adaptar para "Lista de Compras") para suportar operação completa sem internet, garantindo que dados criados ou editados offline sejam sincronizados automaticamente quando a conexão retornar.

### Requisitos Técnicos:

1.  **Persistência Local (SQLite):** Implementar o `database_service.dart` para salvar tarefas/itens localmente antes de tentar enviar à API.
2.  **Detector de Conectividade:** Utilizar `connectivity_plus` para alternar visualmente entre "Modo Online" (verde) e "Modo Offline" (vermelho/laranja).
3.  **Fila de Sincronização:** Implementar a tabela `sync_queue` no SQLite. Toda ação de CREATE/UPDATE/DELETE feita offline deve gerar um registro nesta fila.
4.  **Resolução de Conflitos (LWW):** Implementar a lógica _Last-Write-Wins_. Se o servidor tiver uma versão mais recente que a local, a local é sobrescrita. Se a local for mais recente (editada offline), ela sobe para o servidor.

### 🎬 Roteiro da Demonstração (Sala de Aula):

O aluno deverá seguir estritamente este fluxo na apresentação:

1.  **Prova de Vida Offline:** Colocar o celular em "Modo Avião". Criar 2 itens e editar 1 item existente. Mostrar que os itens aparecem na lista local com um ícone de "pendente/nuvem cortada".
2.  **Persistência:** Fechar o app completamente (kill process) e abrir novamente (ainda offline). Os dados devem estar lá.
3.  **Sincronização:** Tirar do "Modo Avião". O app deve detectar a rede, enviar os dados automaticamente e mudar o ícone para "check/sincronizado".
4.  **Prova de Conflito:** Simular uma edição no servidor (via Postman) e uma no app simultaneamente, mostrando qual versão prevaleceu.
