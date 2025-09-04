const Sequelize = require('sequelize');

module.exports = function (sequelize, DataTypes) {
  return sequelize.define('projetos', {
    id_projeto: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    id_utilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    id_curso: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    nome_projeto: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    ficheiro_url: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    data_submissao: {
      type: DataTypes.DATE,
      allowNull: true,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    },
    ficheiro_nome_original: {
      type: DataTypes.STRING(255),
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'projetos',
    schema: 'public',
    timestamps: false
  });
};
