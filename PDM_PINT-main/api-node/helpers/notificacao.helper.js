const nodemailer = require('nodemailer');
const utilizador = require('../models/utilizador');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'teu-email@gmail.com',
    pass: process.env.EMAIL_PASS || 'tua-password-do-app'
  }
});

const enviarNotificacaoInscricao = async (db, curso, formando, formador) => {
  try {
    // Buscar admins
    const admins = await db.utilizador.findAll({
  where: { tipo: 'administrador' },
  attributes: ['email', 'nome']
});

    // Email do formando
    const emailFormando = {
      from: process.env.EMAIL_USER || 'teu-email@gmail.com',
      to: formando.email,
      subject: `🎉 Inscrição Confirmada - ${curso.titulo}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #28a745; border-bottom: 2px solid #28a745; padding-bottom: 10px;">🎉 Inscrição Confirmada!</h2>
          <p>Olá <strong>${formando.nome}</strong>,</p>
          <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #495057; margin-top: 0;">Detalhes do Curso:</h3>
            <p><strong>📚 Curso:</strong> ${curso.titulo}</p>
            <p><strong>📖 Tema:</strong> ${curso.tema}</p>
            <p><strong>📅 Início:</strong> ${new Date(curso.data_inicio).toLocaleDateString('pt-PT')}</p>
            <p><strong>📅 Fim:</strong> ${new Date(curso.data_fim).toLocaleDateString('pt-PT')}</p>
            <p><strong>👨‍🏫 Formador:</strong> ${formador?.nome || 'A definir'}</p>
            <p><strong>📊 Tipo:</strong> ${curso.tipo}</p>
          </div>
          <div style="background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #0056b3; margin-top: 0;">🚀 Próximos Passos</h3>
            <p>Sua inscrição foi confirmada! Prepare-se para uma ótima jornada de aprendizagem.</p>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://ai2-frontend-0529.onrender.com/meus-cursos" style="background: #007bff; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">📚 Ver Meus Cursos</a>
          </div>
          <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
          <p style="color: #6c757d; font-size: 0.9em; text-align: center;">Boa sorte nos seus estudos!<br>Equipa SoftSkills</p>
        </div>`
    };

    // Email do formador
    const emailFormador = formador ? {
      from: process.env.EMAIL_USER || 'teu-email@gmail.com',
      to: formador.email,
      subject: `👨‍🎓 Nova Inscrição no Seu Curso - ${curso.titulo}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #007bff; border-bottom: 2px solid #007bff; padding-bottom: 10px;">👨‍🎓 Nova Inscrição no Seu Curso</h2>
          <p>Olá <strong>${formador.nome}</strong>,</p>
          <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #495057; margin-top: 0;">Detalhes da Inscrição:</h3>
            <p><strong>📚 Curso:</strong> ${curso.titulo}</p>
            <p><strong>👤 Novo Formando:</strong> ${formando.nome}</p>
            <p><strong>📧 Email:</strong> ${formando.email}</p>
            <p><strong>📅 Data de Inscrição:</strong> ${new Date().toLocaleDateString('pt-PT')}</p>
          </div>
          <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
            <h3 style="color: #856404; margin-top: 0;">📋 Ação Sugerida</h3>
            <p>Um novo formando inscreveu-se no seu curso. Considere enviar uma mensagem de boas-vindas personalizada.</p>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://ai2-frontend-0529.onrender.com/formador" style="background: #28a745; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">👨‍🏫 Área do Formador</a>
          </div>
          <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
          <p style="color: #6c757d; font-size: 0.9em; text-align: center;">Continue o excelente trabalho!<br>Equipa SoftSkills</p>
        </div>`
    } : null;

    // Email dos administradores
    const emailsAdmins = admins.length > 0 ? admins.map(admin => admin.email) : [];
    const emailAdmins = emailsAdmins.length > 0 ? {
      from: process.env.EMAIL_USER || 'teu-email@gmail.com',
      to: emailsAdmins,
      subject: `📊 Nova Inscrição Registrada - ${curso.titulo}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #6f42c1; border-bottom: 2px solid #6f42c1; padding-bottom: 10px;">📊 Nova Inscrição Registrada</h2>
          <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #495057; margin-top: 0;">Detalhes da Inscrição:</h3>
            <p><strong>📚 Curso:</strong> ${curso.titulo}</p>
            <p><strong>👤 Formando:</strong> ${formando.nome} (${formando.email})</p>
            <p><strong>👨‍🏫 Formador:</strong> ${formador?.nome || 'Não definido'}</p>
            <p><strong>📅 Data:</strong> ${new Date().toLocaleDateString('pt-PT')}</p>
            <p><strong>📊 Estado do Curso:</strong> ${curso.estado}</p>
          </div>
          <div style="background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #0056b3; margin-top: 0;">📈 Gestão de Cursos</h3>
            <p>Nova inscrição registrada no sistema. Acompanhe o progresso das inscrições na área administrativa.</p>
          </div>
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://ai2-frontend-0529.onrender.com/cursos" style="background: #6f42c1; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">📊 Gestão de Cursos</a>
          </div>
          <hr style="border: none; border-top: 1px solid #dee2e6; margin: 30px 0;">
          <p style="color: #6c757d; font-size: 0.9em; text-align: center;">Sistema de notificação automática SoftSkills</p>
        </div>`
    } : null;

    // Enviar os emails
    const emailsEnviados = [];
    await transporter.sendMail(emailFormando);
    emailsEnviados.push('formando');

    if (emailFormador) {
      await transporter.sendMail(emailFormador);
      emailsEnviados.push('formador');
    }

    if (emailAdmins) {
      await transporter.sendMail(emailAdmins);
      emailsEnviados.push(`${admins.length} administrador(es)`);
    }

    console.log(`Notificações enviadas para: ${emailsEnviados.join(', ')}`);
    return { success: true, emailsEnviados };

  } catch (error) {
    console.error('Erro ao enviar notificações:', error);
    return { success: false, error: error.message };
  }
};

module.exports = { enviarNotificacaoInscricao };
