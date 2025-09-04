const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('analisa', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    iddenuncia: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'analisa',
    schema: 'public',
    timestamps: false
  });
};
