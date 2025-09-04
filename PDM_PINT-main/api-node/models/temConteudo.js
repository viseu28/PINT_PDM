const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('temConteudo', {
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'tem_conteudo',
    schema: 'public',
    timestamps: false
  });
};
