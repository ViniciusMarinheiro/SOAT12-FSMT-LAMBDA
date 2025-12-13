const { app } = require('@azure/functions');
const { cpf: cpfValidator } = require('cpf-cnpj-validator');
const jwt = require('jsonwebtoken');
const { Client } = require('pg');

// Configurações via Variáveis de Ambiente
const JWT_SECRET = process.env.JWT_SECRET || "minha-chave-super-secreta-padrao";
const DB_CONNECTION_STRING = process.env.DB_CONNECTION_STRING;

app.http('authClient', {
    methods: ['POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        context.log('Processando requisição de login/identificação.');

        let body;
        try {
            body = await request.json();
        } catch (error) {
            return { status: 400, body: JSON.stringify({ message: "Corpo da requisição inválido. Envie um JSON." }) };
        }

        const { cpf } = body;

        // 1. Validar formato do CPF
        if (!cpf || !cpfValidator.isValid(cpf)) {
            return { status: 400, body: JSON.stringify({ message: "CPF inválido ou não informado." }) };
        }

        const cpfClean = cpfValidator.strip(cpf);
        let clientData = null;

        // 2. Consultar Cliente no Banco de Dados
        const client = new Client({ connectionString: DB_CONNECTION_STRING });
        
        try {
            await client.connect();
            
            // Supondo que sua tabela se chame 'clientes' e tenha colunas 'cpf', 'id', 'nome'
            const query = 'SELECT id, nome, email FROM clientes WHERE cpf = $1';
            const res = await client.query(query, [cpfClean]);

            if (res.rows.length > 0) {
                clientData = res.rows[0];
                context.log(`Cliente encontrado: ${clientData.nome}`);
            } else {
                // Se o cliente não existe, você pode optar por retornar 404 
                // OU criar um token "anônimo" identificado apenas pelo CPF.
                // Para o Tech Challenge, geralmente identificamos o CPF mesmo sem cadastro prévio para pedidos.
                context.log(`Cliente com CPF ${cpfClean} não encontrado no banco.`);
                
                // Opção A: Retornar erro (Se o cadastro for obrigatório)
                // return { status: 404, body: JSON.stringify({ message: "Cliente não encontrado." }) };

                // Opção B: Permitir token apenas com CPF (Fluxo de pedido sem cadastro completo)
                clientData = { id: null, nome: 'Cliente Identificado', cpf: cpfClean };
            }

        } catch (err) {
            context.log.error("Erro ao conectar no banco:", err);
            return { status: 500, body: JSON.stringify({ message: "Erro interno ao consultar banco de dados." }) };
        } finally {
            await client.end();
        }

        // 3. Gerar Token JWT
        const tokenPayload = {
            id: clientData.id,
            cpf: cpfClean,
            nome: clientData.nome,
            role: 'client' // Define permissões
        };

        const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: '1h' });

        return {
            status: 200,
            jsonBody: {
                token: token,
                client: clientData
            }
        };
    }
});