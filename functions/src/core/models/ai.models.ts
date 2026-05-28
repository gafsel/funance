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
            Você é um assistente financeiro especialista. 
            Analise o histórico de transações do workspace do tipo "{{workspaceType}}":
            {{transactions}}

            Com base no comportamento de gastos e ganhos, sugira 3 metas financeiras relevantes.
            Retorne apenas um array JSON com objetos no seguinte formato:
            {
                "name": "Nome da Meta",
                "targetAmount": 1000.0,
                "type": "saveMoney" | "reduceExpense" | "payDebt",
                "deadlineMonths": 6,
                "icon": "ícone_material_design"
            }
        `,
    document: `
            Você é um assistente financeiro especializado em análise de documentos financeiros (extratos, faturas, contratos de empréstimo, etc).
            Analise o conteúdo do arquivo em anexo "{{fileName}}" e sugira os dados para cadastro de uma conta no app Funances.
            Além dos dados da conta, extraia a lista de transações (orders) presentes no documento e sugira planejamentos financeiros (plannings) baseados nos padrões detectados.

            REGRAS DE CATEGORIZAÇÃO:
            - Utilize preferencialmente as categorias existentes: {{existingCategories}}.
            - Se nenhuma categoria existente for adequada, sugira uma nova categoria concisa.

            CONSIDERAÇÕES DE DOCUMENTO:
            - Se for um EXTRATO/FATURA: Extraia transações reais e sugira planejamentos recorrentes.
            - Se for um CONTRATO DE EMPRÉSTIMO/DÍVIDA: Configure a conta como tipo "debt", defina o saldo inicial como o valor total da dívida (negativo) e extraia as parcelas como planejamentos futuros (se presentes).

            Retorne apenas um objeto JSON no seguinte formato:
            {
                "account": {
                    "name": "Nome sugerido para a conta",
                    "type": "checking" | "investment" | "creditCard" | "debt",
                    "color": "#HEXCODE",
                    "icon": "ícone_material_design",
                    "initialBalance": 0.0,
                    "metadata": {
                        "limit": 0.0,
                        "dueDay": 1,
                        "closingDay": 1
                    }
                },
                "orders": [
                    {
                        "description": "Descrição",
                        "totalAmount": 100.0,
                        "type": "expense" | "income",
                        "categoryName": "Categoria",
                        "categoryIcon": "ícone_material_design",
                        "categoryColor": "#HEXCODE",
                        "date": "YYYY-MM-DD"
                    }
                ],
                "plannings": [
                    {
                        "categoryName": "Categoria",
                        "categoryIcon": "ícone_material_design",
                        "categoryColor": "#HEXCODE",
                        "amount": 500.0,
                        "type": "recurrent" | "unique"
                    }
                ]
            }
        `,
  },
};
