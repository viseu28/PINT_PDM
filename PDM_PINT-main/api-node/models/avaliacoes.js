const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('avaliacoes', {
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    titulo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    descricaoc: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    },
    tipo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    idavaliacao: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    nota: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    feedback: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    data: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'avaliacoes',
    schema: 'public',
    timestamps: false
  });
};
