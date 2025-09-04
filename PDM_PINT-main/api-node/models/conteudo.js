const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('conteudo', {
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
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
    }
  }, {
    sequelize,
    tableName: 'conteudo',
    schema: 'public',
    timestamps: false
  });
};
