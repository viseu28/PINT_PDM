const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('administra', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idtopicos: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'administra',
    schema: 'public',
    timestamps: false
  });
};
