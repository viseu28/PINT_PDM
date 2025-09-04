const Sequelize = require('sequelize');

module.exports = function (sequelize, DataTypes) {
  return sequelize.define('projetos_submissoes', {
    id_submissao: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    id_projeto: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    id_utilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    ficheiro_url: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    ficheiro_nome_original: {
      type: DataTypes.STRING(255),
      allowNull: true
    },
    data_submissao: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
    }
  }, {
    sequelize,
    tableName: 'projetos_submissoes',
    schema: 'public',
    timestamps: false
  });
};
