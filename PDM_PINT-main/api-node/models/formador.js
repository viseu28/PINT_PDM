const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('formador', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    especilidades: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    avaliacao: {
      type: DataTypes.INTEGER,
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'formador',
    schema: 'public',
    timestamps: false
  });
};
