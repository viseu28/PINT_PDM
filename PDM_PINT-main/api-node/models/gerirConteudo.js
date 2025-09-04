const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('gerirConteudo', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'gerir_conteudo',
    schema: 'public',
    timestamps: false
  });
};
