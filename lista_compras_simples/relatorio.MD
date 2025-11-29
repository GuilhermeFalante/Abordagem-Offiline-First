# 📘 Relatório Labs

## 1. Implementações Realizadas

### Principais Funcionalidades Implementadas

Tela de formulário dedicada para criação e edição de tarefas  
Navegação entre telas usando `Navigator.push/pop`  
Sistema completo de validação com `GlobalKey<FormState>`  
Cards customizados com design profissional  
Sistema de filtros (todas, pendentes, concluídas)  
Card de estatísticas com gradiente e métricas  
Feedback visual com `SnackBars` e `Dialogs` de confirmação  
Pull-to-refresh para atualizar a lista  
Estados vazios personalizados para diferentes cenários  

#### Exercícios Complementares Implementados

**Data de Vencimento**: Campo opcional com `DatePicker`, alertas para tarefas vencidas e ordenação por data  
**Sistema de Categorias**: Modelo completo, dropdown no formulário, filtros por categoria e cores distintas  

---

### Componentes Material Design 3 Utilizados

| Componente | Uso |
|-------------|------|
| `Card` | Containers com sombra e bordas arredondadas |
| `ElevatedButton` | Botões principais com elevação |
| `OutlinedButton` | Botões secundários com contorno |
| `FloatingActionButton.extended` | FAB com texto |
| `TextField/TextFormField` | Campos de entrada com validação |
| `DropdownButtonFormField` | Seletores com validação |
| `SwitchListTile` | Toggle com label e ícone |
| `AppBar` | Barra superior com ações |
| `SnackBar` | Mensagens de feedback temporárias |
| `AlertDialog` | Diálogos de confirmação |
| `PopupMenuButton` | Menus suspensos |
| `FilterChip` | Filtros interativos |
| `RefreshIndicator` | Pull-to-refresh |
| `Checkbox` | Seleção booleana customizada |

---

## 2. Desafios Encontrados

### Desafio : Migração de Schema do SQLite
**Problema:**  
Ao adicionar novos campos (`dueDate`, `categoryId`) ao modelo `Task`, era necessário atualizar o banco existente sem perder dados.  

**Solução:**  
Implementado o método `_upgradeDB` no `DatabaseService` que:
- Verifica a versão atual do banco  
- Executa `ALTER TABLE` para adicionar novas colunas  
- Atualiza registros existentes com valores padrão  

---

### Desafio 2: Gerenciamento de Estado entre Telas
**Problema:**  
Manter a lista de tarefas atualizada após navegação entre `TaskListScreen` e `TaskFormScreen`.  

**Solução:**  
Usado o padrão de retorno com `Navigator.pop(context, true)` e recarregado os dados no `initState` com `await _loadTasks()`.

---

## 3. Melhorias Implementadas

### Parte além do roteiro:

### 1. Sistema de Categorias Avançado
- 7 categorias pré-definidas com cores e ícones únicos  
- Chips interativos para filtro rápido  
- Badges coloridas nos cards das tarefas  
- Ordenação por categoria  
- Estatísticas específicas por categoria  

### 2. Validações Avançadas
- Título com mínimo de 3 caracteres  
- Alertas visuais para tarefas vencidas  
- Prevenção de datas passadas  
- Mensagens de erro descritivas  

### Customizações feitas:

### 1. Experiência do Usuário Aprimorada
- Estados vazios contextualizados  
- Confirmação para exclusão com `AlertDialog`  
- Loading states em todas as operações assíncronas  
- Feedback visual diferenciado por prioridade e categoria  
---

## 4. Aprendizados

### Principais Conceitos Aprendidos

#### Arquitetura e Organização
- Separação em camadas: **Models**, **Services**, **Screens**, **Widgets**  
- Singleton pattern para `DatabaseService`  
- Widgets customizados reutilizáveis (`TaskCard`)  
- Gerenciamento de estado entre telas  

#### UI/UX
- Feedback visual: SnackBars, dialogs e loading states  
- Acessibilidade: contraste, tamanho de toque, legibilidade  

---

### 🔁 Diferenças entre Lab 1 e Lab 2

| Aspecto | Lab 1 (Básico) | Lab 2 (Profissional) |
|----------|----------------|----------------------|
| Arquitetura | Tudo em um arquivo | Separado em camadas |
| UI | ListTile simples | Cards customizados |
| Navegação | Nenhuma | Múltiplas telas |
| Formulários | Inline | Tela dedicada com validação |
| Feedback | Nenhum | SnackBars, Dialogs, Loading |
| Funcionalidades | CRUD básico | Filtros, estatísticas, categorias |
| Experiência | Funcional | Agradável e intuitiva |
| Código | ~150 linhas | +1000 linhas organizadas |

---

## 5. Próximos Passos

### Oque eu gostaria de adicionar:
- Persistência em banco de dados ao invés de usar o sqlite.
- Implementação de controllers para o projeto.

### Ideias para melhorar a aplicação:
- Aumentar a quantidade de serviços que a aplicação possui, como fazer uma lista de compras, possuindo todos os itens necessários.
