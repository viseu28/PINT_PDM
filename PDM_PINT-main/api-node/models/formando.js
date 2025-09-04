const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('formando', {
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurriculopendente: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    cursos: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'formando',
    schema: 'public',
    timestamps: false
  });
};
