export interface AIConfig {
  models: {
    goals: string;
    document: string;
  };
  prompts: {
    goals: string;
    document: string;
  };
}

export const DEFAULT_CONFIG: AIConfig = {
    models: {
        goals: "gemini-1.5-flash-latest",
        document: "gemini-1.5-pro-latest",
    },
    prompts: {
        goals: `
            Você é um assistente financeiro especialista em planejamento financeiro. 
            Analise o contexto do workspace do tipo "{{workspaceType}}":
            Categorias existentes: {{categories}}
            Ordens (lançamentos) recentes: {{orders}}

            Com base no comportamento de gastos e ganhos, sugira:
            1. Três metas financeiras relevantes (goals).
            2. Planejamentos mensais por categoria (plannings).

            REGRAS:
            - Use preferencialmente as categorias existentes. Só sugira uma nova se for estritamente necessário.
            - "plannings" deve focar no valor mensal planejado para a categoria.

            Retorne apenas um objeto JSON no seguinte formato:
            {
                "goals": [
                    {
                        "name": "Nome da Meta",
                        "targetAmount": 1000.0,
                        "type": "save_money" | "reduce_expense" | "reduce_credit_card",
                        "deadlineMonths": 6,
                        "icon": "ícone_material_design"
                    }
                ],
                "plannings": [
                    {
                        "category": {
                            "name": "Categoria",
                            "icon": "ícone_material_design",
                            "color": "#HEXCODE",
                            "type": "income" | "expense"
                        },
                        "amount": 500.0
                    }
                ]
            }
        `,
        document: `
            Você é um assistente financeiro especializado em análise de documentos financeiros (extratos, faturas, contratos de empréstimo, etc).
            Analise o conteúdo do arquivo em anexo "{{fileName}}" e sugira os dados para cadastro de uma conta no app Funances.
            Além dos dados da conta, extraia a lista de transações (orders) presentes no documento.

            REGRAS DE CATEGORIZAÇÃO:
            - Utilize OBRIGATORIAMENTE as categorias existentes se houver similaridade: {{existingCategories}}.
            - Só sugira uma nova categoria se não houver nenhuma similar nas existentes.

            CONSIDERAÇÕES DE DOCUMENTO:
            - Se for um EXTRATO/FATURA: Extraia transações reais (orders).
            - Se for um CONTRATO DE EMPRÉSTIMO/DÍVIDA: Configure a conta como tipo "debt", defina o saldo inicial como o valor total da dívida (negativo) e extraia as parcelas futuras se houver
            - A data e o saldo inicial devem indicar o valor antes dos lançamentos (orders) identificados.

            Retorne apenas um objeto JSON no seguinte formato:
            {
                "account": {
                    "id": "temp-id",
                    "name": "Nome sugerido para a conta",
                    "runtimeType": "checking" | "investment" | "creditCard" | "debt",
                    "color": "#HEXCODE",
                    "icon": "ícone_material_design",
                    "initialBalance": 0.0,
                    "initialBalanceDate": "YYYY-MM-DD",
                    "interestRate": 0.0,
                    "limit": 0.0,
                    "dueDay": 1,
                    "closingDay": 1
                },
                "orders": [
                    {   
                        "type": "expense" | "income",
                        "category": {
                            "name": "Categoria",
                            "icon": "ícone_material_design",
                            "color": "#HEXCODE",
                            "type": "income" | "expense"
                        },
                        "description": "Descrição",
                        "amount": 100.0,
                        "dueDate": "YYYY-MM-DD",
                        "installmentType": "single" | "installment" | "recurring",
                        "installmentCount": 1
                    }
                ]
            }
        `,
    },
};
