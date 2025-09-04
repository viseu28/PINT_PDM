const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('cursospendentes', {
    idcursopendente: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    curso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'cursospendentes',
    schema: 'public',
    timestamps: false
  });
};
