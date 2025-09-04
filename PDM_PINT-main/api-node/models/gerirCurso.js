const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('gerirCurso', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'gerir_curso',
    schema: 'public',
    timestamps: false
  });
};
