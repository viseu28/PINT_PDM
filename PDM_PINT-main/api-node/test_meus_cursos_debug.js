async function testarMeusCursos() {
    try {
        // Substitua pelo ID do usuário que está testando
        const userId = 8; // ou 8, dependendo do usuário de teste
        
        console.log('🔍 Testando endpoint de meus cursos para usuário:', userId);
        
        const response = await fetch(`http://192.168.1.68:3000/inscricoes/${userId}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                // Se necessário, adicione o token aqui
                // 'Authorization': 'Bearer SEU_TOKEN'
            }
        });
        
        console.log('✅ Status:', response.status);
        
        if (response.ok) {
            const data = await response.json();
            console.log('📊 Total de inscrições:', data.data?.length || 0);
            
            if (data.data) {
                data.data.forEach((inscricao, index) => {
                    console.log(`\n📚 Curso ${index + 1}: ${inscricao.titulo}`);
                    console.log(`   - ID: ${inscricao.idcurso}`);
                    console.log(`   - Síncrono: ${inscricao.sincrono} (${typeof inscricao.sincrono})`);
                    console.log(`   - Data início: ${inscricao.data_inicio}`);
                    console.log(`   - Data fim: ${inscricao.data_fim}`);
                    
                    // Calcular estado baseado na data
                    let estado = 'Em Curso';
                    if (inscricao.data_fim) {
                        const dataFim = new Date(inscricao.data_fim);
                        const agora = new Date();
                        estado = agora > dataFim ? 'Terminado' : 'Em Curso';
                    }
                    console.log(`   - Estado calculado: ${estado}`);
                    
                    // Verificar se deve ser removido
                    const isAssincrono = inscricao.sincrono === false || inscricao.sincrono === 'false' || 
                                        inscricao.sincrono === 'Assíncrono' || inscricao.sincrono === 'assíncrono';
                    const isTerminado = estado === 'Terminado';
                    
                    console.log(`   - É assíncrono: ${isAssincrono}`);
                    console.log(`   - É terminado: ${isTerminado}`);
                    console.log(`   - Deve ser removido da lista: ${isAssincrono && isTerminado}`);
                });
            }
        } else {
            console.error('❌ Erro HTTP:', response.status);
        }
        
    } catch (error) {
        console.error('❌ Erro ao testar:', error.message);
    }
}

testarMeusCursos();
