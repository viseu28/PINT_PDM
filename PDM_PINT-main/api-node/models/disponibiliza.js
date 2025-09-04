const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('disponibiliza', {
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'disponibiliza',
    schema: 'public',
    timestamps: false
  });
};
