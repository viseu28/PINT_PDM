const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('inscricaoCurso', {
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idinscricao: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'inscricao_curso',
    schema: 'public',
    timestamps: false
  });
};
