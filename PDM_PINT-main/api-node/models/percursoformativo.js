const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('percursoformativo', {
    idpercurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    datainicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horainicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horafim: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'percursoformativo',
    schema: 'public',
    timestamps: false
  });
};
