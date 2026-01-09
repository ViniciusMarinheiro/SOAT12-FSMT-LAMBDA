# SOAT12-FSMT-LAMBDA

## 📝 Descrição do Propósito
Contém as **Azure Functions** para processamento serverless. Utilizado para gatilhos event-driven que não necessitam de servidores dedicados permanentes.

## 🛠 Tecnologias Utilizadas
* **Azure Functions**: Serverless computing.
* **Python/Node.js**: Linguagem da função.
* **Application Insights**: Telemetria.

## 🚀 Passos para Execução e Deploy

### 💻 Execução Local
1. **Core Tools**: Instale o `Azure Functions Core Tools`.
2. **Executar**: `func start`
3. **Debug**: Utilize o VS Code com a extensão Azure Functions.

### ☁️ Execução na Nuvem (CI/CD)
1. **GitHub Action**: O workflow utiliza `azure/functions-action` para o deploy.
2. **Publish**: O código é compilado e publicado no Function App existente.
3. **Apply Cloud**: O deploy ocorre em cada push para a branch `main`.
