const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('cursos', {
    id: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    titulo: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    tema: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    data_inicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    data_fim: {
      type: DataTypes.DATE,
      allowNull: false
    },
    tipo: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    estado: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    imgcurso: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    avaliacao: {
      type: DataTypes.DECIMAL(3,2),
      allowNull: true
    },
    dificuldade: {
      type: DataTypes.STRING(50),
      allowNull: true
    },
    pontos: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    requisitos: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    publico_alvo: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    dados: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    informacoes: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    video: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    alerta_formador: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    formador_responsavel: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    aprender_no_curso: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    idioma: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    updated_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    vagas_inscricao: {
      type: DataTypes.INTEGER,
      allowNull: true,
      defaultValue: 50
    }
  }, {
    sequelize,
    tableName: 'cursos',
    schema: 'public',
    timestamps: false
  });
};